import React from 'react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs) {
    return twMerge(clsx(inputs));
}

export function Card({ className, children, ...props }) {
    return (
        <div
            className={cn(
                "rounded-xl border border-slate-800 bg-slate-900/50 backdrop-blur-sm shadow-sm transition-all hover:bg-slate-900/70",
                className
            )}
            {...props}
        >
            {children}
        </div>
    );
}

export function CardHeader({ className, children }) {
    return <div className={cn("flex flex-col space-y-1.5 p-6", className)}>{children}</div>;
}

export function CardTitle({ className, children }) {
    return <h3 className={cn("font-semibold leading-none tracking-tight text-slate-100", className)}>{children}</h3>;
}

export function CardContent({ className, children }) {
    return <div className={cn("p-6 pt-0", className)}>{children}</div>;
}
