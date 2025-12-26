import React from 'react';

// Common structures for A2UI
// Based on f:\AION-ZERO\brain\architecture_a2ui.md

export type UIIntent = {
    intent_id: string;
    source_agent: string;
    timestamp: string;
    ui_intent: 'decision_review' | 'data_preview' | 'status_alert' | 'form_input';
    context: {
        title: string;
        summary: string;
        risk_level: 'low' | 'medium' | 'high' | 'critical';
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        data?: any;
    };
    actions?: {
        id: string;
        label: string;
        style?: 'primary' | 'danger' | 'neutral';
        effect?: string;
    }[];
};

type IntentRendererProps = {
    intent: UIIntent;
    onAction?: (actionId: string, intentId: string) => void;
};

// --- Sub-components ---

const DecisionCard: React.FC<IntentRendererProps> = ({ intent, onAction }) => {
    const { context, actions } = intent;

    // Risk coloring
    const riskColors = {
        low: 'border-l-4 border-green-500',
        medium: 'border-l-4 border-yellow-500',
        high: 'border-l-4 border-orange-500',
        critical: 'border-l-4 border-red-600 bg-red-50'
    };

    return (
        <div className={`bg-white rounded-lg shadow-sm mb-4 p-4 ${riskColors[context.risk_level] || ''}`}>
            <div className="flex justify-between items-start mb-2">
                <div>
                    <span className="text-xs uppercase font-bold text-gray-400 tracking-wider">
                        {intent.source_agent} • {context.risk_level} Risk
                    </span>
                    <h3 className="text-lg font-bold text-gray-800">{context.title}</h3>
                </div>
                <div className="text-xs text-gray-400 font-mono">{new Date(intent.timestamp).toLocaleTimeString()}</div>
            </div>

            <p className="text-gray-600 mb-4">{context.summary}</p>

            {/* Optional Data Payload View */}
            {context.data && (
                <div className="bg-gray-50 rounded p-3 mb-4 text-xs font-mono overflow-x-auto border border-gray-100">
                    <pre>{JSON.stringify(context.data, null, 2)}</pre>
                </div>
            )}

            {/* Actions */}
            {actions && actions.length > 0 && (
                <div className="flex gap-3 justify-end mt-2">
                    {actions.map(action => {
                        let btnClass = "px-4 py-2 rounded text-sm font-medium transition-colors ";
                        if (action.style === 'danger') btnClass += "bg-red-100 text-red-700 hover:bg-red-200 border border-red-200";
                        else if (action.style === 'primary') btnClass += "bg-blue-600 text-white hover:bg-blue-700 shadow-sm";
                        else btnClass += "bg-white border border-gray-300 text-gray-700 hover:bg-gray-50";

                        return (
                            <button
                                key={action.id}
                                className={btnClass}
                                onClick={() => onAction && onAction(action.id, intent.intent_id)}
                            >
                                {action.label}
                            </button>
                        )
                    })}
                </div>
            )}
        </div>
    );
}

// --- Main Switcher ---

export const IntentRenderer: React.FC<IntentRendererProps> = (props) => {
    const { intent } = props;

    switch (intent.ui_intent) {
        case 'decision_review':
            return <DecisionCard {...props} />;

        // Placeholder for others
        case 'status_alert':
            return (
                <div className="p-4 bg-blue-50 text-blue-800 rounded border border-blue-200 mb-4">
                    <strong>{intent.context.title}</strong>: {intent.context.summary}
                </div>
            )

        default:
            return (
                <div className="p-4 bg-gray-100 text-gray-500 rounded border border-gray-200 mb-4 font-mono text-xs">
                    Unknown Intent: {intent.ui_intent}
                    <pre>{JSON.stringify(intent, null, 2)}</pre>
                </div>
            );
    }
};
