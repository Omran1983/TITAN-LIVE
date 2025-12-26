// src/components/citadel/Panel.tsx
import React from "react";

export const Panel: React.FC<{
    title: string;
    subtitle?: string;
    children: React.ReactNode;
    right?: React.ReactNode;
}> = ({ title, subtitle, children, right }) => (
    <div className="rounded-2xl border border-white/10 bg-black/25 backdrop-blur p-4">
        <div className="flex items-start gap-3">
            <div className="flex-1">
                <div className="text-white font-semibold">{title}</div>
                {subtitle ? <div className="text-white/50 text-sm mt-1">{subtitle}</div> : null}
            </div>
            {right}
        </div>
        <div className="mt-4">{children}</div>
    </div>
);
