-- CuidarMais — modelo de dados do MVP (PostgreSQL 15 ou mais novo)
--
-- Explicação de cada tabela em docs/modelo-de-dados.md.
-- Quando a API for criada, este arquivo vira a primeira migração.

create extension if not exists pgcrypto;  -- gen_random_uuid()

-- ---------------------------------------------------------------------------
-- Tipos
-- ---------------------------------------------------------------------------

create type perfil_usuario    as enum ('idoso', 'cuidador', 'medico');
create type origem_remedio    as enum ('medico', 'familia', 'paciente');
create type estado_dose       as enum ('agendada', 'lembrada', 'adiada', 'tomada', 'alertada',
                                       'tomada_apos_alerta', 'perdida', 'cancelada');
create type motivo_alerta     as enum ('adiou_duas_vezes', 'sem_resposta');
create type acao_historico    as enum ('criado', 'editado', 'encerrado');
create type tipo_consentimento as enum ('termos_de_uso', 'dados_de_saude',
                                        'compartilhar_com_cuidador', 'compartilhar_com_medico');

-- ---------------------------------------------------------------------------
-- Pessoas
-- ---------------------------------------------------------------------------

-- Uma conta por pessoa que entra no app ou no painel.
create table usuarios (
  id            uuid primary key default gen_random_uuid(),
  nome          text not null,
  email         text not null,
  senha_hash    text not null,                 -- nunca a senha em texto
  perfil        perfil_usuario not null,
  telefone      text,
  detalhe       text,                          -- ex.: "Geriatria · CRM 123456"
  criado_em     timestamptz not null default now()
);
create unique index usuarios_email_unico on usuarios (lower(email));

-- A pessoa cuidada. Com app, tem uma conta em usuarios; sem app, não tem.
create table idosos (
  id               uuid primary key default gen_random_uuid(),
  usuario_id       uuid unique references usuarios (id) on delete set null,
  usa_app          boolean generated always as (usuario_id is not null) stored,
  nome             text not null,
  apelido          text,                       -- ex.: "Dona Maria"
  data_nascimento  date,
  condicoes        text,                       -- ex.: "Hipertensão, diabetes tipo 2"
  telefone         text,
  fuso_horario     text not null default 'America/Sao_Paulo',
  criado_por       uuid not null references usuarios (id),
  criado_em        timestamptz not null default now()
);

-- Cuidador <-> idoso. O parentesco é guardado dos dois lados.
create table vinculos (
  id           uuid primary key default gen_random_uuid(),
  idoso_id     uuid not null references idosos (id) on delete cascade,
  cuidador_id  uuid not null references usuarios (id) on delete cascade,
  cuidador_e   text not null,                  -- o que o cuidador é do idoso: "Filha"
  idoso_e      text not null,                  -- o que o idoso é do cuidador: "Mãe"
  criado_em    timestamptz not null default now(),
  removido_em  timestamptz
);
create unique index vinculos_ativo_unico on vinculos (idoso_id, cuidador_id) where removido_em is null;

-- Código que o cuidador gera e o idoso (com app) digita e aceita.
create table convites (
  id            uuid primary key default gen_random_uuid(),
  codigo        text not null unique,          -- 6 caracteres, ex.: "RUI482"
  cuidador_id   uuid not null references usuarios (id) on delete cascade,
  cuidador_e    text not null,
  idoso_e       text not null,
  expira_em     timestamptz not null default now() + interval '24 hours',
  idoso_id      uuid references idosos (id) on delete cascade,  -- quem respondeu
  aceito_em     timestamptz,
  recusado_em   timestamptz,
  criado_em     timestamptz not null default now(),
  check (not (aceito_em is not null and recusado_em is not null))
);

-- Médico <-> paciente.
create table medicos_pacientes (
  id           uuid primary key default gen_random_uuid(),
  medico_id    uuid not null references usuarios (id) on delete cascade,
  idoso_id     uuid not null references idosos (id) on delete cascade,
  criado_em    timestamptz not null default now(),
  removido_em  timestamptz
);
create unique index medicos_pacientes_ativo_unico on medicos_pacientes (medico_id, idoso_id) where removido_em is null;

