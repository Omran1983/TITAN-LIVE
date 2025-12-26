from titan_social.types import DispatchResult, Platform


def dispatch_platform(platform: Platform) -> DispatchResult:
    # Platform → (aspect ratio, width, height)
    mapping = {
        "IG_FEED":   ("4:5", 1080, 1350),
        "IG_STORY":  ("9:16", 1080, 1920),
        "LINKEDIN":  ("1:1", 1080, 1080),
        "FB_FEED":   ("1:1", 1080, 1080),
        "X":         ("16:9", 1200, 675),
    }
    if platform not in mapping:
        raise ValueError(f"Unsupported platform: {platform}")

    ar, w, h = mapping[platform]
    return DispatchResult(platform=platform, aspect_ratio=ar, width=w, height=h)
