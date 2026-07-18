"""Generate the Campus Maintenance project PDF report and PPTX presentation."""
from __future__ import annotations

import os
from io import BytesIO

from PIL import Image as PILImage
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.util import Inches, Pt, Emu
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch, mm
from reportlab.platypus import (
    Image,
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = r"d:\dB proj"
ASSETS = os.path.join(ROOT, "docs", "report_assets")
LABELED = os.path.join(ASSETS, "labeled")
OUT_PDF = os.path.join(ROOT, "docs", "Campus_Maintenance_Project_Report_Ahnaf_Tajwar_Sadi_2207104.pdf")
OUT_PPTX = os.path.join(ROOT, "docs", "Campus_Maintenance_Presentation_Ahnaf_Tajwar_Sadi_2207104.pptx")
KUET = os.path.join(ASSETS, "kuet_logo.png")
GITHUB = "https://github.com/ATSadi/dB-proj/"

NAVY = colors.HexColor("#0B1220")
ACCENT = colors.HexColor("#1D4ED8")
SOFT = colors.HexColor("#E2E8F0")
MUTED = colors.HexColor("#64748B")
CARD = colors.HexColor("#F8FAFC")
LINE = colors.HexColor("#CBD5E1")


def path(*parts: str) -> str:
    return os.path.join(*parts)


def img(name: str, labeled: bool = True) -> str:
    return path(LABELED if labeled else ASSETS, name)


def fit_image(src: str, max_w: float, max_h: float) -> Image:
    with PILImage.open(src) as im:
        w, h = im.size
    scale = min(max_w / w, max_h / h)
    return Image(src, width=w * scale, height=h * scale)


def make_styles():
    styles = getSampleStyleSheet()
    styles.add(
        ParagraphStyle(
            name="CoverTitle",
            fontName="Helvetica-Bold",
            fontSize=22,
            leading=28,
            alignment=TA_CENTER,
            textColor=NAVY,
            spaceAfter=8,
        )
    )
    styles.add(
        ParagraphStyle(
            name="CoverSub",
            fontName="Helvetica",
            fontSize=12,
            leading=16,
            alignment=TA_CENTER,
            textColor=MUTED,
            spaceAfter=6,
        )
    )
    styles.add(
        ParagraphStyle(
            name="H1Custom",
            fontName="Helvetica-Bold",
            fontSize=16,
            leading=20,
            textColor=NAVY,
            spaceBefore=8,
            spaceAfter=10,
            borderPadding=3,
        )
    )
    styles.add(
        ParagraphStyle(
            name="H2Custom",
            fontName="Helvetica-Bold",
            fontSize=12.5,
            leading=16,
            textColor=ACCENT,
            spaceBefore=10,
            spaceAfter=6,
        )
    )
    styles.add(
        ParagraphStyle(
            name="BodyJust",
            fontName="Helvetica",
            fontSize=10.2,
            leading=14.5,
            alignment=TA_JUSTIFY,
            textColor=colors.HexColor("#1E293B"),
            spaceAfter=7,
        )
    )
    styles.add(
        ParagraphStyle(
            name="Caption",
            fontName="Helvetica-Oblique",
            fontSize=8.5,
            leading=11,
            alignment=TA_CENTER,
            textColor=MUTED,
            spaceBefore=4,
            spaceAfter=12,
        )
    )
    styles.add(
        ParagraphStyle(
            name="BulletBody",
            fontName="Helvetica",
            fontSize=10,
            leading=13.5,
            textColor=colors.HexColor("#1E293B"),
        )
    )
    styles.add(
        ParagraphStyle(
            name="Footer",
            fontName="Helvetica",
            fontSize=8,
            textColor=MUTED,
            alignment=TA_CENTER,
        )
    )
    styles.add(
        ParagraphStyle(
            name="TOCEntry",
            fontName="Helvetica",
            fontSize=10.5,
            leading=16,
            textColor=colors.HexColor("#1E293B"),
            leftIndent=8,
        )
    )
    styles.add(
        ParagraphStyle(
            name="SmallCenter",
            fontName="Helvetica",
            fontSize=9.5,
            leading=13,
            alignment=TA_CENTER,
            textColor=MUTED,
        )
    )
    return styles


def bullets(items, styles):
    return ListFlowable(
        [ListItem(Paragraph(i, styles["BulletBody"]), leftIndent=8, value="•") for i in items],
        bulletType="bullet",
        start="•",
        leftIndent=12,
        bulletFontName="Helvetica",
        bulletFontSize=10,
    )


def section_title(text, styles):
    data = [[Paragraph(text, styles["H1Custom"])]]
    t = Table(data, colWidths=[6.7 * inch])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), CARD),
                ("BOX", (0, 0), (-1, -1), 0.6, LINE),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return t