-- Consentimentos da LGPD. Revogar não apaga a linha: marca revogado_em.
create table consentimentos (
  id            uuid primary key default gen_random_uuid(),
  usuario_id    uuid not null references usuarios (id) on delete cascade,  -- quem aceitou
  idoso_id      uuid references idosos (id) on delete cascade,             -- de quem são os dados
  tipo          tipo_consentimento not null,
  versao_texto  text not null,                 -- versão do texto aceito, ex.: "2026-11"
  aceito_em     timestamptz not null default now(),
  revogado_em   timestamptz
);

-- ---------------------------------------------------------------------------
-- Remédios
-- ---------------------------------------------------------------------------

create table medicamentos (
  id                uuid primary key default gen_random_uuid(),
  idoso_id          uuid not null references idosos (id) on delete cascade,
  nome              text not null,             -- "Losartana 50 mg"
  dose              text not null,             -- "1 comprimido"
  horarios          time[] not null check (cardinality(horarios) > 0),
  dias_semana       smallint[] not null default '{1,2,3,4,5,6,7}'
                      check (cardinality(dias_semana) > 0 and dias_semana <@ '{1,2,3,4,5,6,7}'),
  inicio            date not null,
  fim               date check (fim is null or fim >= inicio),
  prazo_alerta_min  smallint not null default 30 check (prazo_alerta_min between 5 and 240),
  origem            origem_remedio not null,
  criado_por        uuid not null references usuarios (id),
  criado_em         timestamptz not null default now(),
  atualizado_em     timestamptz not null default now(),
  encerrado_em      timestamptz
);
create index medicamentos_por_idoso on medicamentos (idoso_id) where encerrado_em is null;

-- Toda criação, edição e encerramento, com a versão antes e depois.
create table medicamentos_historico (
  id              uuid primary key default gen_random_uuid(),
  medicamento_id  uuid not null references medicamentos (id) on delete cascade,
  acao            acao_historico not null,
  alterado_por    uuid not null references usuarios (id),
  alterado_em     timestamptz not null default now(),
  antes           jsonb,                       -- null quando acao = 'criado'
  depois          jsonb not null
);
create index medicamentos_historico_por_remedio on medicamentos_historico (medicamento_id, alterado_em);

-- ---------------------------------------------------------------------------
-- Doses, confirmações e alertas
-- ---------------------------------------------------------------------------

-- Uma linha por horário de cada dia ("Losartana às 08:00 de 20/11").
create table doses (
  id                   uuid primary key default gen_random_uuid(),
  medicamento_id       uuid not null references medicamentos (id) on delete cascade,
  idoso_id             uuid not null references idosos (id) on delete cascade,
  agendada_para        timestamptz not null,
  estado               estado_dose not null default 'agendada',
  adiamentos           smallint not null default 0 check (adiamentos between 0 and 2),
  lembretes_enviados   smallint not null default 0,
  proximo_lembrete_em  timestamptz,            -- quando o agendador deve agir de novo
  unique (medicamento_id, agendada_para)
);
create index doses_por_idoso_e_dia on doses (idoso_id, agendada_para);
create index doses_para_o_agendador on doses (proximo_lembrete_em)
  where estado in ('agendada', 'lembrada', 'adiada', 'alertada');

-- Quem confirmou e quando. Só uma confirmação por dose.
create table confirmacoes (
  id               uuid primary key default gen_random_uuid(),
  dose_id          uuid not null unique references doses (id) on delete cascade,
  confirmado_por   uuid not null references usuarios (id),
  perfil           perfil_usuario not null check (perfil in ('idoso', 'cuidador')),
  confirmado_em    timestamptz not null default now()
);

-- Aviso ao cuidador. No máximo um por dose.
create table alertas (
  id             uuid primary key default gen_random_uuid(),
  dose_id        uuid not null unique references doses (id) on delete cascade,
  idoso_id       uuid not null references idosos (id) on delete cascade,
  motivo         motivo_alerta not null,
  criado_em      timestamptz not null default now(),
  resolvido_em   timestamptz,                  -- preenchido quando a dose é confirmada
  resolvido_por  uuid references usuarios (id)
);
create index alertas_abertos on alertas (idoso_id) where resolvido_em is null;

-- ---------------------------------------------------------------------------
-- Notificações
-- ---------------------------------------------------------------------------

-- Token do Firebase Cloud Messaging de cada celular.
create table dispositivos (
  id             uuid primary key default gen_random_uuid(),
  usuario_id     uuid not null references usuarios (id) on delete cascade,
  token_fcm      text not null unique,
  plataforma     text not null default 'android',
  criado_em      timestamptz not null default now(),
  ultimo_uso_em  timestamptz not null default now()
);
