// Neon serverless Postgres client.
// Uses the @neondatabase/serverless driver — connection-pooled, edge-safe.
//
// Set DATABASE_URL in Railway service variables (Settings → Variables).
// Use the POOLED connection string (contains "-pooler" in the hostname).
//
// Build-time safety: the proxy's get trap does NOT eagerly call getSql().
// This lets Next.js collect page data without a live DB connection.
// The build succeeds; the settings page shows "NOT SET" until the env var is added.

import { neon, type NeonQueryFunction } from "@neondatabase/serverless";

let _sql: NeonQueryFunction<false, false> | undefined;

function getSql(): NeonQueryFunction<false, false> {
  if (!_sql) {
    if (!process.env.DATABASE_URL) {
      throw new Error(
        "[db] DATABASE_URL is not set. Set it in the Railway service variables."
      );
    }
    _sql = neon(process.env.DATABASE_URL);
  }
  return _sql;
}

export const sql: NeonQueryFunction<false, false> = new Proxy(
  (() => {}) as unknown as NeonQueryFunction<false, false>,
  {
    apply(_target, thisArg, args) {
      // Tagged-template call: sql`SELECT ...` — initialize lazily.
      return Reflect.apply(getSql(), thisArg, args);
    },
    get(_target, prop, receiver) {
      // Only forward property reads if a connection already exists.
      // Eagerly calling getSql() here triggers a build-time throw when
      // DATABASE_URL is absent — this guard prevents that.
      if (_sql) {
        return Reflect.get(_sql, prop, receiver);
      }
      return undefined;
    },
  }
);

// ---- Convenience types for the most-read tables ----
export type Project = {
  id: string;
  title: string;
  type: "short" | "pilot" | "series" | "commercial" | "feature";
  status: string;
  owner_id: string | null;
  budget_cents: number;
  greenlight_level: "G0" | "G1" | "G2" | "G3" | "G4" | "G5" | "G6" | "G7";
  created_at: string;
};

export type Concept = {
  id: string;
  project_id: string | null;
  logline: string;
  treatment_md: string | null;
  genre: string[] | null;
  audience: string[] | null;
  hook_emotional: string | null;
  hook_visual: string | null;
  ip_risk_score: number | null;
  persona_score: unknown | null;
  greenlight_level: string;
  created_by: string | null;
  created_at: string;
};

export type Release = {
  id: string;
  project_id: string;
  master_asset_id: string | null;
  platform: string | null;
  version_variant: string | null;
  hook_variant: string | null;
  scheduled_at: string | null;
  published_at: string | null;
  status: string;
};

export type AgentRun = {
  id: string;
  agent_name: string;
  plane: string;
  input_ref: string | null;
  output_ref: string | null;
  model_used: string | null;
  tokens_in: number | null;
  tokens_out: number | null;
  latency_ms: number | null;
  cost_cents: number | null;
  human_gate_status: string | null;
  started_at: string;
  completed_at: string | null;
};

export type GateApproval = {
  id: string;
  agent_run_id: string;
  gate_type: string;
  entity_type: string;
  entity_id: string;
  required_role: string;
  state: "pending" | "approved" | "rejected" | "revision_requested" | "timeout" | "auto_approved";
  sla_hours: number;
  requested_at: string;
  resolved_at: string | null;
  resolved_by: string | null;
  resolution_note: string | null;
};

// ---- Health-check query (used by the Settings page) ----
export async function dbHealth(): Promise<{ ok: boolean; tables: number; error?: string }> {
  if (!process.env.DATABASE_URL) {
    return { ok: false, tables: 0, error: "DATABASE_URL not configured — add it in Railway service variables" };
  }
  try {
    const rows = (await sql`
      select count(*)::int as count
      from information_schema.tables
      where table_schema = 'public'
    `) as { count: number }[];
    return { ok: true, tables: rows[0]?.count ?? 0 };
  } catch (e: unknown) {
    return { ok: false, tables: 0, error: e instanceof Error ? e.message : String(e) };
  }
}
