"""Testes do agendador com um Firestore de mentira (sem internet).

Rode na pasta agendador/:  python -m unittest -v
"""

import unittest
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from zoneinfo import ZoneInfo

from agendador import Agendador, decidir, dose_id, horarios_do_dia

SP = ZoneInfo("America/Sao_Paulo")


# ---------------------------------------------------------------------------
# Firestore e Cloud Messaging de mentira


class Doc:
    def __init__(self, store, path):
        self.store, self.path = store, path

    @property
    def id(self):
        return self.path.split("/")[-1]

    def collection(self, name):
        return Col(self.store, f"{self.path}/{name}")

    def get(self):
        data = self.store.get(self.path)
        return SimpleNamespace(exists=data is not None, to_dict=lambda: dict(data) if data else None,
                               id=self.id, reference=self)

    def set(self, data):
        self.store[self.path] = dict(data)

    def update(self, data):
        self.store[self.path].update(data)


class Col:
    def __init__(self, store, path, filters=()):
        self.store, self.path, self.filters = store, path, filters

    def document(self, doc_id):
        return Doc(self.store, f"{self.path}/{doc_id}")

    def where(self, filter):
        return Col(self.store, self.path, self.filters + (filter,))

    def stream(self):
        prefix = self.path + "/"
        for path, data in list(self.store.items()):
            rest = path[len(prefix):] if path.startswith(prefix) else None
            if not rest or "/" in rest:
                continue
            ok = True
            for f in self.filters:
                v = data.get(f.field_path)
                ok &= (v is not None and v >= f.value) if f.op_string == ">=" else v == f.value
            if ok:
                doc = Doc(self.store, path)
                yield SimpleNamespace(id=doc.id, to_dict=lambda d=data: dict(d), reference=doc)


class Db:
    def __init__(self):
        self.store = {}

    def collection(self, name):
        return Col(self.store, name)


class Messaging:
    """Guarda as notificações em vez de enviar."""

    def __init__(self):
        self.enviadas = []

    MulticastMessage = staticmethod(lambda **kw: SimpleNamespace(**kw))
    Notification = staticmethod(lambda **kw: SimpleNamespace(**kw))
    AndroidConfig = staticmethod(lambda **kw: SimpleNamespace(**kw))
    WebpushConfig = staticmethod(lambda **kw: SimpleNamespace(**kw))
    WebpushNotification = staticmethod(lambda **kw: SimpleNamespace(**kw))
    WebpushFCMOptions = staticmethod(lambda **kw: SimpleNamespace(**kw))
    AndroidNotification = staticmethod(lambda **kw: SimpleNamespace(**kw))

    def send_each_for_multicast(self, msg):
        for t in msg.tokens:
            self.enviadas.append((t, msg.notification.title, msg.notification.body))
        ok = SimpleNamespace(success=True, exception=None)
        return SimpleNamespace(success_count=len(msg.tokens), responses=[ok] * len(msg.tokens))


def sp(h, m=0, dia=0):
    """Hoje (23/11/2026) em São Paulo, às h:m, mais `dia` dias."""
    return datetime(2026, 11, 23, h, m, tzinfo=SP) + timedelta(days=dia)


def cenario(usa_app=True):
    db = Db()
    db.store["usuarios/u-maria"] = {"tokensFcm": ["tok-maria"]}
    db.store["usuarios/u-carla"] = {"tokensFcm": ["tok-carla"]}
    db.store["idosos/e1"] = {
        "usuarioId": "u-maria" if usa_app else None,
        "apelido": "Maria",
        "usaApp": usa_app,
        "cuidadoresIds": ["u-carla"],
        "fusoHorario": "America/Sao_Paulo",
    }
    db.store["idosos/e1/medicamentos/m1"] = {
        "nome": "Losartana 50 mg",
        "dose": "1 comprimido",
        "horarios": ["08:00", "20:00"],
        "diasSemana": [1, 2, 3, 4, 5, 6, 7],
        "inicio": sp(0, 0, -10),
        "fim": None,
        "prazoAlertaMin": 30,
        "encerradoEm": None,
        "criadoEm": sp(0, 0, -10),
    }
    return db


def rodar(db, quando):
    msg = Messaging()
    contagem = Agendador(db, msg, agora=quando.astimezone(timezone.utc)).rodar()
    return contagem, msg.enviadas


DOSE_8H = f"idosos/e1/doses/{dose_id('m1', sp(8))}"


# ---------------------------------------------------------------------------


