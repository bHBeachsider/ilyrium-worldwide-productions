const concepts = [
  { id: "cnc_9f...", title: "The Pothole Coalition", project: "New Harmony", gl: "G3", glCls: "bg-[#E3F2FD] text-[#1976D2]", score: "4.6 / 5", risk: "Low", riskCls: "bg-[#E8F5E9] text-ok" },
  { id: "cnc_8a...", title: "The Library Sit-In", project: "New Harmony", gl: "G1 → G2 (pending)", glCls: "bg-[#FFF3E0] text-amber", score: "4.2 / 5", risk: "Low", riskCls: "bg-[#E8F5E9] text-ok" },
  { id: "cnc_7e...", title: "Kathy 04 · Storm Coast", project: "Kathy Flyover", gl: "G2", glCls: "bg-[#E3F2FD] text-[#1976D2]", score: "3.9 / 5", risk: "Low", riskCls: "bg-[#E8F5E9] text-ok" },
  { id: "cnc_6d...", title: "Mayor Pengold's Ferret", project: "New Harmony", gl: "G0", glCls: "bg-[#E8EDF2] text-navy", score: "—", risk: "Low", riskCls: "bg-[#E8F5E9] text-ok" },
  { id: "cnc_5c...", title: "The Annexation Reboot", project: "New Harmony", gl: "G0", glCls: "bg-[#E8EDF2] text-navy", score: "—", risk: "Medium", riskCls: "bg-[#FFF3E0] text-amber" },
  { id: "cnc_4b...", title: "Kathy 05 · Civic Choir", project: "Kathy Flyover", gl: "G0", glCls: "bg-[#E8EDF2] text-navy", score: "—", risk: "Low", riskCls: "bg-[#E8F5E9] text-ok" },
];

export default function Concepts() {
  return (
    <div className="bg-panel border border-border rounded-lg overflow-hidden">
      <div className="px-4 py-3 bg-[#FAFBFC] border-b border-border flex justify-between items-center">
        <span className="text-[13px] font-semibold text-navy">Concepts · {concepts.length} active</span>
        <span className="text-[11px] text-accent cursor-pointer">+ New concept</span>
      </div>
      <table className="w-full text-[13px]">
        <thead>
          <tr className="bg-[#FAFBFC]">
            <Th>ID</Th><Th>Title</Th><Th>Project</Th><Th>Greenlight</Th><Th>Persona score</Th><Th>IP risk</Th><Th>Owner</Th>
          </tr>
        </thead>
        <tbody>
          {concepts.map((c) => (
            <tr key={c.id} className="hover:bg-[#FAFBFC] border-b border-border last:border-0">
              <td className="px-3 py-2.5 font-mono text-muted">{c.id}</td>
              <td className="px-3 py-2.5">{c.title}</td>
              <td className="px-3 py-2.5">{c.project}</td>
              <td className="px-3 py-2.5"><span className={`inline-block px-2 rounded-lg text-[11px] font-semibold ${c.glCls}`}>{c.gl}</span></td>
              <td className="px-3 py-2.5">{c.score}</td>
              <td className="px-3 py-2.5"><span className={`inline-block px-2 rounded-lg text-[11px] font-semibold ${c.riskCls}`}>{c.risk}</span></td>
              <td className="px-3 py-2.5">Brad</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function Th({ children }: { children: React.ReactNode }) {
  return <th className="text-left px-3 py-2.5 font-semibold text-muted text-[11px] uppercase tracking-wide border-b border-border">{children}</th>;
}
