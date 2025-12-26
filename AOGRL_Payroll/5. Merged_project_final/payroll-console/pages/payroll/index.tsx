"use client";
import { useMemo, useState } from "react";
import { genPayroll, fmt } from "../../lib/demo";
import { loadPolicy } from "../../lib/policy";

function months(pay:any[]){ return Array.from(new Set(pay.map((p:any)=>p.period))).sort(); }

export default function Page(){
  const policy = loadPolicy();
  const full = genPayroll(policy);
  const opts = months(full);
  const [period, setPeriod] = useState(opts[opts.length-1]);
  const rows = useMemo(()=> full.filter(r=>r.period===period), [full,period]);

  const totals = rows.reduce((a:any,r:any)=>({
    basic:a.basic+r.basic, transport:a.transport+r.transport, other_allow:a.other_allow+r.other_allowances,
    allowances:a.allowances+r.allowances, ot:a.ot+r.ot_pay, gross:a.gross+r.gross,
    paye:a.paye+r.paye, csg_emp:a.csg_emp+r.csg_emp, nsf_emp:a.nsf_emp+r.nsf_emp, other:a.other+r.other_deductions,
    total:a.total+r.total_deductions, net:a.net+r.net, csg_er:a.csg_er+r.csg_er, nsf_er:a.nsf_er+r.nsf_er, employer:a.employer+r.employer_cost
  }), {basic:0,transport:0,other_allow:0,allowances:0,ot:0,gross:0,paye:0,csg_emp:0,nsf_emp:0,other:0,total:0,net:0,csg_er:0,nsf_er:0,employer:0});

  return (
    <div className="space-y-4">
      <div className="flex items-end justify-between gap-3">
        <h2 className="text-2xl font-bold">Payroll</h2>
        <div className="flex items-center gap-2">
          <label className="text-sm">Period</label>
          <select className="btn" value={period} onChange={e=>setPeriod(e.target.value)}>
            {opts.map(m=><option key={m} value={m}>{m}</option>)}
          </select>
          <a className="btn" href="/settings">Settings</a>
        </div>
      </div>

      <div className="card"><div className="card-body overflow-x-auto">
        <table className="table min-w-[1600px]">
          <thead>
            <tr>
              <th>Employee</th><th>Designation</th>
              <th>Basic</th><th>Transport</th><th>Other Allw</th><th>Total Allw</th>
              <th>OT h (1.5/2/2.5)</th><th>OT Pay</th>
              <th>Gross</th>
              <th>PAYE</th><th>CSG Emp</th><th>NSF Emp</th><th>Other</th><th>Total Deduct</th><th>Net</th>
              <th>CSG ER</th><th>NSF ER</th><th>Employer Cost</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r:any)=>(
              <tr key={r.employee_id}>
                <td>{r.employee}</td>
                <td>{r.designation}</td>
                <td>{fmt(r.basic)}</td>
                <td>{fmt(r.transport)}</td>
                <td>{fmt(r.other_allowances)}</td>
                <td>{fmt(r.allowances)}</td>
                <td>{r.ot_weekday_h}/{r.ot_weekend_h}/{r.ot_holiday_h}</td>
                <td>{fmt(r.ot_pay)}</td>
                <td>{fmt(r.gross)}</td>
                <td>{fmt(r.paye)}</td>
                <td>{fmt(r.csg_emp)}</td>
                <td>{fmt(r.nsf_emp)}</td>
                <td>{fmt(r.other_deductions)}</td>
                <td>{fmt(r.total_deductions)}</td>
                <td className="font-semibold">{fmt(r.net)}</td>
                <td>{fmt(r.csg_er)}</td>
                <td>{fmt(r.nsf_er)}</td>
                <td className="font-semibold">{fmt(r.employer_cost)}</td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr>
              <td colSpan={2}>Totals</td>
              <td>{fmt(totals.basic)}</td>
              <td>{fmt(totals.transport)}</td>
              <td>{fmt(totals.other_allow)}</td>
              <td>{fmt(totals.allowances)}</td>
              <td></td>
              <td>{fmt(totals.ot)}</td>
              <td>{fmt(totals.gross)}</td>
              <td>{fmt(totals.paye)}</td>
              <td>{fmt(totals.csg_emp)}</td>
              <td>{fmt(totals.nsf_emp)}</td>
              <td>{fmt(totals.other)}</td>
              <td>{fmt(totals.total)}</td>
              <td>{fmt(totals.net)}</td>
              <td>{fmt(totals.csg_er)}</td>
              <td>{fmt(totals.nsf_er)}</td>
              <td>{fmt(totals.employer)}</td>
            </tr>
          </tfoot>
        </table>
      </div></div>
    </div>
  );
}
