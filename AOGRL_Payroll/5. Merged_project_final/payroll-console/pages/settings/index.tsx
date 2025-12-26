export default function Page(){
  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">Settings</h2>
      <div className="card"><div className="card-body space-y-2">
        <p className="text-sm text-slate-600">Admin can configure tax bands, overtime multipliers, and employer rates (UI editor coming next).</p>
        <ul className="list-disc pl-5 text-sm text-slate-700">
          <li>Transport allowance is set per employee (see Employee Profile).</li>
          <li>Public holiday OT default: 2.5×; normal OT: 1.5×; Sunday: 2×.</li>
        </ul>
      </div></div>
    </div>
  );
}
