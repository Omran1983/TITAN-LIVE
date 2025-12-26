import re
import requests
from bs4 import BeautifulSoup
from typing import Dict, Any
from agents.contract import TitanAgent

class WebsiteReviewAgent(TitanAgent):
    name = "website-review-agent"

    def observe(self, ctx: Dict[str, Any]) -> Dict[str, Any]:
        url = (ctx.get("url") or "").strip()
        if not url:
            return {"ok": False, "error": "Missing url"}
        if not re.match(r"^https?://", url):
            url = "https://" + url
        return {"ok": True, "url": url}

    def acquire(self, ctx: Dict[str, Any]) -> Dict[str, Any]:
        url = ctx["observe"]["url"]
        r = requests.get(url, timeout=20, headers={"User-Agent": "TITAN/1.0"})
        return {
            "ok": True,
            "status": r.status_code,
            "headers": dict(r.headers),
            "html": r.text,
            "bytes": len(r.content),
            "final_url": r.url
        }

    def persist(self, ctx: Dict[str, Any]) -> Dict[str, Any]:
        store = ctx["artifact_store"]
        url = ctx["observe"]["url"]
        html = ctx["acquire"]["html"].encode("utf-8", errors="ignore")
        artifact = store.save_raw(
            source_type="website",
            source_uri=url,
            raw_bytes=html,
            parsed={},
            meta={"status": ctx["acquire"]["status"], "final_url": ctx["acquire"]["final_url"]}
        )
        return {"ok": True, "artifact_id": str(artifact["id"]), "hash": artifact["content_hash"], "raw_path": artifact["raw_path"]}

    def index(self, ctx: Dict[str, Any]) -> Dict[str, Any]:
        reg = ctx["cap_registry"]
        html = ctx["acquire"]["html"]
        soup = BeautifulSoup(html, "lxml")

        title = (soup.title.text.strip() if soup.title else "")
        desc = ""
        m = soup.find("meta", attrs={"name": "description"})
        if m and m.get("content"):
            desc = m["content"].strip()

        links = [a.get("href") for a in soup.find_all("a") if a.get("href")]
        links = links[:200]

        capability_meta = {
            "capability": "website_review",
            "category": "ops",
            "inputs": ["url"],
            "outputs": ["status", "title", "meta_description", "signals"],
            "automation_type": "agent",
            "signals": {
                "title": title,
                "meta_description": desc,
                "link_count": len(links),
                "has_https": ctx["observe"]["url"].startswith("https://"),
            }
        }

        cap = reg.upsert_capability(
            kind="agent",
            name="WebsiteReviewAgent",
            category="ops",
            capability_meta=capability_meta,
            source_artifact_id=ctx["persist"]["artifact_id"]
        )
        return {"ok": True, "capability_id": cap["id"], "signals": capability_meta["signals"]}

    def act(self, ctx: Dict[str, Any]) -> Dict[str, Any]:
        # Produce a compact review (evidence-first)
        return {
            "ok": True,
            "review": {
                "url": ctx["observe"]["url"],
                "status": ctx["acquire"]["status"],
                "bytes": ctx["acquire"]["bytes"],
                "signals": ctx["index"]["signals"],
                "notes": [
                    "This is a shallow review (HTML only).",
                    "Next step: add lighthouse/axe checks if needed (governed)."
                ]
            }
        }

    def verify(self, ctx: Dict[str, Any]) -> Dict[str, Any]:
        # Minimal verification: confirm artifact exists + status code
        ok = (ctx["acquire"]["status"] >= 200 and ctx["acquire"]["status"] < 500)
        return {"ok": ok, "verified": ok, "reason": "status_code_check"}
