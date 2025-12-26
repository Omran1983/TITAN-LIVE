import { defaultPolicy, loadPolicy, Policy } from "./policy";

export type Employee = {
  id:string; first_name:string; last_name:string; designation:string; department:string;
  base_salary:number; transport_mode:"bus"|"car"|"bike"|"shuttle"; distance_km:number;
};
export type MonthRow = {
  employee_id:string; employee:string; designation:string; period:string;
  basic:number; transport:number; other_allowances:number; allowances:number;
  ot_weekday_h:number; ot_weekend_h:number; ot_holiday_h:number; ot_pay:number;
  gross:number; paye:number; csg_emp:number; nsf_emp:number; other_deductions:number; total_deductions:number; net:number;
  csg_er:number; nsf_er:number; employer_cost:number;
};

export type LeaveRow = { id:string; employee:string; type:"Annual"|"Sick"|"Unpaid"; start:string; end:string; days:number; status:"approved"|"rejected"|"pending" };

export const fmt = (n:number)=> new Intl.NumberFormat("en-MU",{style:"currency",currency:"MUR",maximumFractionDigits:0}).format(n);

export const employees: Employee[] = [
  ["0a1918d7-0b68-46df-886c-e3b72cb0609a","John","Roussety","HR Manager","HR", 78000,"car",18],
  ["fe30c868-1f27-4d73-8ca5-08d0a8395cf0","Jane","Doe","Accountant","Finance", 62000,"bus",12],
  ["d9aa877a-424d-4fbd-808a-a2ae59f08aeb","Alice","Tester","QA Engineer","Tech", 54000,"bus",16],
  ["1b2f0f35-0aa3-4a7b-8d8b-111122223333","Kevin","Pillay","Software Engineer","Tech", 90000,"car",22],
  ["2c3f1a46-1bb4-5c8c-9e9c-222233334444","Aisha","Ramdin","Ops Coordinator","Operations", 48000,"bus",9],
  ["3d4e2b57-2cc5-6d9d-af0d-333344445555","Nabil","Goolam","Sales Exec","Sales", 52000,"car",15],
  ["4e5f3c68-3dd6-7eae-b01e-444455556666","Priya","Chummun","Marketing Lead","Marketing", 70000,"car",14],
  ["5f604d79-4ee7-8fbf-c12f-555566667777","Samuel","Appadoo","Support Agent","Support", 38000,"bus",11],
  ["60715e8a-5ff8-90c0-d23f-666677778888","Maya","Hossen","Payroll Officer","Finance", 65000,"bike",8],
  ["71826f9b-6g09-a1d1-e34f-777788889999","Yash","Jugnauth","Data Analyst","Tech", 80000,"car",20],
].map(e=>({ id:e[0], first_name:e[1], last_name:e[2], designation:e[3], department:e[4], base_salary:e[5] as number, transport_mode:e[6] as any, distance_km:e[7] as number }));

function lastSixMonths(): string[] {
  const out:string[]=[]; const d=new Date();
  for(let i=0;i<6;i++){ const y=d.getFullYear(); const m=d.getMonth()+1; out.push(`${y}-${String(m).padStart(2,"0")}`); d.setMonth(d.getMonth()-1); }
  return out.reverse();
}
function hourlyRateMonthly(p:Policy, basic:number){ return basic / (p.workDays * p.workHoursPerDay); }
function rnd(n:number){ return Math.round(n); }

export function genPayroll(policy?: Partial<Policy>): MonthRow[] {
  const p:Policy = { ...defaultPolicy, ...(policy||{}), ...(typeof window!=="undefined" ? loadPolicy() : {}) };
  const months = lastSixMonths();
  const rows: MonthRow[] = [];

  for(const period of months){
    for(const e of employees){
      const basic = e.base_salary;
      const hr = hourlyRateMonthly(p, basic);

      // random demo inputs (hours)
      const wkd = Math.floor(Math.random()*10);     // 0–9h
      const wke = Math.floor(Math.random()*6);      // 0–5h
      const hol = Math.floor(Math.random()*4);      // 0–3h

      // Transport allowance (monthly): 2 trips/day * distance * workDays * perKm[mode]
      const perKm = p.transport.perKm[e.transport_mode];
      const transport = rnd(2 * e.distance_km * p.workDays * perKm);

      // Other allowance (role/dept heuristics)
      const other_allowances = (e.designation.includes("Manager")||e.designation.includes("Lead")? 3500: 2000) + (e.department==="Sales"? 1500: 1000);
      const allowances = transport + other_allowances;

      // OT pay with multipliers (weekday/weekend/holiday)
      const ot_pay = rnd(wkd * hr * p.ot.weekday + wke * hr * p.ot.weekend + hol * hr * p.ot.holiday);

      // Gross
      const gross = basic + ot_pay + allowances;

      // Employee deductions
      const csg_emp = rnd(basic * (basic <= p.csgEmp.threshold ? p.csgEmp.low : p.csgEmp.high));
      const nsf_emp = Math.min(rnd(basic * p.nsfEmp.rate), p.nsfEmp.cap);
      const paye = rnd(gross * (gross <= p.paye.band1Limit ? p.paye.band1Rate : p.paye.band2Rate));
      const other_deductions = rnd(gross * p.otherEmpPct);
      const total_deductions = csg_emp + nsf_emp + paye + other_deductions;

      const net = gross - total_deductions;

      // Employer contributions
      const csg_er = rnd(basic * (basic <= p.employer.csg.threshold ? p.employer.csg.low : p.employer.csg.high));
      const nsf_er = rnd(basic * p.employer.nsf.basic + (ot_pay + allowances) * p.employer.nsf.extras);
      const employer_cost = gross + csg_er + nsf_er;

      rows.push({
        employee_id:e.id, employee:`${e.first_name} ${e.last_name}`, designation:e.designation, period,
        basic, transport, other_allowances, allowances,
        ot_weekday_h:wkd, ot_weekend_h:wke, ot_holiday_h:hol, ot_pay,
        gross, paye, csg_emp, nsf_emp, other_deductions, total_deductions, net,
        csg_er, nsf_er, employer_cost
      });
    }
  }
  return rows;
}

export function genLeaves(): LeaveRow[] {
  const types:LeaveRow["type"][]=["Annual","Sick","Unpaid"];
  const statuses:LeaveRow["status"][]=["approved","rejected","pending"];
  const out:LeaveRow[]=[];
  for (const e of employees.slice(0,8)){
    const start = new Date(); start.setDate(start.getDate() - Math.floor(Math.random()*60));
    const len = 1 + Math.floor(Math.random()*4);
    const end = new Date(start); end.setDate(start.getDate()+len-1);
    out.push({ id:cryptoRandom(), employee:`${e.first_name} ${e.last_name}`,
      type: types[Math.floor(Math.random()*types.length)],
      status: statuses[Math.floor(Math.random()*statuses.length)],
      start: start.toISOString().slice(0,10), end: end.toISOString().slice(0,10), days: len
    });
  }
  return out;
}
function cryptoRandom(){ try{ return crypto.randomUUID(); }catch{ return Math.random().toString(36).slice(2); } }
