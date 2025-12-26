import Link from "next/link";
import { useEffect, useState } from "react";
import { supabase } from "../../lib/supabase";

export default function Employees(){
  const [rows,setRows]=useState<any[]>([]);
  const [loading,setLoading]=useState(false);
  const [err,setErr]=useState<string|null>(null);

  async function load(){
    setErr(null); setLoading(true);
    const { data, error } = await supabase
      .from("employees")
      .select("id, first_name, last_name, position:job_title, transport_allowance_mur")
      .order("last_name");
    if(error) setErr(error.message);
    setRows(data || []);
    setLoading(false);
  }
  useEffect(()=>{ load(); },[]);

  async function save(id:string, val:number){
    const { error } = await supabase.from("employees")
      .update({ transport_allowance_mur: val })
      .eq("id", id);
    if(error) alert(error.message);
  }

  return (
    <div className="wrap">
      <h2 className="h2">Employees</h2>
      {err && <p className="error">{err}</p>}
      <div className="card">
        <div className="card-body">
          <table className="table">
            <thead><tr>
              <th>Name</th><th>Designation</th><th>Transport (MUR/mo)</th><th></th>
            </tr></thead>
            <tbody>
              {rows.map(r=>(
                <tr key={r.id}>
                  <td>{r.first_name} {r.last_name}</td>
                  <td>{r.position || "-"}</td>
                  <td>
                    <input className="input w-36" type="number"
                      defaultValue={r.transport_allowance_mur ?? 0}
                      onBlur={(e)=>save(r.id, Number(e.target.value))}
                    />
                  </td>
                  <td><Link className="btn" href={`/employees/${r.id}`}>Open profile</Link></td>
                </tr>
              ))}
              {rows.length===0 && <tr><td colSpan={4} className="muted">No employees</td></tr>}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
