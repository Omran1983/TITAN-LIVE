import React from "react";
import { Outlet } from "react-router-dom";
import Sidebar from "./components/layout/Sidebar";
import TopBar from "./components/layout/TopBar";

export default function App() {
    return (
        <div className="min-h-screen bg-slate-950 font-sans text-slate-200 selection:bg-sky-500/30">
            <div className="flex min-h-screen">
                {/* Permanent Sidebar */}
                <Sidebar />

                {/* Main */}
                <div className="flex-1 flex flex-col">
                    <TopBar />

                    <main className="flex-1 max-w-7xl mx-auto w-full p-4 md:p-6">
                        <Outlet />
                    </main>
                </div>
            </div>
        </div>
    );
}
