# 📟 CITADEL DASHBOARD V2: TITAN SPECIFICATION
**Module**: UI/UX Upgrade
**Target**: `citadel/static/index.html`

---

## 1. NEW WIDGETS (The "Why")
The current dashboard assumes "Chat" is the main interface.
For Enterprise, we need **Status** to be the main interface.

### A. The Mesh Monitor
*   **Visual**: Network Graph (Nodes = Agents, Lines = Traffic).
*   **Data Source**: `az_mesh_agents` (Supabase).
*   **Interaction**: Click a node to see its Latency/Error Rate.
*   **State**: Green (Online), Yellow (Slow), Red (Circuit Open).

### B. The Memory Stream
*   **Visual**: Scrolling feed of "Learned Facts".
*   **Example**: `[14:02] Learned: User prefers dark mode.`
*   **Action**: "Forget" button next to each item (Privacy Control).

### C. The Autonomy Slider
*   **Visual**: A physics-based slider (Level 0 - 3).
*   **Function**: Sets the global `HITL` (Human-in-the-Loop) variable in `server.py`.
    *   **Level 0**: Read Only.
    *   **Level 1**: Suggest.
    *   **Level 2**: Act (Low Risk).
    *   **Level 3**: God Mode.

### D. The Vision Feed (Live)
*   **Visual**: A Picture-in-Picture window showing `latest_vision.jpg`.
*   **Overlay**: Bounding boxes around detected errors (drawn by Gemini Vision).

---

## 2. LAYOUT GRID (The "How")

```
+-------------------------------------------------------+
|  HEADER: [System Status: ONLINE] [CPU: 12%] [Panic]   |
+---------------------+---------------------------------+
|  LEFT PANEL (20%)   |  CENTER (60%)                   |
|  [Navigation]       |  [Vision Feed (Top)]            |
|  - Dashboard        |  [Chat / Logic Log (Middle)]    |
|  - Mesh Map         |  [Agent Actions (Bottom)]       |
|  - Memory Bank      |                                 |
|  - Settings         |                                 |
+---------------------+---------------------------------+
|  RIGHT PANEL (20%)                                    |
|  [Autonomy Slider]                                    |
|  [Recent Alerts]                                      |
|  [Active Workers]                                     |
+-------------------------------------------------------+
```

---

## 3. IMPLEMENTATION PATH
1.  **Backend**: Add `/api/mesh/status` and `/api/memory/recent` endpoints to `server.py`.
2.  **Frontend**: Use `Recharts` or `D3.js` for the Mesh Graph.
3.  **Realtime**: Poll every 2s (or switch to WebSockets).
