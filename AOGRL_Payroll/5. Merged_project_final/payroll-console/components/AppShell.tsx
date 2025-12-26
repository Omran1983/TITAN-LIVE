import React, { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/router";
import { supabase } from "../lib/supabase";
import { Home, Users, BadgeDollarSign, Clock, BarChart3, ShieldCheck, Settings, ChevronRight } from "lucide-react";

function AuthBar() {
  const [email, setEmail] = useState("");
  const [pass, setPass] = useState("");
  const [signedIn, setSignedIn] = useState(false);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setSignedIn(Boolean(data.session)));
    const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => setSignedIn(Boolean(s)));
    return () => sub.subscription.unsubscribe();
  }, []);

  return (
    <div className="flex items-center gap-2">
      {!signedIn ? (
        <>
          <input className="input px-3 py-2" placeholder="email" value={email} onChange={e=>setEmail(e.target.value)} />
          <input className="input px-3 py-2" placeholder="password" type="password" value={pass} onChange={e=>setPass(e.target.value)} />
          <button
            className="btn btn-primary"
            onClick={async()=>{ await supabase.auth.signInWithPassword({ email, password: pass }); }}
          >
            Sign in
          </button>
        </>
      ) : (
        <button className="btn btn-ghost" onClick={async ()=>{ await supabase.auth.signOut(); }}>Sign out</button>
      )}
    </div>
  );
}

function NavItem({ href, label, icon:Icon }:{href:string;label:string;icon:any}) {
  const r = useRouter();
  const active = r.pathname === href || r.pathname.startsWith(href + "/");
  return (
    <Link href={href}
      className={`flex items-center justify-between rounded-xl px-3 py-2 text-sm ${active ? "bg-slate-900 text-white" : "hover:bg-slate-100"}`}>
      <span className="flex items-center gap-2">
        <Icon className="h-4 w-4" /> {label}
      </span>
      <ChevronRight className="h-4 w-4 opacity-60" />
    </Link>
  );
}

export default function AppShell({ children }:{children: React.ReactNode}) {
  return (
    <div className="min-h-screen">
      <header className="border-b bg-white">
        <div className="container-xxl flex h-16 items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="h-8 w-8 rounded-xl bg-slate-900" />
            <span className="text-lg font-semibold">AOGRL · HR & Payroll</span>
          </div>
          <AuthBar />
        </div>
      </header>

      <div className="container-xxl grid grid-cols-1 lg:grid-cols-[250px_1fr] gap-6 py-6">
        <aside className="card">
          <div className="card-body space-y-1">
            <NavItem href="/dashboard" label="Dashboard" icon={Home} />
            <NavItem href="/employees" label="Employees" icon={Users} />
            <NavItem href="/payroll" label="Payroll" icon={BadgeDollarSign} />
            <NavItem href="/time" label="Time & Attendance" icon={Clock} />
            <NavItem href="/reports" label="Reports" icon={BarChart3} />
            <NavItem href="/compliance" label="Compliance" icon={ShieldCheck} />
            <NavItem href="/settings" label="Settings" icon={Settings} />
          </div>
        </aside>

        <main>{children}</main>
      </div>
    </div>
  );
}
