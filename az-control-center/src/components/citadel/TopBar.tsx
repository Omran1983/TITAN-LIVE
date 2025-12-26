// src/components/citadel/TopBar.tsx
import React from "react";

export const TopBar: React.FC<{
    token: string;
    setToken: (v: string) => void;
    title?: string;
}> = ({ token, setToken, title = "TITAN / AZ — Glass Citadel" }) => {
    return (
        <div className="h-14 border-b border-white/10 bg-black/30 backdrop-blur flex items-center px-4 gap-4">
            <div className="flex items-center gap-3">
                <div className="h-8 w-8 rounded-xl bg-white/10 border border-white/10 flex items-center justify-center">
                    <span className="text-xs text-white/70">AZ</span>
                </div>
                <div className="text-white font-semibold">{title}</div>
            </div>

            <div className="flex-1" />

            <div className="flex items-center gap-2">
                <span className="text-xs text-white/50">Bearer Token</span>
                <select
                    title="User Token"
                    className="bg-white/5 border border-white/10 text-white/80 text-sm rounded-lg px-3 py-2 outline-none"
                    value={token}
                    onChange={(e) => setToken(e.target.value)}
                >
                    <option value="PUBLIC">PUBLIC</option>
                    <option value="OPERATOR">OPERATOR</option>
                    <option value="ADMIN">ADMIN</option>
                </select>
            </div>
        </div>
    );
};
