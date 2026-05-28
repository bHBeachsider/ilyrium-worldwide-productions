-- =====================================================================
-- Ilyrium Studio OS — Spine Migration 0001
-- =====================================================================
-- Run this once in Neon's SQL Editor to provision the full Studio OS
-- schema. Idempotent: safe to re-run (uses IF NOT EXISTS throughout).
--
-- Schema sources:
--   - Founding Plan Appendix C (12 spine tables)
--   - Control Panel + Orchestration Design Appendix A (5 additional tables)
--
-- Postgres 16+ assumed. Compatible with Neon serverless.
-- =====================================================================

-- ---- Extensions ----
create extension if not exists pgcrypto;   -- gen_random_uuid()
create extension if not exists vector;     -- pgvector for similarity search

-- ---------------------------------------------------------------
-- USERS (referenced by many tables; create first)
-- ---------------------------------------------------------------
create table if not exists users (
    id              uuid primary key default gen_random_uuid(),
    email           text unique not null,
    display_name    text,
    role            text not null check (role in (
                        'showrunner','ai_director','technical_director','producer',
                        'growth_lead','writer','editor','rights_advisor','observer','admin'
                    )),
    clerk_id        text unique,   -- maps to Clerk user when auth is wired
    created_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------
-- PROJECTS
-- ---------------------------------------------------------------
create table if not exists projects (
    id                  uuid primary key default gen_random_uuid(),
    title               text not null,
    type                text not null check (type in ('short','pilot','series','commercial','feature')),
    status              text not null default 'active',
    owner_id            uuid references users(id),
    budget_cents        integer not null default 0,
    greenlight_level    text check (greenlight_level in ('G0','G1','G2','G3','G4','G5','G6','G7')) default 'G0',
    created_at          timestamptz not null default now()
);

create index if not exists projects_status_idx on projects(status);
create index if not exists projects_greenlight_idx on projects(greenlight_level);

-- ---------------------------------------------------------------
-- CONCEPTS
-- ---------------------------------------------------------------
create table if not exists concepts (
    id                  uuid primary key default gen_random_uuid(),
    project_id          uuid references projects(id) on delete cascade,
    logline             text not null,
    treatment_md        text,
    genre               text[],
    audience            text[],
    hook_emotional      text,
    hook_visual         text,
    ip_risk_score       integer check (ip_risk_score between 1 and 5),
    persona_score       jsonb,
    greenlight_level    text check (greenlight_level in ('G0','G1','G2','G3','G4','G5','G6','G7')) default 'G0',
    created_by          uuid references users(id),
    created_at          timestamptz not null default now()
);

create index if not exists concepts_project_idx on concepts(project_id);
create index if not exists concepts_greenlight_idx on concepts(greenlight_level);

-- ---------------------------------------------------------------
-- CHARACTERS
-- ---------------------------------------------------------------
create table if not exists characters (
    id                      uuid primary key default gen_random_uuid(),
    project_id              uuid references projects(id) on delete cascade,
    name                    text not null,
    bible_md                text,
    voice_ref_asset_id      uuid,                       -- soft ref; populated when assets exist
    visual_refs             uuid[],                     -- array of asset ids
    canon_rules_md          text,
    prohibited_uses_md      text,
    created_at              timestamptz not null default now()
);

create index if not exists characters_project_idx on characters(project_id);

-- ---------------------------------------------------------------
-- LOCATIONS (referenced by shots; minimal for now)
-- ---------------------------------------------------------------
create table if not exists locations (
    id              uuid primary key default gen_random_uuid(),
    project_id      uuid references projects(id) on delete cascade,
    name            text not null,
    description     text,
    visual_refs     uuid[],
    created_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------
-- PROMPTS (referenced by shots/assets)
-- ---------------------------------------------------------------
create table if not exists prompts (
    id                  uuid primary key default gen_random_uuid(),
    project_id          uuid references projects(id) on delete set null,
    text                text not null,
    negative_text       text,
    reference_assets    uuid[],
    model_id            text,
    settings_json       jsonb,
    success_score       real,
    reuse_tag           text,
    text_embedding      vector(1536),     -- pgvector for similarity
    created_at          timestamptz not null default now()
);

create index if not exists prompts_reuse_tag_idx on prompts(reuse_tag);
create index if not exists prompts_project_idx on prompts(project_id);
-- Vector index (uncomment after first batch of inserts; ivfflat needs data to train)
-- create index prompts_embed_idx on prompts using ivfflat (text_embedding vector_cosine_ops) with (lists = 100);

-- ---------------------------------------------------------------
-- SCENES (used by shots; minimal)
-- ---------------------------------------------------------------
create table if not exists scenes (
    id              uuid primary key default gen_random_uuid(),
    project_id      uuid references projects(id) on delete cascade,
    scene_number    integer,
    description     text,
    created_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------
-- SHOTS
-- ---------------------------------------------------------------
create table if not exists shots (
    id                  uuid primary key default gen_random_uuid(),
    project_id          uuid references projects(id) on delete cascade,
    scene_id            uuid references scenes(id) on delete set null,
    shot_number         integer not null,
    description         text not null,
    camera              text,
    characters          uuid[],                 -- array of character ids
    location_id         uuid references locations(id) on delete set null,
    status              text not null default 'pending',
    approved_take_id    uuid,                   -- soft ref to assets(id); set after approval
    cost_cents          integer default 0,
    created_at          timestamptz not null default now()
);

create index if not exists shots_project_idx on shots(project_id);
create index if not exists shots_status_idx on shots(status);

-- ---------------------------------------------------------------
-- ASSETS
-- ---------------------------------------------------------------
create table if not exists assets (
    id              uuid primary key default gen_random_uuid(),
    project_id      uuid references projects(id) on delete set null,
    shot_id         uuid references shots(id) on delete set null,
    asset_type      text check (asset_type in ('image','video','voice','music','still','master','reference','board')),
    model_id        text,                   -- e.g. 'veo-3.1-full','comfyui-sdxl','midjourney-v7'
    prompt_id       uuid references prompts(id) on delete set null,
    uri             text not null,          -- r2://bucket/path or s3://...
    version         integer default 1,
    created_at      timestamptz not null default now()
);

create index if not exists assets_project_idx on assets(project_id);
create index if not exists assets_shot_idx on assets(shot_id);

-- ---------------------------------------------------------------
-- RIGHTS RECORDS
-- ---------------------------------------------------------------
create table if not exists rights_records (
    id                              uuid primary key default gen_random_uuid(),
    asset_id                        uuid references assets(id) on delete cascade,
    source_type                     text,           -- 'generated','licensed','public_domain','original_capture'
    creator                         text,
    model_used                      text,
    license_type                    text,
    commercial_use_allowed          boolean,
    third_party_refs                text[],
    likeness_risk                   text check (likeness_risk in ('none','low','medium','high')) default 'none',
    music_risk                      text check (music_risk in ('none','low','medium','high')) default 'none',
    trademark_risk                  text check (trademark_risk in ('none','low','medium','high')) default 'none',
    -- SAG-AFTRA 2026 fields
    synthetic_performer_flag        boolean default false,
    digital_replica_flag            boolean default false,
    training_data_outbound_flag     boolean default false,
    sag_aftra_notice_filed_at       timestamptz,
    -- General risk + release control
    risk_level                      text check (risk_level in ('low','medium','high')) default 'low',
    release_required                boolean default false,
    release_status                  text default 'pending',
    legal_notes                     text,
    approved_for_release            boolean default false,
    approved_by                     uuid references users(id),
    approved_at                     timestamptz
);

create index if not exists rights_records_asset_idx on rights_records(asset_id);
create index if not exists rights_records_release_idx on rights_records(approved_for_release);

-- ---------------------------------------------------------------
-- RELEASES
-- ---------------------------------------------------------------
create table if not exists releases (
    id                  uuid primary key default gen_random_uuid(),
    project_id          uuid references projects(id) on delete cascade,
    master_asset_id     uuid references assets(id),
    platform            text,           -- 'x','tiktok','youtube_shorts','youtube_long','instagram'
    version_variant     text,           -- 'A','B','C' for variants
    hook_variant        text,
    scheduled_at        timestamptz,
    published_at        timestamptz,
    status              text default 'scheduled',
    created_at          timestamptz not null default now()
);

create index if not exists releases_project_idx on releases(project_id);
create index if not exists releases_platform_idx on releases(platform);
create index if not exists releases_published_idx on releases(published_at desc);

-- ---------------------------------------------------------------
-- PERFORMANCE METRICS
-- ---------------------------------------------------------------
create table if not exists performance_metrics (
    id                      bigserial primary key,
    release_id              uuid references releases(id) on delete cascade,
    captured_at             timestamptz not null default now(),
    retention_curve_json    jsonb,
    sentiment_score         real,
    share_rate              real,
    save_rate               real,
    completion_rate         real,
    cpm                     real
);

create index if not exists perf_release_idx on performance_metrics(release_id, captured_at desc);

-- ---------------------------------------------------------------
-- GREENLIGHT SCORES
-- ---------------------------------------------------------------
create table if not exists greenlight_scores (
    id                  uuid primary key default gen_random_uuid(),
    concept_id          uuid references concepts(id) on delete cascade,
    level               text not null check (level in ('G0','G1','G2','G3','G4','G5','G6','G7')),
    scored_by           uuid references users(id),
    scored_at           timestamptz default now(),
    creative_score      integer,
    audience_score      integer,
    risk_score          integer,
    business_score      integer,
    decision            text not null check (decision in ('promote','hold','kill','reshape')),
    notes               text
);

create index if not exists greenlight_concept_idx on greenlight_scores(concept_id, scored_at desc);

-- ---------------------------------------------------------------
-- AGENT RUNS (production observability for every agent execution)
-- ---------------------------------------------------------------
create table if not exists agent_runs (
    id                  uuid primary key default gen_random_uuid(),
    agent_name          text not null,         -- 'development','persona_panel','script_doctor','prompt_engineer',
                                               -- 'continuity','rights_risk','trailer','analytics','slate'
    plane               text not null check (plane in ('concept','production','rights','distribution','studio_os')),
    input_ref           text,
    output_ref          text,
    model_used          text,
    tokens_in           integer,
    tokens_out          integer,
    latency_ms          integer,
    cost_cents          integer,
    human_gate_status   text check (human_gate_status in ('pending','approved','rejected','auto_approved','timeout','revision_requested')),
    started_at          timestamptz default now(),
    completed_at        timestamptz
);

create index if not exists agent_runs_status_idx on agent_runs(human_gate_status, started_at desc);
create index if not exists agent_runs_agent_idx on agent_runs(agent_name, started_at desc);

-- ---------------------------------------------------------------
-- GATE APPROVALS (HITL gate state machine)
-- ---------------------------------------------------------------
create table if not exists gate_approvals (
    id                  uuid primary key default gen_random_uuid(),
    agent_run_id        uuid references agent_runs(id) on delete cascade,
    gate_type           text not null,         -- e.g. 'concept.G1_to_G2', 'rights.release_authorize'
    entity_type         text not null,
    entity_id           uuid not null,
    required_role       text not null,
    required_cosigners  text[],
    state               text not null check (state in (
                            'pending','approved','rejected','revision_requested','timeout','auto_approved'
                        )) default 'pending',
    sla_hours           integer not null default 24,
    requested_at        timestamptz not null default now(),
    resolved_at         timestamptz,
    resolved_by         uuid references users(id),
    resolution_note     text,
    trace_reviewed      boolean default false
);

create index if not exists gate_state_idx on gate_approvals(state, requested_at);
create index if not exists gate_entity_idx on gate_approvals(entity_type, entity_id);

-- ---------------------------------------------------------------
-- EVENT LOG (durable, replay-safe pub-sub)
-- ---------------------------------------------------------------
create table if not exists event_log (
    id                  bigserial primary key,
    event_type          text not null,         -- e.g. 'concept.greenlit.G2','shot.generated','gate.requested'
    event_version       integer not null default 1,
    producer_plane      text not null check (producer_plane in ('concept','production','rights','distribution','studio_os')),
    idempotency_key     text unique,
    payload             jsonb not null,
    occurred_at         timestamptz default now()
);

create index if not exists event_log_type_time_idx on event_log(event_type, occurred_at desc);

-- ---------------------------------------------------------------
-- ADAPTER CALLS (model-vendor telemetry)
-- ---------------------------------------------------------------
create table if not exists adapter_calls (
    id                  bigserial primary key,
    agent_run_id        uuid references agent_runs(id) on delete set null,
    capability          text not null,         -- 'complete','generate_video','generate_image','synthesize_voice',
                                               -- 'generate_music','publish_release','audit_music','submit_render'
    vendor              text not null,         -- 'claude-opus-4-6','veo-3.1-full','elevenlabs',...
    cost_cents          integer,
    latency_ms          integer,
    status              text check (status in ('ok','retried','failed_then_fallback','refused_cap','failed')),
    attempt             integer default 1,
    fallback_chain      text[],
    occurred_at         timestamptz default now()
);

create index if not exists adapter_calls_capability_idx on adapter_calls(capability, occurred_at desc);
create index if not exists adapter_calls_vendor_idx on adapter_calls(vendor, occurred_at desc);

-- ---------------------------------------------------------------
-- COST CAPS (spend enforcement)
-- ---------------------------------------------------------------
create table if not exists cost_caps (
    id                      uuid primary key default gen_random_uuid(),
    scope_type              text not null check (scope_type in ('vendor','project','agent_run')),
    scope_id                text not null,
    period                  text not null check (period in ('monthly','total','per_run')),
    cap_cents               integer not null,
    current_cents           integer not null default 0,
    alert_threshold_pct     integer default 80,
    created_at              timestamptz default now()
);

create index if not exists cost_caps_scope_idx on cost_caps(scope_type, scope_id);

-- ---------------------------------------------------------------
-- AUDIT LOG (every state change in the studio)
-- ---------------------------------------------------------------
create table if not exists audit_log (
    id              bigserial primary key,
    actor           text not null,         -- 'agent:rights_risk' or 'user:<uuid>'
    action          text not null,
    entity_type     text not null,
    entity_id       uuid,
    before_json     jsonb,
    after_json      jsonb,
    occurred_at     timestamptz default now()
);

create index if not exists audit_log_entity_idx on audit_log(entity_type, entity_id, occurred_at desc);
create index if not exists audit_log_actor_idx on audit_log(actor, occurred_at desc);

-- =====================================================================
-- Verification queries — run these after the migration to confirm
-- =====================================================================
-- select count(*) as table_count from information_schema.tables
--   where table_schema='public';
-- -- Expect ~17 tables.
--
-- select extname from pg_extension where extname in ('pgcrypto','vector');
-- -- Expect 2 rows.
