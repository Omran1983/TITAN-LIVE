import { useState, useEffect } from 'react';
import { createClient } from '@supabase/supabase-js';
import { formatMUR } from '../../lib/currency';

// Get env vars
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Mock RPC call (replace with actual RPC when DB is ready)
async function getKPIs(tenantId: string) {
  const mockData = {
    employees_count: 12,
    total_payroll: 520000,
    ot_cost: 15000,
    employer_cost: 80000,
  };
  return mockData;
}

export default function Dashboard() {
  const [kpi, setKpi] = useState({
    employees_count: 0,
    total_payroll: 0,
    ot_cost: 0,
    employer_cost: 0,
  });

  useEffect(() => {
    const fetchKPIs = async () => {
      const tenantId = process.env.TENANT_ID;
      if (!tenantId) return;

      const kpis = await getKPIs(tenantId);
      setKpi(kpis);
    };

    fetchKPIs();
  }, []);

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold mb-8">Dashboard</h1>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-lg shadow-md p-6 border">
            <h3 className="font-semibold text-gray-700">Total Employees</h3>
            <p className="text-3xl font-bold mt-2">{kpi.employees_count}</p>
          </div>

          <div className="bg-white rounded-lg shadow-md p-6 border">
            <h3 className="font-semibold text-gray-700">Payroll (This Month)</h3>
            <p className="text-3xl font-bold mt-2">{formatMUR(kpi.total_payroll)}</p>
          </div>

          <div className="bg-white rounded-lg shadow-md p-6 border">
            <h3 className="font-semibold text-gray-700">OT Cost (This Month)</h3>
            <p className="text-3xl font-bold mt-2">{formatMUR(kpi.ot_cost)}</p>
          </div>

          <div className="bg-white rounded-lg shadow-md p-6 border">
            <h3 className="font-semibold text-gray-700">Employer Cost (This Month)</h3>
            <p className="text-3xl font-bold mt-2">{formatMUR(kpi.employer_cost)}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