class Regras(unittest.TestCase):
    def test_horarios_respeitam_dias_da_semana(self):
        med = {"horarios": ["08:00"], "diasSemana": [1], "encerradoEm": None}  # só segunda
        self.assertEqual(horarios_do_dia(med, sp(0).date(), SP), [sp(8)])  # 23/11/2026 é segunda
        self.assertEqual(horarios_do_dia(med, sp(0, 0, 1).date(), SP), [])

    def test_dose_futura_nao_faz_nada(self):
        dose = {"agendadaPara": sp(9), "estado": "pendente"}
        acao = decidir(dose, sp(8), True, 30, sp(8).date(), SP)
        self.assertFalse(acao.lembrar_idoso or acao.mudancas)


class Agendamento(unittest.TestCase):
    def test_cria_doses_de_hoje_e_amanha(self):
        db = cenario()
        contagem, _ = rodar(db, sp(7, 0))
        self.assertEqual(contagem["doses_criadas"], 4)  # 08h e 20h, hoje e amanhã
        self.assertIn(DOSE_8H, db.store)
        contagem, _ = rodar(db, sp(7, 5))
        self.assertEqual(contagem["doses_criadas"], 0)  # não duplica

    def test_lembrete_na_hora_e_uma_vez_so(self):
        db = cenario()
        rodar(db, sp(7, 0))
        _, enviadas = rodar(db, sp(8, 2))
        self.assertEqual([(t, titulo) for t, titulo, _ in enviadas], [("tok-maria", "Hora do remédio: Losartana 50 mg")])
        _, enviadas = rodar(db, sp(8, 7))
        self.assertEqual(enviadas, [])

    def test_lembra_de_novo_depois_de_adiar(self):
        db = cenario()
        rodar(db, sp(7, 0))
        rodar(db, sp(8, 2))
        db.store[DOSE_8H].update({"adiamentos": 1, "estado": "adiada"})  # tocou em "Me lembra"
        _, enviadas = rodar(db, sp(8, 10))
        self.assertEqual(enviadas, [])  # ainda não passaram 15 min
        _, enviadas = rodar(db, sp(8, 16))
        self.assertEqual([t for t, *_ in enviadas], ["tok-maria"])

    def test_sem_resposta_avisa_o_cuidador(self):
        db = cenario()
        rodar(db, sp(7, 0))
        rodar(db, sp(8, 2))
        contagem, enviadas = rodar(db, sp(8, 31))
        self.assertEqual(contagem["alertas_criados"], 1)
        self.assertEqual(db.store[DOSE_8H]["estado"], "atrasada")
        self.assertEqual(enviadas[0][0], "tok-carla")
        self.assertIn("não respondeu", enviadas[0][2])
        _, enviadas = rodar(db, sp(8, 36))
        self.assertEqual(enviadas, [])  # um alerta só

    def test_adiou_duas_vezes_avisa_o_cuidador(self):
        db = cenario()
        rodar(db, sp(7, 0))
        rodar(db, sp(8, 2))
        # O app cria o alerta no segundo "Me lembra em 15 min".
        db.store[DOSE_8H].update({"adiamentos": 2, "estado": "atrasada", "alertado": True})
        db.store[f"idosos/e1/alertas/{dose_id('m1', sp(8))}"] = {
            "doseId": dose_id("m1", sp(8)), "nomeRemedio": "Losartana 50 mg", "horaDose": sp(8),
            "motivo": "adiouDuasVezes", "resolvidoEm": None, "notificado": False,
        }
        _, enviadas = rodar(db, sp(8, 20))
        self.assertEqual(enviadas[0][0], "tok-carla")
        self.assertIn("adiou 2 vezes", enviadas[0][2])

    def test_confirmada_nao_avisa_ninguem(self):
        db = cenario()
        rodar(db, sp(7, 0))
        db.store[DOSE_8H]["estado"] = "tomada"
        _, enviadas = rodar(db, sp(8, 40))
        self.assertEqual(enviadas, [])

    def test_idoso_sem_app_avisa_cuidador_a_cada_15_min(self):
        db = cenario(usa_app=False)
        rodar(db, sp(7, 0))
        _, enviadas = rodar(db, sp(8, 1))
        self.assertEqual([t for t, *_ in enviadas], ["tok-carla"])
        _, enviadas = rodar(db, sp(8, 10))
        self.assertEqual(enviadas, [])
        _, enviadas = rodar(db, sp(8, 16))
        self.assertEqual([t for t, *_ in enviadas], ["tok-carla"])

    def test_dose_de_ontem_vira_perdida(self):
        db = cenario()
        rodar(db, sp(7, 0))
        contagem, _ = rodar(db, sp(0, 10, 1))  # 00:10 do dia seguinte
        self.assertGreaterEqual(contagem["doses_perdidas"], 1)
        self.assertEqual(db.store[DOSE_8H]["estado"], "perdida")


if __name__ == "__main__":
    unittest.main()
