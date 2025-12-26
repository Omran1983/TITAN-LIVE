def build_locked_prompt(*, industry: str, main_text: str, brand_color_hex: str, platform: str) -> str:
    # Lane 1: structure is immutable. Only variables injected.
    # Keep it short, concrete, and constraint-heavy.
    return (
        f"A professional social media graphic for {industry}. "
        f"Center focus: the text \"{main_text}\" clearly displayed in modern sans-serif. "
        f"Background: clean solid or subtle gradient using brand color {brand_color_hex}. "
        f"Style: minimalist, modern, high contrast. "
        f"Composition: centered text, generous safe margins, uncluttered edges. "
        f"Output must be immediately postable on {platform}. "
        f"Negative: distortion, unreadable text, blur, clutter, low contrast, artifacts."
    )
