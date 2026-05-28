import Link from "next/link";

const sections: { label: string; items: { label: string; href?: string; badge?: number }[] }[] = [
  { label: "", items: [{ label: "Dashboard", href: "/" }] },
  { label: "Concept Plane", items: [
    { label: "Concepts", href: "/concepts", badge: 12 },
    { label: "Personas" },
    { label: "Greenlight" },
  ]},
  { label: "Production Plane", items: [
    { label: "Shots", href: "/shots" },
    { label: "Assets" },
    { label: "Prompts" },
  ]},
  { label: "Rights & Provenance", items: [
    { label: "Rights Ledger" },
    { label: "Union Filings" },
  ]},
  { label: "Distribution", items: [
    { label: "Releases" },
    { label: "Analytics" },
  ]},
  { label: "Studio OS", items: [
    { label: "Gates", href: "/gates", badge: 3 },
    { label: "Agent Runs" },
    { label: "Audit Log" },
    { label: "Settings", href: "/settings" },
  ]},
];

export default function Sidebar() {
  return (
    <aside className="w-56 bg-navy text-white py-5 flex-shrink-0">
      <div className="px-6 pb-5 border-b border-white/10 mb-3">
        <div className="text-xl font-bold tracking-wider">ILYRIUM</div>
        <div className="text-[10px] opacity-70 mt-0.5">Studio OS · v0.1</div>
      </div>
      <nav>
        {sections.map((section, si) => (
          <div key={si}>
            {section.label && (
              <div className="px-6 pt-4 pb-1.5 text-[10px] uppercase opacity-50 tracking-widest">
                {section.label}
              </div>
            )}
            {section.items.map((item, ii) => {
              const inner = (
                <span className="flex justify-between items-center w-full">
                  <span>{item.label}</span>
                  {item.badge ? (
                    <span className="bg-accent text-white text-[10px] px-1.5 py-px rounded-md font-bold">
                      {item.badge}
                    </span>
                  ) : null}
                </span>
              );
              return item.href ? (
                <Link key={ii} href={item.href}
                  className="block px-6 py-2.5 text-[13px] hover:bg-white/5 border-l-[3px] border-transparent">
                  {inner}
                </Link>
              ) : (
                <div key={ii}
                  className="px-6 py-2.5 text-[13px] opacity-60 cursor-not-allowed border-l-[3px] border-transparent">
                  {inner}
                </div>
              );
            })}
          </div>
        ))}
      </nav>
    </aside>
  );
}
