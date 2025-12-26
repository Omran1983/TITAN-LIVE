import { useRouter } from "next/router";

export default function Page(){
  const { query } = useRouter();
  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">Employee</h2>
      <div className="card"><div className="card-body">
        <p className="text-sm text-slate-600">
          Profile {String(query.id || "")} — transport allowance is set per employee and will be editable here soon.
        </p>
      </div></div>
    </div>
  );
}