def figure(story, styles, src, caption, max_w=6.4 * inch, max_h=3.5 * inch):
    if not os.path.exists(src):
        story.append(Paragraph(f"[Missing figure: {os.path.basename(src)}]", styles["Caption"]))
        return
    story.append(KeepTogether([fit_image(src, max_w, max_h), Paragraph(caption, styles["Caption"])]))


def info_table(rows, col_widths):
    style_data = [
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("ALIGN", (0, 0), (-1, 0), "CENTER"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("GRID", (0, 0), (-1, -1), 0.4, LINE),
        ("BACKGROUND", (0, 1), (-1, -1), colors.white),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, CARD]),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]
    t = Table(rows, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle(style_data))
    return t


def add_page_number(canvas, doc):
    canvas.saveState()
    page = canvas.getPageNumber()
    if page > 1:
        canvas.setStrokeColor(LINE)
        canvas.setLineWidth(0.6)
        canvas.line(18 * mm, 14 * mm, A4[0] - 18 * mm, 14 * mm)
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(MUTED)
        canvas.drawString(18 * mm, 8 * mm, "Campus Maintenance & Complaint Management System")
        canvas.drawRightString(A4[0] - 18 * mm, 8 * mm, f"Page {page}")
        canvas.setFillColor(ACCENT)
        canvas.rect(0, A4[1] - 4 * mm, A4[0], 4 * mm, fill=1, stroke=0)
    canvas.restoreState()


