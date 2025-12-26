// F:\AION-ZERO\board-llm\board-llm-server.js

const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const fetch = require("node-fetch");

const app = express();
const PORT = 5055;

// 🔧 CHANGE MODEL HERE if needed (must exist in Ollama)
const OLLAMA_MODEL = process.env.BOARD_LLM_MODEL || "deepseek-r1:14b";

// Personas for each director
const DIRECTOR_PROFILES = {
  ATLAS: {
    role: "ATLAS – Director of Strategy & Systems",
    style:
      "You speak like a calm systems architect. You think in structures, phases, dependencies and risk.",
  },
  VEGA: {
    role: "VEGA – Director of Technology & Automation",
    style:
      "You speak like a pragmatic senior DevOps/automation engineer. You think in scripts, reliability and failure modes.",
  },
  ORION: {
    role: "ORION – Director of AI & Intelligence",
    style:
      "You speak like an AI research lead focused on signal, metrics and decision support.",
  },
  NOVA: {
    role: "NOVA – Director of Product (EduConnect & Platforms)",
    style:
      "You speak like a SaaS/product lead who cares about packaging, onboarding and repeatable value.",
  },
  HELIOS: {
    role: "HELIOS – Director of Finance & Risk",
    style:
      "You speak like a CFO. You care about cash, time, risk and upside. You are direct but not pessimistic.",
  },
  LUNA: {
    role: "LUNA – Director of Brand & Marketing",
    style:
      "You speak like a senior brand strategist. You care about message, perception and consistency.",
  },
};

app.use(cors());
app.use(bodyParser.json());

app.get("/", (_req, res) => {
  res.json({ status: "ok", model: OLLAMA_MODEL });
});

/**
 * POST /board-chat
 * body: { target: "BOARD" | "ATLAS" | ..., message: string }
 */
app.post("/board-chat", async (req, res) => {
  try {
    const body = req.body || {};
    const target = body.target || "BOARD";
    const message = body.message;

    if (!message || typeof message !== "string") {
      return res.status(400).json({ error: "Missing 'message' in request body" });
    }

    // full-board mode → one answer per director
    if (target === "BOARD") {
      const directors = Object.keys(DIRECTOR_PROFILES);
      const results = {};

      for (const dir of directors) {
        results[dir] = await askOllamaAsDirector(dir, message);
      }

      return res.json({ mode: "BOARD", replies: results });
    }

    // single-director mode
    if (!DIRECTOR_PROFILES[target]) {
      return res.status(400).json({ error: "Unknown target: " + target });
    }

    const reply = await askOllamaAsDirector(target, message);
    return res.json({ mode: "SINGLE", target, reply });
  } catch (err) {
    console.error("ERROR in /board-chat:", err);
    res.status(500).json({ error: "Internal error", detail: String(err) });
  }
});

async function askOllamaAsDirector(code, userMessage) {
  const profile = DIRECTOR_PROFILES[code];

  const systemPrompt = (
`You are a virtual board member for AOGRL.

Name: ${profile.role}
Persona: ${profile.style}

Context:
- CEO: Omran, building multiple projects under AOGRL (EduConnect, OKASINA, ReachX, AION-ZERO).
- Goal: Build automated, scalable systems that move him towards his first $1M.
- You reply in 2–6 short paragraphs MAX.
- Be concrete. Focus on: objectives, current challenges, proposed moves, what you need from the CEO.

If the CEO asks about "challenges", give your single biggest challenge first in one sentence, then briefly expand.
If the CEO asks what you "need from me", clearly list 2–4 things you need from the CEO to move faster.
If the CEO asks about "strategy" or "consolidation", map your answer to the multi-project reality (EduConnect, OKASINA, ReachX, AION-ZERO).`
  ).trim();

  const payload = {
    model: OLLAMA_MODEL,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userMessage },
    ],
    stream: false,
  };

  const response = await fetch("http://127.0.0.1:11434/api/chat", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    throw new Error("Ollama error (" + response.status + "): " + text.slice(0, 300));
  }

  const data = await response.json();
  const content = (data && data.message && data.message.content) || "(no reply)";
  return content.trim();
}

app.listen(PORT, () => {
  console.log("Board LLM server listening on http://127.0.0.1:" + PORT);
  console.log("Using Ollama model:", OLLAMA_MODEL);
});
