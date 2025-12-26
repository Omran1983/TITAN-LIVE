from PIL import Image, ImageDraw, ImageFont
import io
import re
import colorsys

class LocalTemplateProvider:
    """
    Professional layout engine with 5 design archetypes.
    Zero cost, deterministic, validator-safe.
    """
    
    LAYOUTS = ["hero", "split", "badge", "diagonal", "card"]
    
    def __init__(self, *, api_key: str = "", model: str = ""):
        pass

    def generate_png(self, *, prompt: str, width: int, height: int) -> bytes:
        # Extract brand color and text from prompt
        brand_color = self._extract_color(prompt)
        text_content = self._extract_text(prompt)
        
        # Choose layout based on aspect ratio
        layout = self._choose_layout(width, height)
        
        # Generate image
        if layout == "hero":
            img = self._layout_hero(width, height, brand_color, text_content)
        elif layout == "split":
            img = self._layout_split(width, height, brand_color, text_content)
        elif layout == "badge":
            img = self._layout_badge(width, height, brand_color, text_content)
        elif layout == "diagonal":
            img = self._layout_diagonal(width, height, brand_color, text_content)
        else:  # card
            img = self._layout_card(width, height, brand_color, text_content)
        
        buf = io.BytesIO()
        img.save(buf, format='PNG')
        return buf.getvalue()
    
    def _extract_color(self, prompt: str) -> str:
        match = re.search(r'brand color (#\w+)', prompt)
        return match.group(1) if match else "#2C3E50"
    
    def _extract_text(self, prompt: str) -> str:
        match = re.search(r'text "([^"]+)"', prompt)
        return match.group(1) if match else "SAMPLE TEXT"
    
    def _choose_layout(self, width: int, height: int) -> str:
        ratio = width / height
        if ratio > 1.5:  # Wide (e.g., FB_FEED)
            return "split"
        elif ratio < 0.7:  # Tall (e.g., IG_STORY)
            return "hero"
        else:  # Square-ish (e.g., IG_FEED, LINKEDIN)
            return "badge"
    
    def _get_font(self, size: int):
        """Try to load best available font"""
        font_paths = [
            "C:\\Windows\\Fonts\\segoeui.ttf",  # Segoe UI (Windows)
            "C:\\Windows\\Fonts\\arial.ttf",     # Arial (Windows)
            "/System/Library/Fonts/Helvetica.ttc",  # Helvetica (Mac)
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",  # Linux
        ]
        
        for path in font_paths:
            try:
                return ImageFont.truetype(path, size)
            except:
                continue
        
        return ImageFont.load_default()
    
    def _get_bold_font(self, size: int):
        """Try to load bold font"""
        font_paths = [
            "C:\\Windows\\Fonts\\segoeuib.ttf",  # Segoe UI Bold
            "C:\\Windows\\Fonts\\arialbd.ttf",   # Arial Bold
        ]
        
        for path in font_paths:
            try:
                return ImageFont.truetype(path, size)
            except:
                continue
        
        return self._get_font(size)
    
    def _add_noise_texture(self, img: Image, opacity: int = 15) -> Image:
        """Add subtle noise texture for depth"""
        import random
        
        width, height = img.size
        noise = Image.new('RGBA', (width, height), (0, 0, 0, 0))
        pixels = noise.load()
        
        for y in range(0, height, 2):
            for x in range(0, width, 2):
                if random.random() > 0.5:
                    pixels[x, y] = (255, 255, 255, opacity)
        
        img = img.convert('RGBA')
        img = Image.alpha_composite(img, noise)
        return img.convert('RGB')
    
    def _add_dot_pattern(self, draw, width: int, height: int, color: tuple, spacing: int = 40):
        """Add subtle dot pattern"""
        for y in range(0, height, spacing):
            for x in range(0, width, spacing):
                draw.ellipse([x-2, y-2, x+2, y+2], fill=color)
    
    def _hex_to_rgb(self, hex_color: str) -> tuple:
        hex_color = hex_color.lstrip('#')
        return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    
    def _create_gradient(self, width: int, height: int, color1: tuple, color2: tuple) -> Image:
        base = Image.new('RGB', (width, height), color1)
        top = Image.new('RGB', (width, height), color2)
        mask = Image.new('L', (width, height))
        mask_data = []
        for y in range(height):
            for x in range(width):
                mask_data.append(int(255 * (y / height)))
        mask.putdata(mask_data)
        base.paste(top, (0, 0), mask)
        return base
    
    def _darken_color(self, rgb: tuple, factor: float = 0.6) -> tuple:
        h, l, s = colorsys.rgb_to_hls(rgb[0]/255, rgb[1]/255, rgb[2]/255)
        l = max(0, l * factor)
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        return (int(r*255), int(g*255), int(b*255))
    
    def _lighten_color(self, rgb: tuple, factor: float = 1.3) -> tuple:
        h, l, s = colorsys.rgb_to_hls(rgb[0]/255, rgb[1]/255, rgb[2]/255)
        l = min(1, l * factor)
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        return (int(r*255), int(g*255), int(b*255))
    
    # LAYOUT 1: HERO BANNER
    def _layout_hero(self, width: int, height: int, brand_color: str, text: str) -> Image:
        rgb = self._hex_to_rgb(brand_color)
        dark = self._darken_color(rgb, 0.7)
        
        # Gradient background
        img = self._create_gradient(width, height, rgb, dark)
        draw = ImageDraw.Draw(img)
        
        # Add subtle dot pattern
        dot_color = self._lighten_color(rgb, 1.1)
        self._add_dot_pattern(draw, width, height, (*dot_color, 30), spacing=60)
        
        # Accent bar at top
        bar_height = int(height * 0.08)
        draw.rectangle([0, 0, width, bar_height], fill=self._lighten_color(rgb, 1.2))
        
        # Accent line below bar
        draw.rectangle([0, bar_height, width, bar_height + 3], fill=(255, 255, 255, 200))
        
        # Main text with bold font
        font_size = int(height / 12)
        font = self._get_bold_font(font_size)
        
        # Split text into lines if needed
        words = text.split()
        if len(words) > 3:
            line1 = ' '.join(words[:len(words)//2])
            line2 = ' '.join(words[len(words)//2:])
            
            y1 = height/2 - font_size
            y2 = height/2 + font_size/4
            
            # Shadow (larger, softer)
            for offset in [(4, 4), (3, 3), (2, 2)]:
                draw.text((width/2 + offset[0], y1 + offset[1]), line1, font=font, fill=(0,0,0,40), anchor="mm")
                draw.text((width/2 + offset[0], y2 + offset[1]), line2, font=font, fill=(0,0,0,40), anchor="mm")
            
            # Text
            draw.text((width/2, y1), line1, font=font, fill=(255,255,255), anchor="mm")
            draw.text((width/2, y2), line2, font=font, fill=(255,255,255), anchor="mm")
        else:
            # Shadow (layered for depth)
            for offset in [(5, 5), (4, 4), (3, 3)]:
                draw.text((width/2 + offset[0], height/2 + offset[1]), text, font=font, fill=(0,0,0,40), anchor="mm")
            # Text
            draw.text((width/2, height/2), text, font=font, fill=(255,255,255), anchor="mm")
        
        # Add noise texture
        img = self._add_noise_texture(img, opacity=12)
        
        return img
    
    # LAYOUT 2: SPLIT PANEL
    def _layout_split(self, width: int, height: int, brand_color: str, text: str) -> Image:
        rgb = self._hex_to_rgb(brand_color)
        light = self._lighten_color(rgb, 1.4)
        
        img = Image.new('RGB', (width, height), light)
        draw = ImageDraw.Draw(img)
        
        # Right panel (brand color)
        split = int(width * 0.55)
        draw.rectangle([split, 0, width, height], fill=rgb)
        
        # Diagonal accent
        points = [(split-50, 0), (split+50, 0), (split, height), (split-100, height)]
        draw.polygon(points, fill=self._darken_color(rgb, 0.8))
        
        # Text on left
        font_size = int(height / 10)
        font = self._get_font(font_size)
        
        text_x = split / 2
        # Shadow
        draw.text((text_x + 3, height/2 + 3), text, font=font, fill=(0,0,0,64), anchor="mm")
        # Text
        draw.text((text_x, height/2), text, font=font, fill=self._darken_color(rgb, 0.3), anchor="mm")
        
        return img
    
    # LAYOUT 3: BADGE STYLE
    def _layout_badge(self, width: int, height: int, brand_color: str, text: str) -> Image:
        rgb = self._hex_to_rgb(brand_color)
        dark = self._darken_color(rgb, 0.5)
        
        # Gradient background
        img = self._create_gradient(width, height, rgb, dark)
        draw = ImageDraw.Draw(img)
        
        # Circle badge
        badge_size = min(width, height) * 0.7
        badge_x = width / 2
        badge_y = height / 2
        
        # Outer circle (shadow)
        draw.ellipse([
            badge_x - badge_size/2 + 5,
            badge_y - badge_size/2 + 5,
            badge_x + badge_size/2 + 5,
            badge_y + badge_size/2 + 5
        ], fill=(0, 0, 0, 64))
        
        # Inner circle
        draw.ellipse([
            badge_x - badge_size/2,
            badge_y - badge_size/2,
            badge_x + badge_size/2,
            badge_y + badge_size/2
        ], fill=self._lighten_color(rgb, 1.3), outline=(255,255,255), width=int(badge_size*0.02))
        
        # Text with word wrapping
        words = text.split()
        max_chars_per_line = 12  # Adjust based on circle size
        
        lines = []
        current_line = []
        for word in words:
            test_line = ' '.join(current_line + [word])
            if len(test_line) <= max_chars_per_line:
                current_line.append(word)
            else:
                if current_line:
                    lines.append(' '.join(current_line))
                current_line = [word]
        if current_line:
            lines.append(' '.join(current_line))
        
        # Dynamic font size based on number of lines and text length
        if len(lines) > 2:
            font_size = int(badge_size / 14)
        elif len(lines) == 2:
            font_size = int(badge_size / 11)
        else:
            font_size = int(badge_size / 9)
        
        font = self._get_font(font_size)
        
        # Calculate total text height
        line_height = font_size * 1.3
        total_height = len(lines) * line_height
        start_y = badge_y - (total_height / 2) + (line_height / 2)
        
        # Draw each line
        for i, line in enumerate(lines):
            y = start_y + (i * line_height)
            draw.text((badge_x, y), line, font=font, fill=dark, anchor="mm")
        
        return img
    
    # LAYOUT 4: DIAGONAL ACCENT
    def _layout_diagonal(self, width: int, height: int, brand_color: str, text: str) -> Image:
        rgb = self._hex_to_rgb(brand_color)
        
        img = Image.new('RGB', (width, height), (255, 255, 255))
        draw = ImageDraw.Draw(img)
        
        # Diagonal band
        points = [
            (0, height * 0.3),
            (width, height * 0.1),
            (width, height * 0.5),
            (0, height * 0.7)
        ]
        draw.polygon(points, fill=rgb)
        
        # Accent line
        accent_points = [
            (0, height * 0.72),
            (width, height * 0.52),
            (width, height * 0.56),
            (0, height * 0.76)
        ]
        draw.polygon(accent_points, fill=self._darken_color(rgb, 0.7))
        
        # Text
        font_size = int(height / 9)
        font = self._get_font(font_size)
        
        # Shadow
        draw.text((width/2 + 3, height/2 + 3), text, font=font, fill=(0,0,0,64), anchor="mm")
        # Text
        draw.text((width/2, height/2), text, font=font, fill=(255,255,255), anchor="mm")
        
        return img
    
    # LAYOUT 5: CARD STACK
    def _layout_card(self, width: int, height: int, brand_color: str, text: str) -> Image:
        rgb = self._hex_to_rgb(brand_color)
        light = self._lighten_color(rgb, 1.5)
        
        img = Image.new('RGB', (width, height), light)
        draw = ImageDraw.Draw(img)
        
        # Card dimensions
        card_w = width * 0.85
        card_h = height * 0.7
        card_x = (width - card_w) / 2
        card_y = (height - card_h) / 2
        
        # Shadow cards (depth effect)
        for i in range(2, 0, -1):
            offset = i * 8
            draw.rectangle([
                card_x + offset,
                card_y + offset,
                card_x + card_w + offset,
                card_y + card_h + offset
            ], fill=(0, 0, 0, 32))
        
        # Main card
        draw.rectangle([
            card_x,
            card_y,
            card_x + card_w,
            card_y + card_h
        ], fill=rgb, outline=self._darken_color(rgb, 0.6), width=3)
        
        # Top accent bar
        bar_h = card_h * 0.15
        draw.rectangle([
            card_x,
            card_y,
            card_x + card_w,
            card_y + bar_h
        ], fill=self._darken_color(rgb, 0.7))
        
        # Text
        font_size = int(card_h / 8)
        font = self._get_font(font_size)
        
        text_y = card_y + card_h/2
        draw.text((width/2, text_y), text, font=font, fill=(255,255,255), anchor="mm")
        
        return img