def build_pdf():
    styles = make_styles()
    doc = SimpleDocTemplate(
        OUT_PDF,
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=16 * mm,
        bottomMargin=18 * mm,
        title="Campus Maintenance & Complaint Management System — Project Report",
        author="Ahnaf Tajwar Sadi",
    )
    story = []

    # -------- Cover --------
    story.append(Spacer(1, 18 * mm))
    if os.path.exists(KUET):
        story.append(fit_image(KUET, 1.45 * inch, 1.45 * inch))
    story.append(Spacer(1, 8 * mm))
    story.append(Paragraph("KHULNA UNIVERSITY OF ENGINEERING & TECHNOLOGY", styles["CoverSub"]))
    story.append(Paragraph("Department of Computer Science and Engineering", styles["CoverSub"]))
    story.append(Spacer(1, 8 * mm))
    story.append(
        Paragraph(
            "Campus Maintenance &amp; Complaint<br/>Management System",
            styles["CoverTitle"],
        )
    )
    story.append(
        Paragraph(
            "Database Systems Laboratory Project Report",
            ParagraphStyle("x", parent=styles["CoverSub"], textColor=ACCENT, fontName="Helvetica-Bold"),
        )
    )
    story.append(Spacer(1, 14 * mm))

    meta = [
        ["Student Name", "Ahnaf Tajwar Sadi"],
        ["Roll Number", "2207104"],
        ["Course", "Database Systems Lab"],
        ["Technology", "Oracle SQL/PL/SQL · Node.js · Express · HTML/CSS/JS"],
        ["Repository", GITHUB],
        ["Date", "July 2026"],
    ]
    mt = Table(meta, colWidths=[1.8 * inch, 4.6 * inch])
    mt.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (0, -1), CARD),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 10),
                ("TEXTCOLOR", (0, 0), (-1, -1), NAVY),
                ("BOX", (0, 0), (-1, -1), 0.8, LINE),
                ("INNERGRID", (0, 0), (-1, -1), 0.4, LINE),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
            ]
        )
    )
    story.append(mt)
    story.append(Spacer(1, 16 * mm))
    story.append(
        Paragraph(
            "A database-driven campus operations platform for complaint submission, "
            "worker assignment, SLA enforcement, chronic-issue detection, and monthly reporting.",
            styles["SmallCenter"],
        )
    )
    story.append(PageBreak())

    # -------- TOC --------
    story.append(section_title("Table of Contents", styles))
    story.append(Spacer(1, 4 * mm))
    toc = [
        "1. Introduction",
        "2. Objectives",
        "3. Problem Statement &amp; Motivation",
        "4. System Overview &amp; Key Features",
        "5. Technology Stack",
        "6. Role-Based Workflow",
        "7. System Architecture",
        "8. Database Design",
        "9. PL/SQL Business Logic",
        "10. Implementation &amp; User Interfaces",
        "11. Security &amp; Authentication",
        "12. Testing &amp; Demo Accounts",
        "13. Repository &amp; Development History",
        "14. Conclusion &amp; Future Work",
        "15. References",
    ]
    for item in toc:
        story.append(Paragraph(item, styles["TOCEntry"]))
    story.append(PageBreak())

    # -------- 1 --------
    story.append(section_title("1. Introduction", styles))
    story.append(
        Paragraph(
            "Campus facilities generate continuous maintenance demand across classrooms, laboratories, "
            "hostels, offices, and common areas. Manual complaint handling is slow, opaque, and difficult "
            "to audit. This project implements a complete <b>Campus Maintenance &amp; Complaint Management "
            "System</b> that couples a normalized Oracle database with role-based web portals.",
            styles["BodyJust"],
        )
    )
    story.append(
        Paragraph(
            "Students submit location-aware complaints with category and priority. Supervisors assign "
            "specialized workers, monitor SLA breaches and chronic issues, and generate monthly reports. "
            "Workers execute jobs and update availability. Admins manage the directory of students, "
            "workers, and locations. Core business rules—SLA deadlines, escalation, audit logging, "
            "performance scoring, and chronic-flag detection—are enforced inside the database using "
            "triggers, procedures, and functions.",
            styles["BodyJust"],
        )
    )

    # -------- 2 --------
    story.append(section_title("2. Objectives", styles))
    story.append(
        bullets(
            [
                "Design a 3NF relational schema covering users, locations, complaints, assignments, feedback, and reports.",
                "Implement Oracle PL/SQL automation for SLA, escalation, audit trails, and performance scoring.",
                "Build role-based portals for Student, Worker, Supervisor, and Admin with a shared Node.js API.",
                "Provide operational dashboards for queues, overdue work, chronic locations, and monthly analytics.",
                "Demonstrate end-to-end workflow with seed data, authentication, and a public GitHub repository.",
            ],
            styles,
        )
    )
    story.append(Spacer(1, 3 * mm))

    # -------- 3 --------
    story.append(section_title("3. Problem Statement &amp; Motivation", styles))
    story.append(
        Paragraph(
            "Without a centralized system, maintenance requests are lost in informal channels. Supervisors "
            "cannot see workload, SLA risk, or recurring location failures. Workers lack a clear assignment "
            "queue. Students receive little feedback after reporting an issue. A database-centric solution "
            "is ideal because integrity, history, and analytics all depend on durable relational data and "
            "server-side constraints rather than UI-only validation.",
            styles["BodyJust"],
        )
    )

    # -------- 4 --------
    story.append(section_title("4. System Overview &amp; Key Features", styles))
    story.append(Paragraph("4.1 Core Features", styles["H2Custom"]))
    story.append(
        bullets(
            [
                "Complaint submission with category, priority, location, and description.",
                "Supervisor assignment of workers with specialization awareness.",
                "Worker job lifecycle: start, resolve, log repair cost, toggle availability.",
                "Student feedback/rating after resolution.",
                "Monthly maintenance report generation with totals, averages, and cost.",
            ],
            styles,
        )
    )
    story.append(Paragraph("4.2 Enhanced Database Features", styles["H2Custom"]))
    story.append(
        bullets(
            [
                "<b>SLA tracking:</b> urgent = 4 hours, medium = 24 hours, low = 72 hours (trigger).",
                "<b>Auto-escalation:</b> overdue assigned complaints can be escalated for supervisor attention.",
                "<b>Audit log:</b> every status transition is recorded in STATUS_LOG.",
                "<b>Chronic detection:</b> 3+ same category at the same location creates a chronic flag.",
                "<b>Performance score:</b> worker score derived from resolution time and feedback ratings.",
                "<b>Budget tracking:</b> repair cost stored per assignment and rolled into monthly reports.",
            ],
            styles,
        )
    )
    story.append(Spacer(1, 2 * mm))
    figure(
        story,
        styles,
        img("diagram-workflow.png", labeled=False),
        "Figure 1. End-to-end complaint lifecycle across system roles.",
        max_h=2.8 * inch,
    )

    # -------- 5 --------
    story.append(section_title("5. Technology Stack", styles))
    stack = [
        [Paragraph("<b>Layer</b>", styles["BulletBody"]), Paragraph("<b>Technology</b>", styles["BulletBody"])],
        ["Database", "Oracle Database 21c XE — SQL, PL/SQL, sequences, triggers, procedures, functions"],
        ["Backend API", "Node.js, Express, oracledb, session/token auth, REST endpoints"],
        ["Frontend", "HTML5, modern CSS, vanilla JavaScript (role portals)"],
        ["Tooling", "DBeaver / SQL Developer, GitHub, dbdiagram.io (ERD source)"],
    ]
    story.append(info_table(stack, [1.5 * inch, 5.2 * inch]))
    story.append(Spacer(1, 4 * mm))

    # -------- 6 --------
    story.append(section_title("6. Role-Based Workflow", styles))
    story.append(
        Paragraph(
            "The command chain is: <b>Student submits → Supervisor assigns → Worker resolves → "
            "Student rates → Admin reports</b>. Supervisors and Admins share the operations dashboard; "
            "Admins additionally receive the Directory tab for account and location management.",
            styles["BodyJust"],
        )
    )
    roles = [
        [
            Paragraph("<b>Role</b>", styles["BulletBody"]),
            Paragraph("<b>Portal</b>", styles["BulletBody"]),
            Paragraph("<b>Responsibilities</b>", styles["BulletBody"]),
        ],
        ["Student", "/student.html", "Submit, track SLA, search/filter, rate resolved work"],
        ["Worker", "/worker.html", "Active/done jobs, SLA urgency, start/resolve, availability"],
        ["Supervisor", "/admin.html", "Assign, queue, overdue, workers, chronic, reports"],
        ["Admin", "/admin.html", "Full ops + Directory (students/workers/locations/CSV import)"],
    ]
    story.append(info_table(roles, [1.2 * inch, 1.4 * inch, 4.1 * inch]))
    story.append(Spacer(1, 3 * mm))
    figure(
        story,
        styles,
        img("diagram-roles.png", labeled=False),
        "Figure 2. Role-based access model.",
        max_h=2.9 * inch,
    )
    story.append(PageBreak())

    # -------- 7 --------
    story.append(section_title("7. System Architecture", styles))
    story.append(
        Paragraph(
            "The system follows a classic three-tier architecture. The browser hosts role-specific "
            "portals. Express exposes authenticated REST APIs. Oracle stores authoritative state and "
            "executes business rules close to the data for consistency and auditability.",
            styles["BodyJust"],
        )
    )
    figure(
        story,
        styles,
        img("diagram-architecture.png", labeled=False),
        "Figure 3. Three-tier system architecture.",
        max_h=3.4 * inch,
    )
    story.append(
        Paragraph(
            "Project layout groups DDL/DML/PLSQL under <b>sql/</b>, the API and static UI under "
            "<b>frontend/</b>, design documents under <b>docs/</b>, and screenshots under <b>assets/</b>.",
            styles["BodyJust"],
        )
    )

    # -------- 8 --------
    story.append(section_title("8. Database Design", styles))
    story.append(Paragraph("8.1 Entity Relationship Diagram", styles["H2Custom"]))
    story.append(
        Paragraph(
            "The schema contains nine core tables. COMPLAINTS is the central fact entity linking "
            "students and locations. ASSIGNMENTS connect workers to complaints. STATUS_LOG and FEEDBACK "
            "preserve history and quality signals. CHRONIC_FLAGS and MAINTENANCE_REPORTS support "
            "operations analytics.",
            styles["BodyJust"],
        )
    )
    figure(
        story,
        styles,
        img("diagram-erd-overview.png", labeled=False),
        "Figure 4. Conceptual ER overview generated for this report.",
        max_h=4.2 * inch,
    )
    figure(
        story,
        styles,
        img("diagram-erd-dbeaver.png"),
        "Figure 5. Relational schema diagram (table relationships view).",
        max_h=4.0 * inch,
    )

    story.append(Paragraph("8.2 Tables Overview", styles["H2Custom"]))
    tables = [
        [
            Paragraph("<b>Table</b>", styles["BulletBody"]),
            Paragraph("<b>Purpose</b>", styles["BulletBody"]),
            Paragraph("<b>PK</b>", styles["BulletBody"]),
        ],
        ["USERS", "All actors (student/worker/supervisor/admin)", "user_id"],
        ["LOCATIONS", "Campus building / floor / room registry", "location_id"],
        ["COMPLAINTS", "Maintenance requests with SLA & status", "complaint_id"],
        ["WORKERS", "Worker profile + specialization + score", "worker_id"],
        ["ASSIGNMENTS", "Worker–complaint link, timing, repair cost", "assignment_id"],
        ["STATUS_LOG", "Immutable audit trail of status changes", "log_id"],
        ["FEEDBACK", "Student rating after resolution", "feedback_id"],
        ["CHRONIC_FLAGS", "Recurring location + category alerts", "flag_id"],
        ["MAINTENANCE_REPORTS", "Monthly aggregated operations snapshot", "report_id"],
    ]
    story.append(info_table(tables, [1.7 * inch, 3.7 * inch, 1.3 * inch]))
    story.append(Spacer(1, 3 * mm))

    story.append(Paragraph("8.3 Normalization (3NF)", styles["H2Custom"]))
    story.append(
        bullets(
            [
                "<b>1NF:</b> atomic attributes, unique rows, no repeating groups.",
                "<b>2NF:</b> surrogate single-column keys; no partial dependencies.",
                "<b>3NF:</b> worker-specific fields isolated in WORKERS; history in STATUS_LOG; ratings in FEEDBACK.",
                "<b>Controlled denormalization:</b> cached sla_deadline and performance_score for query speed.",
            ],
            styles,
        )
    )
    story.append(PageBreak())

    # -------- 9 --------
    story.append(section_title("9. PL/SQL Business Logic", styles))
    story.append(
        Paragraph(
            "Database intelligence is a primary learning outcome of this project. Business rules are not "
            "left solely to the frontend; they are encoded as Oracle objects so every client path remains consistent.",
            styles["BodyJust"],
        )
    )
    figure(
        story,
        styles,
        img("diagram-plsql.png", labeled=False),
        "Figure 6. PL/SQL triggers, procedures, and functions summary.",
        max_h=3.5 * inch,
    )
    story.append(Paragraph("9.1 Representative Rules", styles["H2Custom"]))
    rules = [
        [
            Paragraph("<b>Rule</b>", styles["BulletBody"]),
            Paragraph("<b>Enforcement</b>", styles["BulletBody"]),
        ],
        ["Priority → SLA deadline", "Trigger on COMPLAINTS INSERT"],
        ["Status change audit", "Trigger writes STATUS_LOG rows"],
        ["Chronic issue (≥3 same location+category)", "Compound trigger on COMPLAINTS"],
        ["Worker performance score refresh", "Trigger/function after FEEDBACK"],
        ["Assign specialized worker", "Stored procedure assign_worker"],
        ["Escalate overdue assigned work", "Procedure escalate_overdue_complaints"],
        ["Generate monthly report", "Procedure writing MAINTENANCE_REPORTS"],
    ]
    story.append(info_table(rules, [3.2 * inch, 3.5 * inch]))
    story.append(Spacer(1, 3 * mm))

    # -------- 10 --------
    story.append(section_title("10. Implementation &amp; User Interfaces", styles))
    story.append(
        Paragraph(
            "The frontend is a responsive dark-themed operations UI with shared navigation patterns, "
            "role guards, and live dashboard metrics. Below are representative screenshots from the running system.",
            styles["BodyJust"],
        )
    )

    story.append(Paragraph("10.1 Authentication", styles["H2Custom"]))
    story.append(
        Paragraph(
            "Users sign in with email and password. Demo accounts use the shared initial password "
            "<b>Password123</b>. A forgot-password flow issues a short-lived reset code (shown in the UI "
            "when DEMO_MODE is enabled).",
            styles["BodyJust"],
        )
    )
    figure(story, styles, img("ui-01-login.png"), "Figure 7. Login portal with role-aware access.")

    story.append(Paragraph("10.2 Student Portal", styles["H2Custom"]))
    story.append(
        Paragraph(
            "Students submit complaints, filter/search their history, monitor SLA remaining time, and "
            "rate resolved work through a modal feedback flow.",
            styles["BodyJust"],
        )
    )
    figure(story, styles, img("ui-02-student.png"), "Figure 8. Student portal overview.")
    figure(story, styles, img("ui-04-student-detail.png"), "Figure 9. Student complaint tracking / details.")

    story.append(Paragraph("10.3 Worker Portal", styles["H2Custom"]))
    story.append(
        Paragraph(
            "Workers view assigned jobs, separate active vs completed work, start and resolve tasks, "
            "and toggle availability for new assignments.",
            styles["BodyJust"],
        )
    )
    figure(story, styles, img("ui-03-worker.png"), "Figure 10. Worker portal.")
    figure(story, styles, img("ui-05-worker-jobs.png"), "Figure 11. Worker job queue and actions.")
    story.append(PageBreak())

    story.append(Paragraph("10.4 Supervisor Operations Dashboard", styles["H2Custom"]))
    story.append(
        Paragraph(
            "Supervisors manage day-to-day operations: assign workers from the submitted queue, inspect "
            "overdue SLA breaches, review worker performance, investigate chronic locations, and open reports.",
            styles["BodyJust"],
        )
    )
    figure(story, styles, img("ui-06-supervisor-assign.png"), "Figure 12. Supervisor — Assign worker.")
    figure(story, styles, img("ui-07-supervisor-queue.png"), "Figure 13. Supervisor — Complaint queue.")
    figure(story, styles, img("ui-08-supervisor-overdue.png"), "Figure 14. Supervisor — Overdue complaints.")
    figure(story, styles, img("ui-09-supervisor-workers.png"), "Figure 15. Supervisor — Worker performance.")
    figure(story, styles, img("ui-10-supervisor-chronic.png"), "Figure 16. Supervisor — Chronic issues.")
    figure(story, styles, img("ui-11-supervisor-reports.png"), "Figure 17. Supervisor — Maintenance reports.")
    story.append(PageBreak())

    story.append(Paragraph("10.5 Admin Dashboard &amp; Directory", styles["H2Custom"]))
    story.append(
        Paragraph(
            "Admins inherit the operations dashboard and gain Directory management: add students "
            "(including CSV bulk import), add workers with specialization, register locations, and browse directories.",
            styles["BodyJust"],
        )
    )
    figure(story, styles, img("ui-12-admin-assign.png"), "Figure 18. Admin — Operations assign view.")
    figure(story, styles, img("ui-13-admin-reports.png"), "Figure 19. Admin — Generated monthly reports.")
    figure(story, styles, img("ui-14-admin-directory.png"), "Figure 20. Admin — Directory overview.")
    figure(story, styles, img("ui-15-admin-add-student.png"), "Figure 21. Admin — Add / import students.")
    figure(story, styles, img("ui-16-admin-add-worker.png"), "Figure 22. Admin — Add worker / location forms.")
    figure(story, styles, img("ui-17-admin-students-list.png"), "Figure 23. Admin — Students &amp; directories.")
    story.append(PageBreak())

    # -------- 11 --------
    story.append(section_title("11. Security &amp; Authentication", styles))
    story.append(
        bullets(
            [
                "Password hashes stored in the database (scrypt-based hashing in the Node API).",
                "Bearer/session token required for privileged Admin Directory APIs.",
                "Role guards prevent students/workers from accessing supervisor/admin actions.",
                "Supervisors cannot use Admin-only Directory mutation endpoints (403).",
                "Password reset tokens are time-limited; demo mode surfaces codes for viva convenience.",
                "Oracle CHECK constraints and FK relationships protect data integrity independently of the UI.",
            ],
            styles,
        )
    )

    # -------- 12 --------
    story.append(section_title("12. Testing &amp; Demo Accounts", styles))
    story.append(
        Paragraph(
            "Seed scripts and a demo-reset script populate a realistic campus dataset (students, workers, "
            "locations, mixed complaint statuses, overdue work, and at least one chronic plumbing location). "
            "Default password for demo accounts: <b>Password123</b>.",
            styles["BodyJust"],
        )
    )
    demos = [
        [
            Paragraph("<b>Role</b>", styles["BulletBody"]),
            Paragraph("<b>Email</b>", styles["BulletBody"]),
            Paragraph("<b>Password</b>", styles["BulletBody"]),
        ],
        ["Student", "hassan.r@stu.edu", "Password123"],
        ["Worker", "rashid.i@campus.edu", "Password123"],
        ["Supervisor", "omar.s@campus.edu", "Password123"],
        ["Admin", "admin@campus.edu", "Password123"],
    ]
    story.append(info_table(demos, [1.4 * inch, 3.2 * inch, 2.1 * inch]))
    story.append(Spacer(1, 3 * mm))
    story.append(
        Paragraph(
            "Local run: configure <b>frontend/.env</b>, start Oracle listener/service, run SQL scripts, then "
            "<b>npm start</b> in <b>frontend/</b> and open http://localhost:3000.",
            styles["BodyJust"],
        )
    )

    # -------- 13 --------
    story.append(section_title("13. Repository &amp; Development History", styles))
    story.append(
        Paragraph(
            f"Source code, SQL scripts, documentation, and screenshots are hosted at "
            f'<link href="{GITHUB}"><font color="#1D4ED8"><u>{GITHUB}</u></font></link>.',
            styles["BodyJust"],
        )
    )
    figure(story, styles, img("github-01-repo.png"), "Figure 24. GitHub repository landing page.")
    figure(story, styles, img("github-02-commits.png"), "Figure 25. Commit history highlighting database → API → UI progression.")
    figure(story, styles, img("github-03-contributors.png"), "Figure 26. Contributors / commit activity insight.")
    story.append(
        Paragraph(
            "Development progressed from schema/ERD foundations and PL/SQL automation, through Node.js "
            "API integration and analytical queries, to polished role portals (student filters, worker "
            "availability, admin/supervisor dashboards) and documentation for viva demos.",
            styles["BodyJust"],
        )
    )
    story.append(PageBreak())

    # -------- 14 --------
    story.append(section_title("14. Conclusion &amp; Future Work", styles))
    story.append(
        Paragraph(
            "The project successfully demonstrates a production-shaped academic system: normalized schema "
            "design, database-enforced business rules, multi-role workflows, operational analytics, and a "
            "usable web interface. It shows how Oracle PL/SQL and a lightweight Node/Express layer can "
            "cooperate without sacrificing integrity.",
            styles["BodyJust"],
        )
    )
    story.append(Paragraph("Future extensions may include:", styles["H2Custom"]))
    story.append(
        bullets(
            [
                "Email/SMS notifications for SLA risk and assignment events.",
                "Photo attachments for complaint evidence (object storage).",
                "Advanced analytics dashboards (heatmaps by building/category).",
                "Mobile-first PWA packaging for on-site workers.",
                "Deeper Oracle role grants mapped 1:1 with application permissions.",
            ],
            styles,
        )
    )

    # -------- 15 --------
    story.append(section_title("15. References", styles))
    story.append(
        bullets(
            [
                "Oracle Database Documentation — SQL Language Reference &amp; PL/SQL Language Reference.",
                "Elmasri, R. &amp; Navathe, S. — Fundamentals of Database Systems (normalization &amp; ER modeling).",
                "Express / Node.js documentation — https://expressjs.com/",
                "Project repository — https://github.com/ATSadi/dB-proj/",
                "Khulna University of Engineering &amp; Technology — https://www.kuet.ac.bd/",
            ],
            styles,
        )
    )
    story.append(Spacer(1, 12 * mm))
    story.append(Paragraph("— End of Report —", styles["SmallCenter"]))

    doc.build(story, onFirstPage=add_page_number, onLaterPages=add_page_number)
    print("PDF written:", OUT_PDF)




if __name__ == "__main__":
    build_pdf()
    print("PDF READY")
