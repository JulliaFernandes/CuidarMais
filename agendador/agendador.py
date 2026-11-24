"""Agendador do CuidarMais.

Roda a cada 5 minutos no GitHub Actions (.github/workflows/agendador.yml) e
faz o que o app não consegue fazer sozinho com ele fechado:

1. cria as doses de hoje e de amanhã de cada remédio;
2. manda o lembrete no horário para o celular do idoso (ou do cuidador, se o
   idoso não usa o app) e de novo depois de cada "Me lembra em 15 min";
3. cria o alerta de "sem resposta" quando passa o prazo do remédio;
4. avisa o cuidador de cada alerta novo (inclusive o de "adiou 2 vezes",
   que o próprio app cria);
5. idoso sem app: avisa o cuidador a cada 15 minutos até alguém confirmar;
6. marca como perdida a dose que ficou sem confirmação no dia anterior.

As regras são as mesmas do modo de demonstração do app
(MVP/lib/data/store/app_store.dart).

Atenção: os logs do GitHub Actions deste repositório são públicos. Por isso
o script só imprime contagens, nunca nomes, remédios ou emails.

Precisa da variável de ambiente FIREBASE_SERVICE_ACCOUNT com o JSON da chave
de serviço do projeto (segredo do GitHub, veja agendador/LEIA-ME.md).
"""

from __future__ import annotations

import json
import os
import sys
from collections import Counter
from dataclasses import dataclass, field
from datetime import date, datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

APP_URL = "https://cuidarmais-app.web.app"
FUSO_PADRAO = "America/Sao_Paulo"
ADIAMENTO = timedelta(minutes=15)
AVISO_SEM_APP = timedelta(minutes=15)
ABERTAS = {"pendente", "adiada", "atrasada"}

try:  # filtro de consulta do Firestore; sem a biblioteca (nos testes), um igual
    from google.cloud.firestore_v1.base_query import FieldFilter
except ImportError:  # pragma: no cover

    @dataclass
    class FieldFilter:  # type: ignore[no-redef]
        field_path: str
        op_string: str
        value: object


# ---------------------------------------------------------------------------
# Regras (sem Firebase, para dar para testar sozinhas)


def dose_id(medicamento_id: str, quando_local: datetime) -> str:
    """Mesmo id que o app usa (RemoteSync.doseId), para não duplicar a dose."""
    return f"{medicamento_id}_{quando_local:%Y%m%d%H%M}"


def remedio_ativo(med: dict, dia: date) -> bool:
    if med.get("encerradoEm") is not None:
        return False
    dias = med.get("diasSemana") or [1, 2, 3, 4, 5, 6, 7]
    if dia.isoweekday() not in dias:
        return False
    inicio = _data_local(med.get("inicio"))
    fim = _data_local(med.get("fim"))
    if inicio and dia < inicio:
        return False
    if fim and dia > fim:
        return False
    return True


def horarios_do_dia(med: dict, dia: date, fuso: ZoneInfo) -> list[datetime]:
    """Horários do remédio nesse dia, já com fuso."""
    if not remedio_ativo(med, dia):
        return []
    saida = []
    for h in med.get("horarios") or []:
        hora, minuto = (int(x) for x in h.split(":"))
        saida.append(datetime.combine(dia, time(hora, minuto), tzinfo=fuso))
    return saida


@dataclass
class Acao:
    """O que fazer com uma dose agora."""

    mudancas: dict = field(default_factory=dict)
    lembrar_idoso: bool = False
    lembrar_cuidador: bool = False
    criar_alerta_sem_resposta: bool = False


def decidir(dose: dict, agora: datetime, usa_app: bool, prazo_min: int, hoje_local: date, fuso: ZoneInfo) -> Acao:
    """Aplica as regras de lembrete e escalada a uma dose aberta."""
    acao = Acao()
    quando: datetime = dose["agendadaPara"]
    if dose.get("estado") not in ABERTAS:
        return acao

    # Ficou sem confirmação no dia anterior: perdida.
    if quando.astimezone(fuso).date() < hoje_local:
        acao.mudancas["estado"] = "perdida"
        return acao

    if quando > agora:
        return acao

    lembretes = int(dose.get("lembretes") or 0)
    adiamentos = int(dose.get("adiamentos") or 0)

    if not usa_app:
        # Um aviso novo ao cuidador a cada 15 minutos até confirmar.
        devidos = int((agora - quando) / AVISO_SEM_APP) + 1
        if devidos > lembretes:
            acao.lembrar_cuidador = True
            acao.mudancas["lembretes"] = devidos
        return acao

    # Primeiro lembrete, na hora.
    if lembretes == 0:
        acao.lembrar_idoso = True
        lembretes = 1
        acao.mudancas["lembretes"] = 1
    # Depois de cada "Me lembra em 15 min" (no máximo 2), lembra de novo.
    elif 0 < adiamentos < 2 and lembretes <= adiamentos and agora >= quando + ADIAMENTO * adiamentos:
        acao.lembrar_idoso = True
        acao.mudancas["lembretes"] = adiamentos + 1

    # Sem resposta: o prazo conta a partir do último lembrete.
    ultimo = quando + ADIAMENTO * adiamentos
    if not dose.get("alertado") and agora - ultimo >= timedelta(minutes=prazo_min):
        acao.criar_alerta_sem_resposta = True
        acao.mudancas["estado"] = "atrasada"
        acao.mudancas["alertado"] = True
    return acao


