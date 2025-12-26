from dataclasses import dataclass
from typing import Literal

Platform = Literal["IG_FEED", "IG_STORY", "LINKEDIN", "FB_FEED", "X"]

@dataclass(frozen=True)
class GraphicRequest:
    brand_name: str
    industry: str
    brand_color_hex: str
    platform: Platform
    main_text: str


@dataclass(frozen=True)
class DispatchResult:
    platform: Platform
    aspect_ratio: str
    width: int
    height: int


@dataclass(frozen=True)
class ValidationVerdict:
    status: Literal["PASS", "FAIL"]
    reason: str
