# Titan A2UI Architecture (Agent-to-UI)

**Core Principle:** Agents emit structured **Intents** (JSON), not UI. The Control Center renders them deterministically.

## 1. The Contract (UI Intent Schema)

Every agent decision requiring human interaction must follow this JSON structure:

```json
{
  "intent_id": "uuid-v4",
  "source_agent": "titan_risk_officer",
  "timestamp": "ISO8601",
  "ui_intent": "decision_review",  // The "Type" of UI to render
  "context": {
      "title": "Invoice Approval",
      "summary": "Invoice #902 exceeds auto-approve limit ($500).",
      "risk_level": "medium",  // low, medium, high, critical
      "data": { ... }          // Arbitrary payload for the renderer
  },
  "actions": [
      { 
          "id": "approve", 
          "label": "Approve", 
          "style": "primary",
          "effect": "execute_payment" 
      },
      { 
          "id": "reject", 
          "label": "Reject", 
          "style": "danger",
          "effect": "cancel_process" 
      }
  ]
}
```

## 2. Intent Types (Standard Library)

| Intent Type | Description | Rendered Component |
| :--- | :--- | :--- |
| `decision_review` | Binary or Multi-choice decision. | `DecisionCard` |
| `data_preview` | Show a table or JSON object for verification. | `DataGrid` |
| `status_alert` | Non-blocking notification or warning. | `AlertBanner` |
| `form_input` | Request specific parameters from user. | `DynamicForm` |

## 3. Database Schema (`az_ui_intents`)

We prefer to log *every* intent for audit trails.

```sql
CREATE TABLE az_ui_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id TEXT NOT NULL,
    intent_type TEXT NOT NULL,
    risk_level TEXT DEFAULT 'low',
    payload JSONB NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, approved, rejected, expired
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolved_by TEXT
);
```

## 4. Implementation Steps
1.  **Refactor Agents**: Agents typically print text. They must now return `Intent` objects.
2.  **Frontend Renderer**: A React component `<IntentRenderer intent={json} />` that switches on `intent_type`.
3.  **Governance**: High-risk intents trigger "L4 Authority" lockouts in the UI.
