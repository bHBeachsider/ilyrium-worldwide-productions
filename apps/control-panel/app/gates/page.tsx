export default function Gates() {
  return (
    <div>
      <div className="bg-panel border border-border rounded-lg overflow-hidden">
        <div className="px-4 py-3 bg-[#FAFBFC] border-b border-border flex justify-between items-center">
          <span className="text-[13px] font-semibold text-navy">HITL gate · Persona Panel on NH-04</span>
          <span className="bg-[#FFF3E0] text-amber text-[11px] font-semibold px-2 py-0.5 rounded-lg">Pending · 4h 12m</span>
        </div>

        <div className="grid grid-cols-[1fr_320px]">
          <div className="p-5 border-r border-border">
            <h2 className="m-0 text-navy text-xl">NH-04 · &ldquo;The Library Sit-In&rdquo;</h2>
            <div className="text-[13px] text-muted mt-1">
              Logline: A New Harmony librarian refuses to remove a banned book, and the entire town&rsquo;s media descends on her front desk.
            </div>

            <dl className="grid grid-cols-[100px_1fr] gap-x-4 gap-y-1.5 text-xs my-4">
              <dt className="text-muted">Project</dt><dd>New Harmony</dd>
              <dt className="text-muted">Concept</dt><dd>NH-04 · G1 → G2 promotion</dd>
              <dt className="text-muted">Agent</dt><dd>Persona Panel (Sonnet 4.6)</dd>
              <dt className="text-muted">Gate type</dt><dd>Showrunner approval to promote G1 → G2</dd>
              <dt className="text-muted">Cost</dt><dd className="font-mono">$0.42 (run) · $0 (gate)</dd>
            </dl>

            <h3 className="mt-4 mb-1.5 text-sm font-semibold">Panel verdict (excerpt)</h3>
            <div className="text-[13px] bg-[#FAFBFC] p-3 rounded border-l-[3px] border-accent">
              Top-resonating segment: <strong>civic-satire viewers + small-town nostalgia cluster</strong>.
              Hook clarity: 4.2/5 across 175 personas. Weakest element: the third act feels rushed — 38% of personas wanted
              a beat between the standoff and the reporters&rsquo; arrival. Sequel demand: 3.1/5 (moderate). Confusion risks:
              none material; one persona mistook the librarian for the mayor in test 17.
            </div>

            <div className="flex gap-2 mt-4">
              <button className="px-4 py-2.5 rounded-md bg-navy text-white text-[13px] font-semibold">Approve → promote to G2</button>
              <button className="px-4 py-2.5 rounded-md border border-border bg-white text-[13px] font-semibold">Request revision</button>
              <button className="px-4 py-2.5 rounded-md border border-[#FFCDD2] bg-white text-danger text-[13px] font-semibold">Reject (kill)</button>
            </div>

            <div className="text-[11px] text-muted mt-2.5">
              Approval is logged in <span className="font-mono">greenlight_scores</span> with note + outcome.
              Rejection requires a one-line rationale.
            </div>
          </div>

          <div className="p-5 bg-[#FAFBFC]">
            <div className="text-[11px] text-muted uppercase tracking-wide">Agent trace</div>
            <div className="font-mono text-xs leading-6 mt-2 space-y-0.5">
              <TraceLine ts="14:02:11" tag="INPUT" tagCls="text-[#1976D2]" data="concept NH-04 (logline + treatment)" />
              <TraceLine ts="14:02:12" tag="TOOL" tagCls="text-ok" data="load_personas(library_id=v1.2)" />
              <TraceLine ts="14:02:14" tag="TOOL" tagCls="text-ok" data="load_comp_works(genre=&quot;civic-satire&quot;)" />
              <TraceLine ts="14:02:15" tag="LLM" tagCls="text-accent" data="sonnet-4-6 · 175 persona evaluations · 24s" />
              <TraceLine ts="14:02:39" tag="OUTPUT" tagCls="text-accent" data="reception_report.json (3.2 KB)" />
              <TraceLine ts="14:02:40" tag="GATE" tagCls="text-amber font-bold" data="request_human_approval(showrunner, SLA=24h)" />
            </div>

            <div className="text-[11px] text-muted uppercase tracking-wide mt-4">SLA</div>
            <div className="text-[13px] mt-1">24h · 19h 48m remaining · ✓ within SLA</div>

            <div className="text-[11px] text-muted uppercase tracking-wide mt-4">References</div>
            <ul className="mt-1.5 ml-4 list-disc text-xs">
              <li>concept_id <span className="font-mono">cnc_8a4f...</span></li>
              <li>panel_run_id <span className="font-mono">run_pa_001b...</span></li>
              <li>persona library <span className="font-mono">v1.2</span></li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}

function TraceLine({ ts, tag, tagCls, data }: { ts: string; tag: string; tagCls: string; data: string }) {
  return (
    <div className="py-0.5">
      <span className="text-muted mr-3">{ts}</span>
      <span className={`inline-block w-20 font-semibold ${tagCls}`}>{tag}</span>
      <span>{data}</span>
    </div>
  );
}
