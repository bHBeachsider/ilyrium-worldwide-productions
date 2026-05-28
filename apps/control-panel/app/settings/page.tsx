import { dbHealth } from "@/lib/db";

export const dynamic = "force-dynamic";   // always re-check on each load

export default async function Settings() {
  const health = await dbHealth();
  const envSet = Boolean(process.env.DATABASE_URL);

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold text-navy">Settings</h1>

      <div className="bg-panel border border-border rounded-lg overflow-hidden">
        <div className="px-4 py-3 bg-[#FAFBFC] border-b border-border">
          <span className="text-[13px] font-semibold text-navy">Studio OS · Database connection</span>
        </div>
        <div className="p-5 space-y-3 text-[13px]">
          <Row k="DATABASE_URL env var" v={envSet ? "set" : "NOT SET"} tone={envSet ? "ok" : "danger"} />
          <Row k="Connection" v={health.ok ? "Connected" : "Failed"} tone={health.ok ? "ok" : "danger"} />
          <Row k="Tables in public schema" v={String(health.tables)} tone={health.tables >= 17 ? "ok" : health.tables > 0 ? "amber" : "danger"} />
          {!health.ok && health.error ? (
            <Row k="Error" v={health.error} tone="danger" />
          ) : null}
          {health.ok && health.tables < 17 ? (
            <div className="mt-3 p-3 bg-[#FFF3E0] border-l-[3px] border-amber rounded text-[12px]">
              Connected but the spine migration hasn&rsquo;t been applied yet. Run{" "}
              <span className="font-mono">db/migrations/0001_studio_os_spine.sql</span>{" "}
              in Neon&rsquo;s SQL Editor.
            </div>
          ) : null}
          {health.ok && health.tables >= 17 ? (
            <div className="mt-3 p-3 bg-[#E8F5E9] border-l-[3px] border-ok rounded text-[12px]">
              Studio OS spine is live. {health.tables} tables provisioned.
            </div>
          ) : null}
        </div>
      </div>

      <div className="bg-panel border border-border rounded-lg overflow-hidden">
        <div className="px-4 py-3 bg-[#FAFBFC] border-b border-border">
          <span className="text-[13px] font-semibold text-navy">Next slices</span>
        </div>
        <div className="p-5 text-[13px] space-y-2 text-muted">
          <p>Once DB is green, future settings live here: vendor key inventory, spend caps, user + role management, audit-log export.</p>
        </div>
      </div>
    </div>
  );
}

function Row({ k, v, tone }: { k: string; v: string; tone: "ok" | "amber" | "danger" }) {
  const toneCls = tone === "ok" ? "text-ok" : tone === "amber" ? "text-amber" : "text-danger";
  return (
    <div className="flex justify-between">
      <span className="text-muted">{k}</span>
      <span className={`font-mono font-semibold ${toneCls}`}>{v}</span>
    </div>
  );
}
