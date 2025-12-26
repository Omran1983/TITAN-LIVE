from abc import ABC, abstractmethod
from typing import Dict, Any

class TitanAgent(ABC):
    """
    Every agent must implement the closed loop:
    observe -> acquire -> persist -> index -> act -> verify
    Each stage must return structured dict outputs (evidence-first).
    """

    name: str = "unnamed-agent"

    @abstractmethod
    def observe(self, ctx: Dict[str, Any]) -> Dict[str, Any]: ...

    @abstractmethod
    def acquire(self, ctx: Dict[str, Any]) -> Dict[str, Any]: ...

    @abstractmethod
    def persist(self, ctx: Dict[str, Any]) -> Dict[str, Any]: ...

    @abstractmethod
    def index(self, ctx: Dict[str, Any]) -> Dict[str, Any]: ...

    @abstractmethod
    def act(self, ctx: Dict[str, Any]) -> Dict[str, Any]: ...

    @abstractmethod
    def verify(self, ctx: Dict[str, Any]) -> Dict[str, Any]: ...

    def run(self, ctx: Dict[str, Any]) -> Dict[str, Any]:
        o = self.observe(ctx)
        ctx.update({"observe": o})

        a = self.acquire(ctx)
        ctx.update({"acquire": a})

        p = self.persist(ctx)
        ctx.update({"persist": p})

        i = self.index(ctx)
        ctx.update({"index": i})

        act = self.act(ctx)
        ctx.update({"act": act})

        v = self.verify(ctx)
        ctx.update({"verify": v})

        return {
            "ok": True,
            "agent": self.name,
            "observe": o,
            "acquire": a,
            "persist": p,
            "index": i,
            "act": act,
            "verify": v,
        }
