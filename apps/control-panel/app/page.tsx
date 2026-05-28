type Release = { title: string; project: string; platforms: string; retention: string; status: string };

const kpis = [
  { label: "Gates awaiting approval", value: "3", sub: "Oldest: 4h 12m · Persona Panel on NH-04", tone: "alert" as const },
  { label: "Days since last release", value: "2", sub: "Target ≤ 8 · ✓ on cadence", tone: "neutral" as const },
  { label: "Cost / min · last 4 shorts", value: "$148", sub: "−12% vs. plan · ✓ in range", tone: "ok" as const },
  { label: "Rights ledger", value: "100%", sub: "12 / 12 published assets cleared", tone: "ok" as const },
];

const releases: Release[] = [
  { title: "Kathy 03 — Twilight Pass", project: "Kathy Flyover", platforms: "X · YT · TikTok", retention: "62%", status: "Live" },
  { title: "NH-02 — Pengold's Press Conference", project: "New Harmony", platforms: "X · YT · TikTok", retention: "71%", status: "Live" },
  { title: "Kathy 02 — Stormside", project: "Kathy Flyover", platforms: "X · YT · TikTok · IG", retention: "58%", status: "Live" },
  { title: "NH-01 — Annexation Day", project: "New Harmony", platforms: "X · YT · TikTok", retention: "54%", status: "Live" },
  { title: "Kathy 01 — Flyover", project: "Kathy Flyover", platforms: "X · YT", retention: "49%", status: "Live · Phase A first ship" },
];

const costs = [
  { vendor: "Veo 3.1 (Fast + Full)", value: "$1,247" },
  { vendor: "ComfyUI (EC2 g6.2xlarge)", value: "$284" },
  { vendor: "Claude (Opus + Sonnet)", value: "$92" },
  { vendor: "ElevenLabs", value: "$48" },
  { vendor: "Suno (Premier)", value: "$30" },
  { vendor: "Storage (R2 + S3)", value: "$11" },
];
const total = "$1,712";

const runs = [
  { agent: "Continuity", plane: "Production", target: "Kathy 04 · drift scan over 18 shots", started: "2m ago", status: "Running" },
  { agent: "Persona Panel", plane: "Concept", target: "NH-04 concept · 175 personas", started: "14m ago", status: "Pending gate" },
  { agent: "Rights Risk", plane: "Rights", target: "Kathy 03 master · pre-publish audit", started: "5m ago", status: "Cleared" },
  { agent: "Trailer", plane: "Distribution", target: "NH-03 · 3 hook variants + thumbnails", started: "28m ago", status: "Pending gate" },
];

const toneBorder = { alert: "border-l-[4px] border-accent", ok: "border-l-[4px] border-ok", neutral: "" } as const;
const toneValue = { alert: "text-accent", ok: "text-navy", neutral: "text-navy" } as const;

const pillCls = (status: string) => {
  if (status === "Live" || status === "Cleared") return "bg-[#E8F5E9] text-ok";
  if (status === "Running" || status.startsWith("Pending")) return "bg-[#FFF3E0] text-amber";
  return "bg-[#ECEFF1] text-muted";
};
const planeCls = (p: string) => {
  if (p === "Concept") return "bg-[#E3F2FD] text-[#1976D2]";
  if (p === "Production") return "bg-[#E8F5E9] text-[#388E3C]";
  if (p === "Rights") return "bg-[#FFF3E0] text-[#F57C00]";
  if (p === "Distribution") return "bg-[#F3E5F5] text-[#7B1FA2]";
  return "bg-[#ECEFF1] text-navy";
};

