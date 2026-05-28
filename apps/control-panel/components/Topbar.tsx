export default function Topbar() {
  return (
    <div className="h-14 bg-panel border-b border-border flex items-center px-6 justify-between">
      <div className="text-[13px] text-muted">
        <span className="font-bold text-[#1A2533]">Dashboard</span>
        <span> · COO view</span>
      </div>
      <div className="flex gap-3 items-center text-xs text-muted">
        <span className="bg-[#E8F5E9] border border-[#C8E6C9] text-ok text-[11px] px-2.5 py-0.5 rounded-xl">● Studio OS healthy</span>
        <span className="bg-bg border border-border text-[11px] px-2.5 py-0.5 rounded-xl">EC2 stopped</span>
        <span>Brad Burns</span>
      </div>
    </div>
  );
}