def _data_local(valor) -> date | None:
    if valor is None:
        return None
    if isinstance(valor, datetime):
        return valor.astimezone(ZoneInfo(FUSO_PADRAO)).date()
    return None


def hhmm(quando: datetime, fuso: ZoneInfo) -> str:
    return quando.astimezone(fuso).strftime("%H:%M")


# ---------------------------------------------------------------------------
# Firebase


class Agendador:
    def __init__(self, db, messaging, agora: datetime | None = None):
        self.db = db
        self.messaging = messaging
        self.agora = agora or datetime.now(timezone.utc)
        self.contagem = Counter()
        self._tokens: dict[str, list[str]] = {}

    def rodar(self) -> Counter:
        for snap in self.db.collection("idosos").stream():
            try:
                self.processar_idoso(snap)
            except Exception as erro:  # um idoso com problema não para os outros
                self.contagem["erros"] += 1
                print(f"Erro ao processar um idoso: {type(erro).__name__}", file=sys.stderr)
        return self.contagem

    def processar_idoso(self, snap) -> None:
        idoso = snap.to_dict() or {}
        ref = snap.reference
        fuso = ZoneInfo(idoso.get("fusoHorario") or FUSO_PADRAO)
        hoje = self.agora.astimezone(fuso).date()
        usa_app = bool(idoso.get("usaApp", True))
        apelido = idoso.get("apelido") or (idoso.get("nome") or "").split(" ")[0] or "o idoso"
        dono = idoso.get("usuarioId")
        cuidadores = list(idoso.get("cuidadoresIds") or [])
        self.contagem["idosos"] += 1

        meds = {m.id: m.to_dict() or {} for m in ref.collection("medicamentos").stream()}
        inicio = datetime.combine(hoje - timedelta(days=1), time(0, 0), tzinfo=fuso)
        doses = {d.id: d.to_dict() or {} for d in ref.collection("doses").where(filter=FieldFilter("agendadaPara", ">=", inicio)).stream()}

        # 1. Doses de hoje e de amanhã.
        for med_id, med in meds.items():
            criado = med.get("criadoEm")
            for dia in (hoje, hoje + timedelta(days=1)):
                for quando in horarios_do_dia(med, dia, fuso):
                    if criado and quando <= criado:
                        continue  # não cria dose de antes do remédio existir
                    if quando <= self.agora - timedelta(hours=1):
                        continue  # horário que já passou faz tempo
                    did = dose_id(med_id, quando)
                    if did in doses:
                        continue
                    dados = {
                        "medicamentoId": med_id,
                        "idosoId": snap.id,
                        "nomeRemedio": med.get("nome", ""),
                        "dose": med.get("dose", ""),
                        "agendadaPara": quando,
                        "estado": "pendente",
                        "adiamentos": 0,
                        "lembretes": 0,
                        "alertado": False,
                        "criadoEm": self.agora,
                    }
                    ref.collection("doses").document(did).set(dados)
                    doses[did] = dados
                    self.contagem["doses_criadas"] += 1

        # 2, 3, 5 e 6. Lembretes, sem resposta e perdidas.
        for did, dose in doses.items():
            med = meds.get(dose.get("medicamentoId"), {})
            prazo = int(med.get("prazoAlertaMin") or 30)
            acao = decidir(dose, self.agora, usa_app, prazo, hoje, fuso)
            nome = dose.get("nomeRemedio", "remédio")
            hora = hhmm(dose["agendadaPara"], fuso)
            if acao.lembrar_idoso and dono:
                self.enviar([dono], f"Hora do remédio: {nome}", f"{dose.get('dose', '')} · {hora}. Toque para confirmar.")
                self.contagem["lembretes_idoso"] += 1
            if acao.lembrar_cuidador:
                self.enviar(cuidadores, f"Hora do remédio de {apelido}", f"{nome} das {hora}. Confirme quando {apelido} tomar.")
                self.contagem["lembretes_cuidador"] += 1
            if acao.criar_alerta_sem_resposta:
                alerta_ref = ref.collection("alertas").document(did)
                if not alerta_ref.get().exists:
                    alerta_ref.set({
                        "doseId": did,
                        "nomeRemedio": nome,
                        "horaDose": dose["agendadaPara"],
                        "motivo": "semResposta",
                        "criadoEm": self.agora,
                        "resolvidoEm": None,
                        "notificado": False,
                    })
                    self.contagem["alertas_criados"] += 1
            if acao.mudancas:
                ref.collection("doses").document(did).update(acao.mudancas)
                if acao.mudancas.get("estado") == "perdida":
                    self.contagem["doses_perdidas"] += 1

        # 4. Avisa o cuidador de cada alerta novo.
        for alerta in ref.collection("alertas").where(filter=FieldFilter("notificado", "==", False)).stream():
            a = alerta.to_dict() or {}
            if a.get("resolvidoEm") is None:
                hora = hhmm(a["horaDose"], fuso) if a.get("horaDose") else ""
                nome = a.get("nomeRemedio", "remédio")
                if a.get("motivo") == "adiouDuasVezes":
                    corpo = f"{apelido} adiou 2 vezes o lembrete da {nome} das {hora}."
                else:
                    corpo = f"{apelido} não respondeu ao lembrete da {nome} das {hora}."
                self.enviar(cuidadores, f"Alerta: {apelido}", corpo + " Que tal ligar para confirmar?")
                self.contagem["alertas_enviados"] += 1
            alerta.reference.update({"notificado": True})

    def tokens_de(self, uid: str) -> list[str]:
        if uid not in self._tokens:
            snap = self.db.collection("usuarios").document(uid).get()
            self._tokens[uid] = list((snap.to_dict() or {}).get("tokensFcm") or []) if snap.exists else []
        return self._tokens[uid]

    def enviar(self, uids: list[str], titulo: str, corpo: str) -> None:
        donos = {t: uid for uid in uids for t in self.tokens_de(uid)}
        if not donos:
            self.contagem["sem_aparelho"] += 1
            return
        m = self.messaging
        tokens = list(donos)
        mensagem = m.MulticastMessage(
            tokens=tokens,
            notification=m.Notification(title=titulo, body=corpo),
            # Android: canal "lembretes" (prioridade alta, criado em MainActivity.kt) para aparecer
            # por cima da tela, com som de alarme e vibração.
            android=m.AndroidConfig(
                priority="high",
                ttl=3600,
                notification=m.AndroidNotification(
                    channel_id="lembretes",
                    priority="max",
                    visibility="public",
                    default_vibrate_timings=True,
                ),
            ),
            # Navegador: urgente (entrega na hora) e fica na tela até a pessoa tocar.
            webpush=m.WebpushConfig(
                headers={"Urgency": "high", "TTL": "3600"},
                notification=m.WebpushNotification(
                    icon=f"{APP_URL}/icons/Icon-192.png",
                    badge=f"{APP_URL}/icons/Icon-192.png",
                    require_interaction=True,
                    renotify=True,
                    tag=titulo,
                    vibrate=[800, 400, 800, 400, 800],
                ),
                fcm_options=m.WebpushFCMOptions(link=APP_URL),
            ),
        )
        resposta = m.send_each_for_multicast(mensagem)
        self.contagem["notificacoes_ok"] += resposta.success_count
        for token, r in zip(tokens, resposta.responses):
            if r.success:
                continue
            self.contagem["notificacoes_erro"] += 1
            # Aparelho que desinstalou o app ou saiu da conta: tira da lista.
            if type(r.exception).__name__ in {"UnregisteredError", "SenderIdMismatchError"}:
                from google.cloud.firestore import ArrayRemove  # import tardio: só com Firebase

                uid = donos[token]
                self.db.collection("usuarios").document(uid).update({"tokensFcm": ArrayRemove([token])})
                self._tokens[uid] = [t for t in self._tokens.get(uid, []) if t != token]


def main() -> int:
    chave = os.environ.get("FIREBASE_SERVICE_ACCOUNT", "").strip()
    if not chave:
        print("FIREBASE_SERVICE_ACCOUNT não configurado. Nada a fazer (veja agendador/LEIA-ME.md).")
        return 0

    import firebase_admin
    from firebase_admin import credentials, firestore, messaging

    firebase_admin.initialize_app(credentials.Certificate(json.loads(chave)))
    contagem = Agendador(firestore.client(), messaging).rodar()
    resumo = ", ".join(f"{k}={v}" for k, v in sorted(contagem.items())) or "nada a fazer"
    print(f"Agendador {datetime.now(timezone.utc):%Y-%m-%d %H:%M} UTC: {resumo}")
    return 1 if contagem.get("erros") else 0


if __name__ == "__main__":
    sys.exit(main())
