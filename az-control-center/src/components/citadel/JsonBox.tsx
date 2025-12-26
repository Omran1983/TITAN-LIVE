// src/components/citadel/JsonBox.tsx
import React from "react";

export const JsonBox: React.FC<{ value: any }> = ({ value }) => {
    const text = typeof value === "string" ? value : JSON.stringify(value, null, 2);
    return (
        <pre className="text-xs text-white/75 bg-black/40 border border-white/10 rounded-xl p-3 overflow-auto max-h-[420px]">
            {text}
        </pre>
    );
};