export default function Dashboard() {
  return (
    <div>
      <div className="grid grid-cols-4 gap-3">
        {kpis.map((k) => (
          <div key={k.label} className={`bg-panel border border-border rounded-lg p-4 ${toneBorder[k.tone]}`}>
            <div className="text-[11px] text-muted uppercase tracking-wide">{k.label}</div>
            <div className={`text-3xl font-bold mt-1.5 leading-none ${toneValue[k.tone]}`}>{k.value}</div>
            <div className="text-[11px] text-muted mt-1.5">{k.sub}</div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-[2fr_1fr] gap-4 mt-4">
        <div className="bg-panel border border-border rounded-lg overflow-hidden">
          <div className="px-4 py-3 bg-[#FAFBFC] border-b border-border flex justify-between items-center">
            <span className="text-[13px] font-semibold text-navy">Recent releases</span>
            <span className="text-[11px] text-accent cursor-pointer">View all →</span>
          </div>
          <table className="w-full text-[13px]">
            <thead>
              <tr className="bg-[#FAFBFC]">
                <Th>Title</Th><Th>Project</Th><Th>Platforms</Th><Th>24h retention</Th><Th>Status</Th>
              </tr>
            </thead>
            <tbody>
              {releases.map((r) => (
                <tr key={r.title} className="hover:bg-[#FAFBFC] border-b border-border last:border-0">
                  <td className="px-3 py-2.5">{r.title}</td>
                  <td className="px-3 py-2.5">{r.project}</td>
                  <td className="px-3 py-2.5">{r.platforms}</td>
                  <td className="px-3 py-2.5">{r.retention}</td>
                  <td className="px-3 py-2.5"><span className={`inline-block px-2 rounded-lg text-[11px] font-semibold ${pillCls(r.status)}`}>{r.status}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="bg-panel border border-border rounded-lg overflow-hidden">
          <div className="px-4 py-3 bg-[#FAFBFC] border-b border-border flex justify-between items-center">
            <span className="text-[13px] font-semibold text-navy">Pipeline cost · last 14d</span>
            <span className="text-[11px] text-accent cursor-pointer">Detail →</span>
          </div>
          <table className="w-full text-[13px]">
            <tbody>
              {costs.map((c) => (
                <tr key={c.vendor} className="border-b border-border">
                  <td className="px-3 py-2.5">{c.vendor}</td>
                  <td className="px-3 py-2.5 text-right font-mono text-muted">{c.value}</td>
                </tr>
              ))}
              <tr className="font-semibold">
                <td className="px-3 py-2.5">Total</td>
                <td className="px-3 py-2.5 text-right font-mono">{total}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div className="bg-panel border border-border rounded-lg overflow-hidden mt-4">
        <div className="px-4 py-3 bg-[#FAFBFC] border-b border-border flex justify-between items-center">
          <span className="text-[13px] font-semibold text-navy">Active agent runs</span>
          <span className="text-[11px] text-accent cursor-pointer">All runs →</span>
        </div>
        <table className="w-full text-[13px]">
          <thead>
            <tr className="bg-[#FAFBFC]">
              <Th>Agent</Th><Th>Plane</Th><Th>Working on</Th><Th>Started</Th><Th>Status</Th>
            </tr>
          </thead>
          <tbody>
            {runs.map((r) => (
              <tr key={r.agent + r.target} className="hover:bg-[#FAFBFC] border-b border-border last:border-0">
                <td className="px-3 py-2.5 font-semibold">{r.agent}</td>
                <td className="px-3 py-2.5">
                  <span className={`inline-block px-2 py-px rounded-sm text-[10px] font-semibold uppercase tracking-wide ${planeCls(r.plane)}`}>{r.plane}</span>
                </td>
                <td className="px-3 py-2.5">{r.target}</td>
                <td className="px-3 py-2.5 font-mono text-muted">{r.started}</td>
                <td className="px-3 py-2.5">
                  <span className={`inline-block px-2 rounded-lg text-[11px] font-semibold ${pillCls(r.status)}`}>{r.status}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p className="mt-6 text-[11px] text-muted text-center">
        Ilyrium Studio OS · v0.1 scaffold · sample data from New Harmony + Kathy Flyover · companion to Control Panel design v0.1
      </p>
    </div>
  );
}

function Th({ children }: { children: React.ReactNode }) {
  return <th className="text-left px-3 py-2.5 font-semibold text-muted text-[11px] uppercase tracking-wide border-b border-border">{children}</th>;
}
