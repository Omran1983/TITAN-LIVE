export type Policy = {
  workDays: number; workHoursPerDay: number;
  ot: { weekday: number; weekend: number; holiday: number };
  paye: { band1Limit: number; band1Rate: number; band2Rate: number };
  csgEmp: { threshold: number; low: number; high: number };
  nsfEmp: { rate: number; cap: number };
  otherEmpPct: number;
  employer: { csg: { threshold: number; low: number; high: number }, nsf: { basic: number; extras: number } };
  transport: { perKm: { bus:number; car:number; bike:number; shuttle:number } };
};

export const defaultPolicy: Policy = {
  workDays: 22, workHoursPerDay: 8,
  ot: { weekday: 1.5, weekend: 2.0, holiday: 2.5 },           // ← includes 2.5×
  paye: { band1Limit: 54166.67, band1Rate: 0.10, band2Rate: 0.15 },
  csgEmp: { threshold: 50000, low: 0.015, high: 0.03 },
  nsfEmp: { rate: 0.01, cap: 187 },
  otherEmpPct: 0.00,                                           // extra employee deduction (optional)
  employer: { csg: { threshold: 50000, low: 0.03, high: 0.06 }, nsf: { basic: 0.015, extras: 0.025 } },
  // Monthly transport ≈ 2 trips/day * distance_km * workDays * perKm[mode]
  // (editable on Settings)
  transport: { perKm: { bus: 6, car: 12, bike: 4, shuttle: 0 } }
};

const KEY = "policy";
export function loadPolicy(): Policy {
  if (typeof window === "undefined") return defaultPolicy;
  try {
    const raw = window.localStorage.getItem(KEY);
    return raw ? { ...defaultPolicy, ...JSON.parse(raw) } : defaultPolicy;
  } catch { return defaultPolicy; }
}
export function savePolicy(p: Policy){ if (typeof window!=="undefined") window.localStorage.setItem(KEY, JSON.stringify(p)); }
export function resetPolicy(){ if (typeof window!=="undefined") window.localStorage.removeItem(KEY); }
