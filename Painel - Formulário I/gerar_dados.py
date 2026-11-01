#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Lê dados/Cuidar_respostas.xlsx e dados/entrevistas.txt e gera js/dados.js,
o arquivo que o painel (index.html) carrega com os dados reais embutidos.

Como usar:
    python3 gerar_dados.py

Precisa de: pip install openpyxl
Rode de novo sempre que atualizar a planilha ou o entrevistas.txt.
"""
import json
import re
import sys
import unicodedata
from datetime import datetime
from pathlib import Path

BASE = Path(__file__).resolve().parent
XLSX = BASE / "dados" / "Cuidar_respostas.xlsx"
ENTREVISTAS = BASE / "dados" / "entrevistas.txt"
SAIDA = BASE / "js" / "dados.js"

try:
    import openpyxl
except ImportError:
    sys.exit("Falta a biblioteca openpyxl. Instale com: pip install openpyxl")


def norm(s):
    s = str(s or "").lower()
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return s


# Cada pergunta do formulário é reconhecida por um trecho do título (já sem
# acento e minúsculo), não pelo texto exato — assim a ordem das colunas na
# planilha pode mudar sem quebrar o painel.
COLUNAS = [
    ("ts", ["carimbo", "timestamp"]),
    ("dif", ["principais dificuldades"]),
    ("maior", ["maior dificuldade"]),
    ("apos", ["como e o acompanhamento", "acompanhamento do idoso depois"]),
    ("sabe", ["como voce sabe"]),
    ("pref", ["preferiria receber"]),
    ("desafio", ["desafio no cuidado"]),
    ("participa", ["participar de uma conversa", "conversa rapida"]),
    ("esp", ["profissao e especialidade", "qual sua profissao"]),
    ("cidade", ["em qual cidade"]),
]


def short_label(s):
    """Para opções de múltipla escolha com explicação ('Título: explicação...'),
    usa só o título no gráfico; o texto completo fica disponível à parte."""
    s = str(s or "").strip()
    i = s.find(":")
    if 3 < i < 70:
        return s[:i].strip()
    if len(s) > 90:
        corte = s[:87]
        if " " in corte:
            corte = corte[: corte.rfind(" ")]
        return corte.strip() + "…"
    return s


def split_multi(s):
    # As respostas de marcar-várias vêm numa célula só, separadas por vírgula.
    parts = re.split(r",\s*(?=[A-ZÀ-Ú])", str(s or "").strip())
    return [p.strip() for p in parts if p.strip()]


def parse_date(v):
    if isinstance(v, datetime):
        return v
    s = str(v or "")
    m = re.search(r"(\d{1,2})/(\d{1,2})/(\d{4})(?:\s+(\d{1,2}):(\d{2}))?", s)
    if m:
        d, mo, y, h, mi = m.groups()
        return datetime(int(y), int(mo), int(d), int(h or 0), int(mi or 0))
    return None


def ler_planilha():
    if not XLSX.exists():
        sys.exit(f"Não encontrei {XLSX}. Coloque a planilha nesse caminho.")
    wb = openpyxl.load_workbook(XLSX, data_only=True)
    ws = wb.worksheets[0]
    linhas = list(ws.iter_rows(values_only=True))
    if len(linhas) < 2:
        sys.exit("A planilha não tem respostas (só o cabeçalho, ou está vazia).")
    cabecalho = [norm(h) for h in linhas[0]]

    idx, encontradas = {}, {}
    usadas = set()
    for chave, pistas in COLUNAS:
        for i, h in enumerate(cabecalho):
            if i in usadas:
                continue
            if any(p in h for p in pistas):
                idx[chave] = i
                encontradas[chave] = linhas[0][i]
                usadas.add(i)
                break

    essenciais = ["dif", "maior", "apos", "sabe", "pref"]
    achadas = sum(1 for k in essenciais if k in idx)
    if achadas < 2:
        sys.exit(
            "Não reconheci as colunas do formulário nessa planilha. "
            "Confira se a primeira linha tem os títulos das perguntas."
        )

    def val(linha, chave):
        if chave not in idx:
            return ""
        v = linha[idx[chave]]
        return "" if v is None else str(v).strip()

    respostas = []
    for linha in linhas[1:]:
        if not any(str(c).strip() for c in linha if c is not None):
            continue
        full = {}

        def multi(chave):
            out = []
            for item in split_multi(val(linha, chave)):
                rotulo = short_label(item)
                if rotulo != item:
                    full[rotulo] = item
                out.append(rotulo)
            return out

        def um(chave):
            item = val(linha, chave)
            rotulo = short_label(item)
            if rotulo != item and item:
                full[rotulo] = item
            return rotulo

        ts_bruto = linha[idx["ts"]] if "ts" in idx else None
        data = parse_date(ts_bruto) or datetime.now()
        esp = um("esp")
        respostas.append({
            "data": data.isoformat(),
            "esp": esp,
            "cidade": val(linha, "cidade"),
            "dif": multi("dif"),
            "maior": multi("maior"),
            "apos": um("apos"),
            "sabe": um("sabe"),
            "pref": multi("pref"),
            "desafio": val(linha, "desafio"),
            "participa": norm(val(linha, "participa")).startswith("sim"),
            "fullTxt": full,
        })

    respostas.sort(key=lambda r: r["data"])

    faltando = [c for c, _ in COLUNAS if c not in idx and c not in ("ts", "cidade")]
    if faltando:
        print(f"Aviso: não encontrei estas colunas na planilha: {', '.join(faltando)}")
    print(f"Planilha lida: {len(respostas)} respostas.")
    return respostas


def ler_entrevistas():
    if not ENTREVISTAS.exists():
        print("Aviso: dados/entrevistas.txt não encontrado — seção de entrevistas ficará vazia.")
        return []
    texto = ENTREVISTAS.read_text(encoding="utf-8")
    blocos = [b for b in texto.split("\n---") if b.strip()]
    entrevistas = []
    for bloco in blocos:
        linhas = [l for l in bloco.splitlines() if not l.strip().startswith("#")]
        nome, esp = "", ""
        fund, func = [], []
        modo = None
        for l in linhas:
            l = l.rstrip()
            if not l.strip():
                continue
            low = l.strip().lower()
            if low.startswith("nome:"):
                nome = l.split(":", 1)[1].strip()
            elif low.startswith("especialidade:"):
                esp = l.split(":", 1)[1].strip()
            elif low.startswith("fundamentação:") or low.startswith("fundamentacao:"):
                modo = "fund"
            elif low.startswith("funcionalidades:"):
                modo = "func"
            elif l.strip().startswith("-"):
                item = l.strip()[1:].strip()
                if item and modo == "fund":
                    fund.append(item)
                elif item and modo == "func":
                    func.append(item)
        if nome or esp or fund or func:
            entrevistas.append({"nome": nome, "esp": esp, "fund": fund, "func": func})
    print(f"Entrevistas lidas: {len(entrevistas)} (com {sum(len(e['fund']) for e in entrevistas)} "
          f"observações de fundamentação e {sum(len(e['func']) for e in entrevistas)} de funcionalidades).")
    return entrevistas


def main():
    respostas = ler_planilha()
    entrevistas = ler_entrevistas()
    dados = {
        "geradoEm": datetime.now().isoformat(),
        "respostas": respostas,
        "entrevistas": entrevistas,
    }
    SAIDA.parent.mkdir(parents=True, exist_ok=True)
    SAIDA.write_text(
        "// Gerado automaticamente por gerar_dados.py — não edite à mão.\n"
        "// Para atualizar: troque os arquivos em dados/ e rode gerar_dados.py de novo.\n"
        "window.CUIDAR_DADOS = " + json.dumps(dados, ensure_ascii=False, indent=2) + ";\n",
        encoding="utf-8",
    )
    print(f"Pronto: {SAIDA.relative_to(BASE)} atualizado.")


if __name__ == "__main__":
    main()
