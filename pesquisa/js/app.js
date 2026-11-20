// Painel Cuidar+ — lê window.CUIDAR_DADOS (gerado por gerar_dados.py) e desenha a tela.
// Não tem dados de exemplo: se dados.js não tiver respostas, os cartões mostram "sem respostas".
(function () {
  "use strict";
  var $ = function (s) { return document.querySelector(s); };
  var esc = function (s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  };
  var pct = function (n, t) { return t ? Math.round((n / t) * 100) : 0; };
  var fmtDate = function (d) { return d.toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit" }); };
  var fmtFull = function (d) { return d.toLocaleDateString("pt-BR"); };
  var plural = function (n, a, b) { return n + " " + (n === 1 ? a : b); };
  var DAY = 86400000;

  var FONTE = window.CUIDAR_DADOS || { respostas: [], entrevistas: [] };
  var ALL = (FONTE.respostas || []).map(function (r) {
    var o = Object.assign({}, r);
    o.data = new Date(r.data);
    return o;
  });
  var ENTREVISTAS = FONTE.entrevistas || [];

  var espLabel = function (r) { return r.esp ? r.esp : "Especialidade não informada"; };
  function count(rows, key, multi) {
    var m = {}, full = {};
    rows.forEach(function (r) {
      var v = multi ? r[key] : [r[key]];
      v.forEach(function (x) { if (x) { m[x] = (m[x] || 0) + 1; if (r.fullTxt && r.fullTxt[x] && !full[x]) full[x] = r.fullTxt[x]; } });
    });
    return Object.keys(m).map(function (k) { return { label: k, n: m[k], full: full[k] || "" }; })
      .sort(function (a, b) { return b.n - a.n || a.label.localeCompare(b.label); });
  }

  /* ---------- Componentes ---------- */
  function head(title, sub) { return '<div class="card-head"><h3>' + esc(title) + "</h3>" + (sub ? "<p>" + esc(sub) + "</p>" : "") + "</div>"; }
  function tipOf(d, total) {
    var t = d.label + ": " + plural(d.n, "resposta", "respostas") + " (" + pct(d.n, total) + "%)";
    if (d.full) t += ". " + (d.full.length > 170 ? d.full.slice(0, 167) + "…" : d.full);
    return t;
  }
  function bars(list, total, max) {
    if (!list.length) return '<div class="empty">Sem respostas ainda.</div>';
    var top = list.slice(0, max || 6), peak = top[0].n;
    return '<div class="bars">' + top.map(function (d) {
      return '<div class="bar-row" data-tip="' + esc(tipOf(d, total)) + '"><div class="bar-label">' + esc(d.label) + '</div>' +
        '<div class="bar-line"><div class="bar-track"><div class="bar-fill" style="width:' + (d.n / peak * 100) + '%"></div></div>' +
        '<div class="bar-val"><b>' + pct(d.n, total) + "%</b> · " + d.n + "</div></div></div>";
    }).join("") + "</div>";
  }
  function donut(list, total) {
    if (!list.length) return '<div class="empty">Sem respostas ainda.</div>';
    var COL = ["var(--accent)", "var(--s2)", "var(--s3)", "var(--s4)", "var(--s5)"];
    var parts = list.slice(0, 5), rest = list.slice(5);
    if (rest.length) parts.push({ label: "Outros", n: rest.reduce(function (a, d) { return a + d.n; }, 0), other: true, full: "" });
    var R = 68, C = 2 * Math.PI * R, off = 0, segs = "", leg = "";
    parts.forEach(function (d, i) {
      var len = d.n / total * C, gap = parts.length > 1 ? 3 : 0, vis = Math.max(len - gap, 0.8), col = d.other ? "var(--ink-3)" : COL[i];
      var tip = tipOf(d, total);
      segs += '<circle cx="105" cy="105" r="' + R + '" fill="none" stroke="' + col + '" stroke-width="30" stroke-dasharray="' + vis + " " + (C - vis) +
        '" stroke-dashoffset="' + (-off) + '" transform="rotate(-90 105 105)" data-tip="' + esc(tip) + '"/>';
      leg += '<div class="legend-row" data-tip="' + esc(tip) + '"><span class="sw" style="background:' + col + '"></span><span class="nm">' + esc(d.label) +
        '</span><span class="nv"><b>' + pct(d.n, total) + "%</b> · " + d.n + "</span></div>";
      off += len;
    });
    return '<div class="donut-wrap"><svg class="donut" viewBox="0 0 210 210" role="img" aria-label="Distribuição das respostas">' + segs +
      '<text class="c-big" x="105" y="109" text-anchor="middle">' + total + '</text><text class="c-small" x="105" y="130" text-anchor="middle">respostas</text></svg>' +
      '<div class="legend">' + leg + "</div></div>";
  }
  var ICONS = {
    chat: '<path d="M4 5h16v11H9.5L4 20.5z"/>',
    mail: '<rect x="3" y="5.5" width="18" height="13" rx="2"/><path d="M3.5 7l8.5 6 8.5-6"/>',
    screen: '<rect x="3" y="4.5" width="18" height="12" rx="2"/><path d="M8 20.5h8M12 16.5v4"/>',
    file: '<path d="M7 3.5h7l4 4V20.5H7z"/><path d="M14 3.5v4h4M10 12.5h5M10 16h5"/>',
    bell: '<path d="M6 17v-6a6 6 0 0 1 12 0v6l2 2H4z"/><path d="M10 21.5h4"/>'
  };
  function iconFor(label) {
    var n = String(label || "").toLowerCase();
    if (/whats|mensag|sms|chat|alerta/.test(n)) return ICONS.chat;
    if (/mail/.test(n)) return ICONS.mail;
    if (/painel|web|site|dashboard|aplicativo|app/.test(n)) return ICONS.screen;
    if (/prontuario|prontuário|sistema|integra/.test(n)) return ICONS.file;
    return ICONS.bell;
  }
  function columns(list, total) {
    if (!list.length) return '<div class="empty">Sem respostas ainda.</div>';
    var top = list.slice(0, 4), peak = top[0].n;
    return '<div class="cols" style="--n:' + top.length + '">' + top.map(function (d) {
      return '<div class="col" data-tip="' + esc(tipOf(d, total)) + '"><div class="col-plot"><div class="col-val">' + pct(d.n, total) + '%<small>' + d.n + '</small></div>' +
        '<div class="col-bar" style="height:' + Math.max(6, Math.round(d.n / peak * 150)) + 'px"></div></div>' +
        '<div class="col-ico"><svg viewBox="0 0 24 24" aria-hidden="true">' + iconFor(d.label) + '</svg></div><div class="col-lab">' + esc(d.label) + "</div></div>";
    }).join("") + "</div>";
  }
  var UP = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 19V5M6 11l6-6 6 6"/></svg>';
  var DOWN = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5v14M6 13l6 6 6-6"/></svg>';
  var KICON = {
    users: '<circle cx="9" cy="8" r="3.6"/><path d="M2.5 20.5c0-3.7 3-6 6.5-6s6.5 2.3 6.5 6"/><path d="M16 4.6a3.6 3.6 0 0 1 0 6.8M18.2 14.6c2 .8 3.3 2.6 3.3 5.9"/>',
    phone: '<path d="M5 4h4l2 5-2.6 1.6a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/>',
    chat: '<path d="M4 5h16v11H9.5L4 20.5z"/><path d="M8 9.5h8M8 12.5h5"/>'
  };
  function kpi(icon, label, num, note, cls) {
    return '<div class="card kpi"><div class="kpi-ico"><svg viewBox="0 0 24 24" aria-hidden="true">' + KICON[icon] + '</svg></div><div class="kpi-body"><div class="kpi-label">' +
      esc(label) + '</div><div class="kpi-num">' + esc(num) + '</div><div class="kpi-note ' + (cls || "") + '">' + note + "</div></div></div>";
  }

  /* ---------- Linha do tempo (acumulado, curva suave) ---------- */
  function smooth(p) {
    var n = p.length, d = "M" + p[0].x.toFixed(1) + "," + p[0].y.toFixed(1);
    if (n < 3) { for (var k = 1; k < n; k++) d += " L" + p[k].x.toFixed(1) + "," + p[k].y.toFixed(1); return d; }
    var dx = [], m = [], t = [], i;
    for (i = 0; i < n - 1; i++) { dx[i] = p[i + 1].x - p[i].x; m[i] = (p[i + 1].y - p[i].y) / dx[i]; }
    t[0] = m[0]; t[n - 1] = m[n - 2];
    for (i = 1; i < n - 1; i++) t[i] = m[i - 1] * m[i] <= 0 ? 0 : (m[i - 1] + m[i]) / 2;
    for (i = 0; i < n - 1; i++) {
      if (m[i] === 0) { t[i] = 0; t[i + 1] = 0; continue; }
      var a = t[i] / m[i], b = t[i + 1] / m[i], s = a * a + b * b;
      if (s > 9) { var q = 3 / Math.sqrt(s); t[i] = q * a * m[i]; t[i + 1] = q * b * m[i]; }
    }
    for (i = 0; i < n - 1; i++) {
      d += " C" + (p[i].x + dx[i] / 3).toFixed(1) + "," + (p[i].y + t[i] * dx[i] / 3).toFixed(1) + " " +
        (p[i + 1].x - dx[i] / 3).toFixed(1) + "," + (p[i + 1].y - t[i + 1] * dx[i] / 3).toFixed(1) + " " + p[i + 1].x.toFixed(1) + "," + p[i + 1].y.toFixed(1);
    }
    return d;
  }
  function timeline(rows) {
    var el = $("#c-time"), h = '<div class="obs-head">' + head("Respostas acumuladas por dia", "Ritmo da coleta") + '<span style="flex:1"></span><span class="legend-inline"><i></i>Respostas acumuladas</span></div>';
    if (rows.length < 2) {
      el.innerHTML = h + '<div class="empty">' + (rows.length ? "Só há 1 resposta até agora — o gráfico aparece com mais dados." : "Sem respostas ainda.") + "</div>";
      return;
    }
    var day = function (d) { return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime(); };
    var t0 = day(rows[0].data), t1 = day(rows[rows.length - 1].data);
    var days = Math.max(1, Math.round((t1 - t0) / DAY)), series = [], run = 0;
    for (var i = 0; i <= days; i++) {
      var t = t0 + i * DAY;
      run += rows.filter(function (r) { return day(r.data) === t; }).length;
      series.push({ t: t, v: run });
    }
    var W = 960, H = 250, L = 40, R = 18, T = 16, B = 30, max = series[series.length - 1].v || 1;
    var step = max <= 5 ? 1 : Math.ceil(max / 4), top = Math.ceil(max / step) * step;
    var x = function (i) { return L + (i / days) * (W - L - R); };
    var y = function (v) { return T + (1 - v / top) * (H - T - B); };
    var P = series.map(function (p, i) { return { x: x(i), y: y(p.v) }; });
    var line = smooth(P);
    var s = '<svg class="chart-svg" viewBox="0 0 ' + W + " " + H + '" role="img" aria-label="Respostas acumuladas por dia">' +
      '<defs><linearGradient id="gfill" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a78d6" stop-opacity=".30"/><stop offset="1" stop-color="#2a78d6" stop-opacity=".02"/></linearGradient></defs>';
    for (var v = 0; v <= top; v += step) {
      s += '<line class="grid-line" x1="' + L + '" x2="' + (W - R) + '" y1="' + y(v) + '" y2="' + y(v) + '"/><text x="' + (L - 10) + '" y="' + (y(v) + 4) + '" text-anchor="end">' + v + "</text>";
    }
    var ticks = days < 6 ? [0, days] : [0, Math.round(days / 3), Math.round(days * 2 / 3), days];
    ticks.forEach(function (i, k) {
      s += '<text x="' + x(i) + '" y="' + (H - 8) + '" text-anchor="' + (k === 0 ? "start" : k === ticks.length - 1 ? "end" : "middle") + '">' + fmtDate(new Date(series[i].t)) + "</text>";
    });
    s += '<path d="' + line + " L" + x(days) + "," + y(0) + " L" + x(0) + "," + y(0) + ' Z" fill="url(#gfill)"/>';
    s += '<path class="line" d="' + line + '"/>';
    s += '<line class="cross" id="cx" y1="' + T + '" y2="' + (H - B) + '" style="display:none"/>';
    s += '<circle class="dot" id="cd" r="6" style="display:none"/>';
    s += '<circle class="dot" cx="' + x(days) + '" cy="' + y(max) + '" r="6" id="end-dot"/>';
    s += '<rect id="hit" x="' + L + '" y="' + T + '" width="' + (W - L - R) + '" height="' + (H - T - B) + '" fill="transparent"/></svg>';
    el.innerHTML = h + s;
    var hit = $("#hit"), svg = el.querySelector("svg");
    function move(ev) {
      var b = svg.getBoundingClientRect(), px = (ev.clientX - b.left) / b.width * W;
      var i = Math.max(0, Math.min(days, Math.round((px - L) / (W - L - R) * days)));
      var p = series[i];
      $("#cx").setAttribute("x1", x(i)); $("#cx").setAttribute("x2", x(i)); $("#cx").style.display = "";
      $("#cd").setAttribute("cx", x(i)); $("#cd").setAttribute("cy", y(p.v)); $("#cd").style.display = "";
      $("#end-dot").style.display = i === days ? "none" : "";
      showTip(ev, fmtFull(new Date(p.t)) + ": " + (p.v === 1 ? "1 resposta no total" : p.v + " respostas no total"));
    }
    hit.addEventListener("pointermove", move);
    hit.addEventListener("pointerdown", move);
    hit.addEventListener("pointerleave", function () {
      $("#cx").style.display = "none"; $("#cd").style.display = "none"; $("#end-dot").style.display = ""; hideTip();
    });
  }

  /* ---------- Dica ---------- */
  var tip = $("#tip");
  function showTip(ev, text) {
    tip.textContent = text; tip.style.opacity = 1;
    var w = tip.offsetWidth, x = Math.min(ev.clientX + 14, window.innerWidth - w - 8);
    tip.style.left = Math.max(8, x) + "px"; tip.style.top = (ev.clientY + 16) + "px";
  }
  function hideTip() { tip.style.opacity = 0; }
  document.addEventListener("pointermove", function (ev) {
    var t = ev.target.closest && ev.target.closest("[data-tip]");
    if (t) showTip(ev, t.getAttribute("data-tip")); else if (!ev.target.closest || !ev.target.closest("#hit")) hideTip();
  });

  /* ---------- Render ---------- */
  function render() {
    var rows = ALL, n = rows.length, base = "Base: " + plural(n, "médico", "médicos");

    if (!n) {
      $("#meta-text").textContent = "Pesquisa: Acompanhamento de Pacientes Idosos · nenhuma resposta em dados/Cuidar_respostas.xlsx ainda";
      $("#kpis").innerHTML = kpi("users", "Pessoas que responderam", 0, "Sem respostas ainda", "");
      ["c-time", "c-dif", "c-maior", "c-open", "c-apos", "c-sabe", "c-pref"].forEach(function (id) {
        $("#" + id).innerHTML = head("Sem dados ainda") + '<div class="empty">Adicione respostas em dados/Cuidar_respostas.xlsx e rode gerar_dados.py.</div>';
      });
      $("#ent").innerHTML = "";
      return;
    }

    var participantes = rows.filter(function (r) { return r.participa; }).length;
    $("#meta-text").textContent = "Pesquisa: Acompanhamento de Pacientes Idosos · " + plural(n, "resposta", "respostas");
    $("#period-txt").textContent = fmtFull(rows[0].data) + " a " + fmtFull(rows[n - 1].data);

    var last = rows[n - 1].data.getTime();
    var l7 = rows.filter(function (r) { return r.data.getTime() > last - 7 * DAY; }).length;
    var p7 = rows.filter(function (r) { var t = r.data.getTime(); return t <= last - 7 * DAY && t > last - 14 * DAY; }).length;
    var arrow = l7 >= p7 ? UP : DOWN, tone = l7 >= p7 ? "up" : "down";
    $("#kpis").innerHTML =
      kpi("users", "Pessoas que responderam", n, arrow + " " + l7 + " nos últimos 7 dias · antes " + p7, tone) +
      kpi("phone", "Deixaram contato", participantes, pct(participantes, n) + "% de quem respondeu aceitou conversar", "");
    timeline(rows);

    $("#c-dif").innerHTML = head("Principais dificuldades no atendimento a pacientes idosos", base + " · marcar até 3") + bars(count(rows, "dif", true), n, 8);
    $("#c-maior").innerHTML = head("Maior dificuldade no cuidado dos pacientes idosos", base + " · marcar até 2") + bars(count(rows, "maior", true), n, 6);
    var op = rows.filter(function (r) { return r.desafio; });
    $("#c-open").innerHTML = head("Desafios que não mencionamos", plural(op.length, "relato", "relatos") + " em resposta aberta") +
      (op.length ? '<div class="quotes">' + op.slice(0, 40).map(function (r) {
        return '<div class="quote"><p>' + esc(r.desafio) + "</p><small>" + esc(espLabel(r)) + " · " + fmtFull(r.data) + "</small></div>";
      }).join("") + "</div>" : '<div class="empty">Nenhum relato ainda.</div>');

    $("#c-apos").innerHTML = head("Como é o acompanhamento do idoso depois da consulta", base) + donut(count(rows, "apos"), n);
    $("#c-sabe").innerHTML = head("Como sabe se o paciente toma os remédios corretamente", base) + bars(count(rows, "sabe"), n, 6);
    $("#c-pref").innerHTML = head("Como prefere receber essas informações", base + " · se existisse uma plataforma que mostrasse isso") + columns(count(rows, "pref", true), n);

    /* Entrevistas */
    var comEsp = rows.filter(function (r) { return r.esp; });
    var fund = [], func = [];
    ENTREVISTAS.forEach(function (e) {
      (e.fund || []).forEach(function (t) { fund.push({ t: t, who: e.nome || e.esp || "" }); });
      (e.func || []).forEach(function (t) { func.push({ t: t, who: e.nome || e.esp || "" }); });
    });
    function lista(titulo, sub, items) {
      return '<article class="card c4"><div class="obs-head"><h3>' + esc(titulo) + '</h3><span class="count">' + items.length + '</span></div><div class="sub">' + esc(sub) + "</div>" +
        (items.length ? '<ul class="obs-list">' + items.map(function (o) {
          return "<li><span>" + esc(o.t) + "</span>" + (o.who ? "<small>" + esc(o.who) + "</small>" : "") + "</li>";
        }).join("") + "</ul>" : '<div class="empty">Nenhuma observação ainda — adicione em dados/entrevistas.txt.</div>') + "</article>";
    }
    $("#ent").innerHTML =
      '<article class="card c4">' + head("Profissão e especialidade de quem respondeu", "Informado por " + comEsp.length + " de " + n) + bars(count(comEsp, "esp"), comEsp.length, 6) + "</article>" +
      lista("Fundamentação da ideia", "O que mostra que o problema existe e que a solução faz sentido", fund) +
      lista("Funcionalidades para a plataforma", "O que os médicos pediram ou sugeriram nas conversas", func);
  }

  render();
})();
