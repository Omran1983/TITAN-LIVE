from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor, white, black, lightgrey

def create_reachx_flyer(filename):
    c = canvas.Canvas(filename, pagesize=A4)
    width, height = A4

    # -------------------------------------------------
    # COLORS
    # -------------------------------------------------
    bg_dark      = HexColor("#020617")  # deep navy
    bg_mid       = HexColor("#0F172A")
    bg_purple    = HexColor("#1E1B4B")
    accent_teal  = HexColor("#06B6D4")
    accent_green = HexColor("#22C55E")
    accent_pink  = HexColor("#EC4899")
    accent_orange= HexColor("#F97316")

    soft_green   = HexColor("#DCFCE7")
    soft_blue    = HexColor("#E0F2FE")
    soft_yellow  = HexColor("#FEF3C7")

    text_light   = HexColor("#E5E7EB")
    text_muted   = HexColor("#9CA3AF")
    text_dark    = HexColor("#111827")

    # -------------------------------------------------
    # 0. FULL BACKGROUND (GRADIENT STYLE USING BANDS)
    # -------------------------------------------------
    c.setFillColor(bg_dark)
    c.rect(0, 0, width, height, fill=1, stroke=0)

    # angled-ish bands
    c.setFillColor(bg_purple)
    c.rect(-50, height - 420, width + 100, 220, fill=1, stroke=0)

    c.setFillColor(bg_mid)
    c.rect(0, height - 220, width, 110, fill=1, stroke=0)

    # -------------------------------------------------
    # 1. HEADER HERO: BRAND + BIG CLAIM
    # -------------------------------------------------
    # RX pill
    c.setFillColor(accent_teal)
    c.roundRect(30, height - 120, 60, 32, 10, fill=1, stroke=0)
    c.setFillColor(bg_dark)
    c.setFont("Helvetica-Bold", 18)
    c.drawString(42, height - 98, "RX")

    # Brand name
    c.setFillColor(text_light)
    c.setFont("Helvetica-Bold", 22)
    c.drawString(105, height - 98, "ReachX Operations Cockpit")

    # Tagline
    c.setFont("Helvetica", 10)
    c.setFillColor(text_muted)
    c.drawString(105, height - 114, "For recruitment & manpower agencies who live in Excel but need live ops visibility.")

    # Big headline (very short)
    c.setFont("Helvetica-Bold", 28)
    c.setFillColor(text_light)
    c.drawString(30, height - 155, "ONE LIVE COCKPIT.")
    c.setFont("Helvetica-Bold", 18)
    c.setFillColor(accent_green)
    c.drawString(30, height - 175, "KEEP EXCEL. ADD REAL-TIME CONTROL.")

    # 14-day badge
    c.setFillColor(bg_dark)
    c.roundRect(width - 210, height - 135, 180, 75, 14, fill=1, stroke=0)
    c.setFillColor(accent_green)
    c.setFont("Helvetica-Bold", 14)
    c.drawString(width - 198, height - 103, "14-DAY MONITORED PILOT")
    c.setFillColor(text_muted)
    c.setFont("Helvetica", 9)
    c.drawString(width - 198, height - 118, "Remote setup • You keep data")
    c.drawString(width - 198, height - 130, "We watch DB, sync & UI")

    # -------------------------------------------------
    # 2. BIG VISUAL FLOW: DATA → ENGINE → COCKPIT
    # -------------------------------------------------
    y_center = height - 320

    # LEFT CIRCLE: DATA
    c.setFillColor(bg_dark)
    c.circle(100, y_center, 52, fill=1, stroke=0)
    c.setFillColor(white)
    c.circle(100, y_center, 44, fill=1, stroke=0)

    # grid icon
    c.setStrokeColor(lightgrey)
    c.setLineWidth(1)
    for dx in [88, 96, 104, 112]:
        c.line(dx, y_center - 20, dx, y_center + 20)
    for dy in [y_center - 12, y_center - 4, y_center + 4, y_center + 12]:
        c.line(88, dy, 112, dy)

    c.setFillColor(text_dark)
    c.setFont("Helvetica-Bold", 10)
    c.drawCentredString(100, y_center + 32, "YOUR EXCEL")
    c.setFont("Helvetica", 8)
    c.setFillColor(text_muted)
    c.drawCentredString(100, y_center + 20, "Sheets / CSV")

    # CENTER CIRCLE: RX ENGINE
    c.setFillColor(bg_dark)
    c.circle(width / 2, y_center, 52, fill=1, stroke=0)
    c.setFillColor(accent_teal)
    c.circle(width / 2, y_center, 44, fill=1, stroke=0)

    # little spokes
    cx = width / 2
    cy = y_center
    c.setStrokeColor(bg_dark)
    c.setLineWidth(2)
    for angle in [0, 72, 144, 216, 288]:
        import math
        rad = math.radians(angle)
        c.line(
            cx,
            cy,
            cx + 30 * math.cos(rad),
            cy + 30 * math.sin(rad),
        )

    # RX label
    c.setFillColor(bg_dark)
    c.setFont("Helvetica-Bold", 16)
    c.drawCentredString(cx, cy - 6, "RX")
    c.setFont("Helvetica", 7)
    c.drawCentredString(cx, cy - 20, "ENGINE")

    c.setFont("Helvetica", 8)
    c.setFillColor(text_light)
    c.drawCentredString(cx, y_center + 34, "AUTO SYNC + LOGS")

    # RIGHT CIRCLE: COCKPIT
    c.setFillColor(bg_dark)
    c.circle(width - 100, y_center, 52, fill=1, stroke=0)
    c.setFillColor(white)
    c.circle(width - 100, y_center, 44, fill=1, stroke=0)

    # cockpit bars
    c.setFillColor(accent_green)
    c.rect(width - 120, y_center + 5, 40, 10, fill=1, stroke=0)
    c.setFillColor(accent_teal)
    c.rect(width - 120, y_center - 8, 28, 10, fill=1, stroke=0)
    c.setFillColor(accent_pink)
    c.rect(width - 120, y_center - 21, 18, 10, fill=1, stroke=0)

    c.setFillColor(text_dark)
    c.setFont("Helvetica-Bold", 10)
    c.drawCentredString(width - 100, y_center + 32, "LIVE COCKPIT")
    c.setFont("Helvetica", 8)
    c.setFillColor(text_muted)
    c.drawCentredString(width - 100, y_center + 20, "Browser dashboard")

    # ARROWS BETWEEN CIRCLES
    c.setStrokeColor(accent_green)
    c.setFillColor(accent_green)
    c.setLineWidth(0)

    # left → center arrow
    p1 = c.beginPath()
    p1.moveTo(140, y_center + 8)
    p1.lineTo(210, y_center + 8)
    p1.lineTo(210, y_center + 16)
    p1.lineTo(230, y_center)
    p1.lineTo(210, y_center - 16)
    p1.lineTo(210, y_center - 8)
    p1.lineTo(140, y_center - 8)
    p1.close()
    c.drawPath(p1, fill=1, stroke=0)

    # center → right arrow
    p2 = c.beginPath()
    p2.moveTo(cx + 54, y_center + 8)
    p2.lineTo(width - 140, y_center + 8)
    p2.lineTo(width - 140, y_center + 16)
    p2.lineTo(width - 120, y_center)
    p2.lineTo(width - 140, y_center - 16)
    p2.lineTo(width - 140, y_center - 8)
    p2.lineTo(cx + 54, y_center - 8)
    p2.close()
    c.drawPath(p2, fill=1, stroke=0)

    # -------------------------------------------------
    # 3. 3 COLOR CHIPS: WHAT IT SHOWS
    # -------------------------------------------------
    chip_y = y_center - 80

    # Workers
    c.setFillColor(soft_green)
    c.roundRect(40, chip_y, 150, 32, 10, fill=1, stroke=0)
    c.setFillColor(text_dark)
    c.setFont("Helvetica-Bold", 10)
    c.drawString(52, chip_y + 19, "Workers")
    c.setFont("Helvetica", 8)
    c.setFillColor(text_muted)
    c.drawString(52, chip_y + 9, "Active, on leave, returned")

    # Employers
    c.setFillColor(soft_blue)
    c.roundRect((width / 2) - 75, chip_y, 150, 32, 10, fill=1, stroke=0)
    c.setFillColor(text_dark)
    c.setFont("Helvetica-Bold", 10)
    c.drawString((width / 2) - 65, chip_y + 19, "Employers")
    c.setFont("Helvetica", 8)
    c.setFillColor(text_muted)
    c.drawString((width / 2) - 65, chip_y + 9, "By sector / country / city")

    # Dormitories
    c.setFillColor(soft_yellow)
    c.roundRect(width - 190, chip_y, 150, 32, 10, fill=1, stroke=0)
    c.setFillColor(text_dark)
    c.setFont("Helvetica-Bold", 10)
    c.drawString(width - 178, chip_y + 19, "Dormitories")
    c.setFont("Helvetica", 8)
    c.setFillColor(text_muted)
    c.drawString(width - 178, chip_y + 9, "Capacity & occupancy")

    # -------------------------------------------------
    # 4. 3 VISUAL STEPS (VERTICAL CARDS)
    # -------------------------------------------------
    y_cards = chip_y - 105
    card_w = (width - 80) / 3
    radius = 10

    def step_card(x, num, title, line1, line2, color):
        c.setFillColor(color)
        c.roundRect(x, y_cards, card_w - 10, 80, radius, fill=1, stroke=0)

        c.setFillColor(bg_dark)
        c.setFont("Helvetica-Bold", 18)
        c.drawString(x + 12, y_cards + 53, num)

        c.setFillColor(bg_dark)
        c.setFont("Helvetica-Bold", 11)
        c.drawString(x + 40, y_cards + 55, title)

        c.setFont("Helvetica", 8)
        c.setFillColor(text_dark)
        c.drawString(x + 40, y_cards + 40, line1)
        c.drawString(x + 40, y_cards + 28, line2)

    step_card(
        30,
        "01",
        "Share Data",
        "You send Excel / CSV in our",
        "simple template format.",
        soft_blue,
    )

    step_card(
        40 + card_w,
        "02",
        "We Setup",
        "We deploy your cockpit and",
        "turn on monitoring.",
        soft_green,
    )

    step_card(
        50 + 2 * card_w,
        "03",
        "Run Live",
        "You use it 14 days with real",
        "ops, we watch logs.",
        soft_yellow,
    )

    # section title
    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(text_light)
    c.drawCentredString(width / 2, y_cards + 95, "HOW THE PILOT RUNS")

    # -------------------------------------------------
    # 5. MICRO-TRUST LINE
    # -------------------------------------------------
    c.setFont("Helvetica-Oblique", 8)
    c.setFillColor(text_muted)
    c.drawCentredString(
        width / 2,
        y_cards - 10,
        "We don’t promise perfection – we promise no silent failures. DB, sync & dashboard are all watched."
    )

    # -------------------------------------------------
    # 6. FOOTER CTA BAND WITH YOUR CONTACT
    # -------------------------------------------------
    footer_h = 90
    c.setFillColor(accent_green)
    c.rect(0, 0, width, footer_h, fill=1, stroke=0)

    c.setFillColor(text_dark)
    c.setFont("Helvetica-Bold", 16)
    c.drawString(30, 54, "Ready to see your agency in one cockpit?")

    c.setFont("Helvetica", 10)
    c.drawString(30, 36, "Limited 14-day pilots • Remote setup • You keep full control of your data")

    # Your contact (updated)
    c.setFont("Helvetica-Bold", 10)
    c.drawString(30, 20, "Contact: Omran Ahmad  |  WhatsApp: +230 5788 7132  |  Email: deals@aogrl.com")

    # QR placeholder
    c.setFillColor(white)
    c.rect(width - 105, 12, 75, 66, fill=1, stroke=0)
    c.setFillColor(text_dark)
    c.setFont("Helvetica", 8)
    c.drawCentredString(width - 67, 48, "PLACE")
    c.drawCentredString(width - 67, 38, "QR CODE")
    c.drawCentredString(width - 67, 28, "FOR DEMO LINK")

    c.save()


# Generate PDF
create_reachx_flyer("ReachX_Pilot_Flyer.pdf")
