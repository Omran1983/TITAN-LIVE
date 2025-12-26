"""
TITAN HR - Compliance PDF Report Generator
Generates inspector-ready compliance reports from normalized run data.

Input contract (data dict):
{
  "compliance_score": int,
  "total_employees": int,
  "salary_violations": [ { employee, rule, clause, actual, expected, fix, role, tenure } ],
  "leave_violations":  [ ... ],
  "other_violations":  [ ... ],
  "warnings": [ { rule, message, citation } ],
  "notes": [str... optional]
}
"""

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from datetime import datetime
import os


class CompliancePDFGenerator:
    def __init__(self, output_dir: str):
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        self.styles = getSampleStyleSheet()
        self._setup_custom_styles()

    def _setup_custom_styles(self):
        # Avoid clashing with default style names
        self.styles.add(ParagraphStyle(
            name="TITAN_H1",
            parent=self.styles["Heading1"],
            fontSize=18,
            spaceAfter=16,
            textColor=colors.HexColor("#2c3e50")
        ))

        self.styles.add(ParagraphStyle(
            name="TITAN_H2",
            parent=self.styles["Heading2"],
            fontSize=13,
            spaceBefore=14,
            spaceAfter=8,
            textColor=colors.HexColor("#34495e")
        ))

        self.styles.add(ParagraphStyle(
            name="TITAN_SMALL",
            parent=self.styles["Normal"],
            fontSize=8,
            leading=10
        ))

        self.styles.add(ParagraphStyle(
            name="TITAN_BADGE_PASS",
            parent=self.styles["Normal"],
            textColor=colors.green,
            fontSize=12,
            fontName="Helvetica-Bold"
        ))

        self.styles.add(ParagraphStyle(
            name="TITAN_BADGE_FAIL",
            parent=self.styles["Normal"],
            textColor=colors.red,
            fontSize=12,
            fontName="Helvetica-Bold"
        ))

    def generate_report(self, client_name: str, month: str, data: dict, filename: str = None) -> str:
        if not filename:
            filename = f"HR_Compliance_Report_{client_name.replace(' ', '_')}_{month}.pdf"

        filepath = os.path.join(self.output_dir, filename)

        # margins (points): ~0.55 inch
        doc = SimpleDocTemplate(
            filepath,
            pagesize=A4,
            leftMargin=40,
            rightMargin=40,
            topMargin=40,
            bottomMargin=40
        )

        story = []

        # Logo (optional)
        logo_path = "F:/AION-ZERO/sales/logo_aogrl.png"
        if os.path.exists(logo_path):
            try:
                img = Image(logo_path, width=2 * inch, height=0.75 * inch)
                img.hAlign = "LEFT"
                story.append(img)
                story.append(Spacer(1, 10))
            except Exception:
                pass

        story.append(Paragraph("HR COMPLIANCE AUDIT REPORT", self.styles["TITAN_H1"]))

        report_id = f"TITAN-{month}-{abs(hash(client_name)) % 10000:04d}"
        meta_data = [
            ["Client Name:", client_name],
            ["Audit Period:", month],
            ["Report Date:", datetime.now().strftime("%Y-%m-%d")],
            ["Report ID:", report_id],
        ]

        t = Table(meta_data, colWidths=[1.4 * inch, 4.8 * inch])
        t.setStyle(TableStyle([
            ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
            ("TEXTCOLOR", (0, 0), (-1, -1), colors.HexColor("#2c3e50")),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ]))
        story.append(t)
        story.append(Spacer(1, 18))

        # Executive Summary
        story.append(Paragraph("1. Executive Summary", self.styles["TITAN_H2"]))

        score = int(data.get("compliance_score", 0) or 0)
        total_employees = int(data.get("total_employees", 0) or 0)

        status = "COMPLIANT" if score >= 95 else "NON-COMPLIANT"
        badge_style = "TITAN_BADGE_PASS" if status == "COMPLIANT" else "TITAN_BADGE_FAIL"

        story.append(Paragraph(f"Overall Status: {status}", self.styles[badge_style]))
        story.append(Paragraph(f"Compliance Score: {score}%", self.styles["Normal"]))
        story.append(Paragraph(f"Employees Reviewed: {total_employees}", self.styles["Normal"]))
        story.append(Spacer(1, 10))

        violations_count = (
            len(data.get("salary_violations") or [])
            + len(data.get("leave_violations") or [])
            + len(data.get("other_violations") or [])
        )

        summary_text = (
            f"This audit reviewed {total_employees} employee records against PRB salary rules, "
            f"Workers’ Rights Act indicators, and statutory contribution indicators based on the data supplied. "
        )
        if violations_count > 0:
            summary_text += f"Violations detected: {violations_count}. Immediate remediation is recommended."
        else:
            summary_text += "No violations were detected in the supplied dataset."

        story.append(Paragraph(summary_text, self.styles["Normal"]))
        story.append(Spacer(1, 16))

        # Sections
        if data.get("salary_violations"):
            story.append(Paragraph("2. Salary & Compensation Violations (PRB)", self.styles["TITAN_H2"]))
            story.append(Paragraph("Issues related to basic salary floors and increment policy triggers.", self.styles["Normal"]))
            story.append(Spacer(1, 6))
            self._add_violation_table(story, data["salary_violations"])
            story.append(Spacer(1, 14))

        if data.get("leave_violations"):
            story.append(Paragraph("3. Leave & Attendance Violations (Workers’ Rights)", self.styles["TITAN_H2"]))
            story.append(Paragraph("Issues related to annual leave entitlement or utilization thresholds.", self.styles["Normal"]))
            story.append(Spacer(1, 6))
            self._add_violation_table(story, data["leave_violations"])
            story.append(Spacer(1, 14))

        if data.get("other_violations"):
            story.append(Paragraph("4. Other Compliance Issues", self.styles["TITAN_H2"]))
            story.append(Spacer(1, 6))
            self._add_violation_table(story, data["other_violations"])
            story.append(Spacer(1, 14))

        # Warnings / Recommendations
        warnings = data.get("warnings") or []
        if warnings:
            story.append(Paragraph("5. Recommendations & Warnings", self.styles["TITAN_H2"]))
            for w in warnings:
                rule = w.get("rule", "Recommendation")
                msg = w.get("message", "")
                cite = w.get("citation", "")
                line = f"• <b>{rule}</b>: {msg}"
                if cite:
                    line += f" (Ref: {cite})"
                story.append(Paragraph(line, self.styles["Normal"]))
                story.append(Spacer(1, 4))
            story.append(Spacer(1, 10))

        # Methodology & Disclaimer
        story.append(Spacer(1, 18))
        story.append(Paragraph("Methodology & Disclaimer", self.styles["Heading3"]))
        disclaimer = (
            "This report is generated from the data provided by the client. TITAN checks rules against "
            "configured compliance policies and extracted official references where available. "
            "This report does not constitute legal advice. For disputes or edge cases, consult a qualified professional."
        )
        story.append(Paragraph(disclaimer, self.styles["Italic"]))
        story.append(Spacer(1, 12))

        # Footer
        story.append(Paragraph("Generated by TITAN HR Compliance Service", self.styles["Normal"]))
        footer_text = (
            "<b>A-One Global Resourcing Ltd</b><br/>"
            "BRN: C22185206 | TAN: 28006142<br/>"
            "Jurisdiction: Republic of Mauritius<br/>"
            "📧 compliance@aogrl.com | 📞 +230 57 88 7132"
        )
        story.append(Paragraph(footer_text, self.styles["Normal"]))

        doc.build(story)
        return filepath

    def _add_violation_table(self, story, violations):
        """
        Violations rows accepted even if fields missing:
        employee, role, tenure, clause, rule, actual, expected, fix
        """
        headers = ["Employee", "Role", "Tenure", "Ref", "Rule", "Actual", "Limit", "Action"]
        table_data = [headers]

        for v in violations:
            employee = v.get("employee", "Unknown")
            role = v.get("role", "-")
            tenure = v.get("tenure", "-")
            clause = v.get("clause", "-")
            rule = v.get("rule", "-")
            actual = v.get("actual", "N/A")
            expected = v.get("expected", "N/A")
            fix = v.get("fix", "")

            table_data.append([
                Paragraph(str(employee), self.styles["Normal"]),
                Paragraph(str(role), self.styles["TITAN_SMALL"]),
                Paragraph(str(tenure), self.styles["Normal"]),
                Paragraph(str(clause), self.styles["TITAN_SMALL"]),
                Paragraph(str(rule), self.styles["Normal"]),
                Paragraph(str(actual), self.styles["Normal"]),
                Paragraph(str(expected), self.styles["Normal"]),
                Paragraph(str(fix), self.styles["Normal"]),
            ])

        col_widths = [1.0*inch, 0.95*inch, 0.65*inch, 0.85*inch, 1.0*inch, 0.8*inch, 0.8*inch, 1.15*inch]

        t = Table(table_data, colWidths=col_widths, repeatRows=1)
        t.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2c3e50")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, 0), 8),
            ("BOTTOMPADDING", (0, 0), (-1, 0), 10),

            ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#ecf0f1")),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.white),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ]))
        story.append(t)
