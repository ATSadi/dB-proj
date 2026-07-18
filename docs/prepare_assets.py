"""Organize screenshots and generate diagram images for the project report/PPTX."""
from __future__ import annotations

import os
import shutil
from PIL import Image, ImageDraw, ImageFont

BASE = r"d:\dB proj\docs\report_assets"
SHOT = os.path.join(BASE, "screenshots")
OUT = os.path.join(BASE, "labeled")
os.makedirs(OUT, exist_ok=True)

MAPPING = {
    "image-3ee5c682-10d8-406f-bc9e-ddef29bb78d9.png": "ui-01-login.png",
    "image-12bf8c83-c246-4215-b9ef-887ef0c7d853.png": "ui-02-student.png",
    "image-99e45a8f-26e2-4ebd-bc72-5076a2222940.png": "ui-03-worker.png",
    "image-cbd54250-f148-4378-9fae-c9f8ea8962ba.png": "ui-04-student-detail.png",
    "image-dc35e39c-979b-4639-a5b5-b0d3a5569180.png": "ui-05-worker-jobs.png",
    "image-2d0fbb18-5967-482d-be50-bf4fd9c07273.png": "ui-06-supervisor-assign.png",
    "image-60fd3d0f-fe20-4e4b-8cda-d8da5b87ebba.png": "ui-07-supervisor-queue.png",
    "image-54783078-ee05-44c4-a66c-ce0dd0c2786e.png": "ui-08-supervisor-overdue.png",
    "image-d14c6edd-0ec5-439c-a71f-3c5aa91e7297.png": "ui-09-supervisor-workers.png",
    "image-cd0ae52a-a075-498d-b65c-f0cb983fd177.png": "ui-10-supervisor-chronic.png",
    "image-85d849ce-3cb8-4f4d-8993-2d948b31a817.png": "ui-11-supervisor-reports.png",
    "image-3a2da124-9999-4506-9920-d3d6f045e275.png": "ui-12-admin-assign.png",
    "image-a4a390be-f46e-481e-b866-6732ec48e456.png": "ui-13-admin-reports.png",
    "image-bf256dd6-3ee2-4835-9307-e1cfb7ea3a70.png": "ui-14-admin-directory.png",
    "image-624b460d-a6f3-40ef-a417-477d2c510998.png": "ui-15-admin-add-student.png",
    "image-81657ded-9c54-4b5a-bbaa-5d9e468ad44c.png": "ui-16-admin-add-worker.png",
    "image-4bd1e4f2-d891-4d7a-b381-e9f09c6ee4fe.png": "ui-17-admin-students-list.png",
    "image-f4937403-da42-4983-b83e-0e1700764732.png": "diagram-erd-dbeaver.png",
    "image-a3615fbe-2abe-42be-93d3-c88356507f96.png": "github-01-repo.png",
    "image-a0c997bc-78c3-48cd-b4fa-b6d9a1f69d06.png": "github-02-commits.png",
    "image-08a9f576-d20e-4f18-bedf-e1eca9310362.png": "github-03-contributors.png",
    "image-3a840385-f18e-4cf0-aa29-b8f3fb807096.png": "ui-extra-01.png",
    "image-5eab6100-88c9-411d-87bb-338fcccd8b17.png": "ui-extra-02.png",
}


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        r"C:\Windows\Fonts\segoeuib.ttf" if bold else r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def rounded_rect(draw, box, radius, fill, outline=None, width=2):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def organize_screenshots() -> None:
    for name in os.listdir(SHOT):
        src = os.path.join(SHOT, name)
        if name in ("01-login.png", "02-student.png", "03-worker.png", "04-admin.png"):
            shutil.copy2(src, os.path.join(OUT, name))
            continue
        matched = False
        for key, dest in MAPPING.items():
            if key in name:
                shutil.copy2(src, os.path.join(OUT, dest))
                matched = True
                break
        if not matched:
            print("unmapped:", name)
    print("labeled count:", len(os.listdir(OUT)))


def make_architecture() -> None:
    w, h = 1400, 820
    img = Image.new("RGB", (w, h), "#0B1220")
    d = ImageDraw.Draw(img)
    for x in range(0, w, 40):
        d.line([(x, 0), (x, h)], fill="#121A2B", width=1)
    for y in range(0, h, 40):
        d.line([(0, y), (w, y)], fill="#121A2B", width=1)

    d.text((60, 36), "System Architecture", font=font(36, True), fill="#F8FAFC")
    d.text(
        (60, 82),
        "Campus Maintenance & Complaint Management System",
        font=font(18),
        fill="#94A3B8",
    )

    layers = [
        (
            60,
            140,
            1280,
            150,
            "#1E293B",
            "#38BDF8",
            "Presentation Layer",
            "HTML · CSS · JavaScript  |  Student / Worker / Supervisor / Admin portals",
        ),
        (
            60,
            330,
            1280,
            150,
            "#1E293B",
            "#A78BFA",
            "Application Layer",
            "Node.js + Express REST API  ·  Session auth  ·  Role guards  ·  oracledb driver",
        ),
        (
            60,
            520,
            1280,
            220,
            "#1E293B",
            "#34D399",
            "Database Layer (Oracle)",
            "Tables · Sequences · Triggers · Procedures · Functions · Views · Role grants",
        ),
    ]
    for x, y, lw, lh, fill, accent, title, sub in layers:
        rounded_rect(d, (x, y, x + lw, y + lh), 18, fill, accent, 3)
        d.ellipse((x + 28, y + 36, x + 48, y + 56), fill=accent)
        d.text((x + 68, y + 30), title, font=font(26, True), fill="#F8FAFC")
        d.text((x + 68, y + 75), sub, font=font(18), fill="#CBD5E1")

    for y in (290, 480):
        d.polygon([(700, y), (720, y), (710, y + 28)], fill="#64748B")

    img.save(os.path.join(BASE, "diagram-architecture.png"))
    print("architecture ok")


def make_workflow() -> None:
    w, h = 1500, 520
    img = Image.new("RGB", (w, h), "#0B1220")
    d = ImageDraw.Draw(img)
    d.text((50, 30), "End-to-End Complaint Lifecycle", font=font(32, True), fill="#F8FAFC")
    d.text(
        (50, 72),
        "Student → Supervisor → Worker → Feedback → Admin Reports",
        font=font(16),
        fill="#94A3B8",
    )

    steps = [
        ("1", "Submit", "Student files\ncomplaint + priority"),
        ("2", "Assign", "Supervisor assigns\nspecialized worker"),
        ("3", "Resolve", "Worker starts &\ncompletes job"),
        ("4", "Rate", "Student rates\nresolved work"),
        ("5", "Report", "Admin generates\nmonthly report"),
    ]
    colors = ["#38BDF8", "#A78BFA", "#34D399", "#FBBF24", "#F472B6"]
    for i, (n, title, sub) in enumerate(steps):
        x = 50 + i * 290
        y = 150
        rounded_rect(d, (x, y, x + 240, y + 280), 20, "#1E293B", colors[i], 3)
        d.ellipse((x + 90, y + 28, x + 150, y + 88), fill=colors[i])
        d.text((x + 112, y + 42), n, font=font(28, True), fill="#0B1220")
        d.text((x + 28, y + 120), title, font=font(24, True), fill="#F8FAFC")
        yy = y + 170
        for line in sub.split("\n"):
            d.text((x + 28, yy), line, font=font(16), fill="#CBD5E1")
            yy += 26
        if i < len(steps) - 1:
            d.polygon([(x + 250, y + 140), (x + 278, y + 155), (x + 250, y + 170)], fill="#64748B")

    img.save(os.path.join(BASE, "diagram-workflow.png"))
    print("workflow ok")


def make_erd_overview() -> None:
    w, h = 1600, 1100
    img = Image.new("RGB", (w, h), "#0B1220")
    d = ImageDraw.Draw(img)
    d.text((50, 30), "Entity Relationship Overview", font=font(34, True), fill="#F8FAFC")
    d.text(
        (50, 74),
        "Nine normalized tables · Primary/Foreign key relationships · 3NF design",
        font=font(16),
        fill="#94A3B8",
    )

    entities = {
        "USERS": (80, 160, ["user_id PK", "name", "email", "role", "roll_no"]),
        "LOCATIONS": (420, 160, ["location_id PK", "building", "floor", "room_no", "type"]),
        "COMPLAINTS": (
            760,
            200,
            [
                "complaint_id PK",
                "student_id FK",
                "location_id FK",
                "category",
                "priority",
                "status",
                "sla_deadline",
            ],
        ),
        "WORKERS": (80, 520, ["worker_id PK", "user_id FK", "specialization", "score", "available"]),
        "ASSIGNMENTS": (
            420,
            560,
            ["assignment_id PK", "complaint_id FK", "worker_id FK", "assigned_by FK", "cost"],
        ),
        "STATUS_LOG": (1120, 160, ["log_id PK", "complaint_id FK", "old/new status", "changed_by"]),
        "FEEDBACK": (1120, 480, ["feedback_id PK", "complaint_id FK", "student_id FK", "rating"]),
        "CHRONIC_FLAGS": (760, 700, ["flag_id PK", "location_id FK", "category", "count"]),
        "MAINTENANCE_REPORTS": (1120, 780, ["report_id PK", "month/year", "totals", "avg hrs", "cost"]),
    }
    accents = {
        "USERS": "#38BDF8",
        "LOCATIONS": "#34D399",
        "COMPLAINTS": "#A78BFA",
        "WORKERS": "#FBBF24",
        "ASSIGNMENTS": "#F472B6",
        "STATUS_LOG": "#22D3EE",
        "FEEDBACK": "#FB7185",
        "CHRONIC_FLAGS": "#A3E635",
        "MAINTENANCE_REPORTS": "#C084FC",
    }

    centers = {}
    for name, (x, y, cols) in entities.items():
        eh = 54 + len(cols) * 28
        ew = 280
        accent = accents[name]
        rounded_rect(d, (x, y, x + ew, y + eh), 12, "#111827", accent, 2)
        d.rectangle((x, y, x + ew, y + 42), fill=accent)
        d.text((x + 14, y + 8), name, font=font(18, True), fill="#0B1220")
        yy = y + 52
        for col in cols:
            d.text((x + 14, yy), col, font=font(14), fill="#E2E8F0")
            yy += 28
        centers[name] = (x + ew // 2, y + eh // 2)

    rels = [
        ("USERS", "COMPLAINTS"),
        ("LOCATIONS", "COMPLAINTS"),
        ("USERS", "WORKERS"),
        ("COMPLAINTS", "ASSIGNMENTS"),
        ("WORKERS", "ASSIGNMENTS"),
        ("USERS", "ASSIGNMENTS"),
        ("COMPLAINTS", "STATUS_LOG"),
        ("COMPLAINTS", "FEEDBACK"),
        ("LOCATIONS", "CHRONIC_FLAGS"),
    ]
    for a, b in rels:
        d.line([centers[a], centers[b]], fill="#475569", width=2)

    img.save(os.path.join(BASE, "diagram-erd-overview.png"))
    print("erd overview ok")


def make_roles() -> None:
    w, h = 1400, 700
    img = Image.new("RGB", (w, h), "#0B1220")
    d = ImageDraw.Draw(img)
    d.text((50, 30), "Role-Based Access Model", font=font(34, True), fill="#F8FAFC")
    roles = [
        (80, 160, "Student", "#38BDF8", ["Submit complaints", "Track SLA", "Rate resolved jobs"]),
        (390, 160, "Worker", "#34D399", ["View assignments", "Start / resolve jobs", "Toggle availability"]),
        (700, 160, "Supervisor", "#A78BFA", ["Assign workers", "Monitor overdue", "View chronic flags"]),
        (1010, 160, "Admin", "#FBBF24", ["Full operations", "Directory CRUD", "Monthly reports"]),
    ]
    for x, y, title, color, items in roles:
        rounded_rect(d, (x, y, x + 290, y + 420), 18, "#1E293B", color, 3)
        d.text((x + 24, y + 30), title, font=font(26, True), fill=color)
        yy = y + 100
        for item in items:
            d.ellipse((x + 28, yy + 6, x + 42, yy + 20), fill=color)
            d.text((x + 56, yy), item, font=font(16), fill="#E2E8F0")
            yy += 50
    img.save(os.path.join(BASE, "diagram-roles.png"))
    print("roles ok")


def make_plsql() -> None:
    w, h = 1400, 780
    img = Image.new("RGB", (w, h), "#0B1220")
    d = ImageDraw.Draw(img)
    d.text((50, 30), "Database Intelligence Layer (PL/SQL)", font=font(32, True), fill="#F8FAFC")
    cards = [
        (60, 120, "Triggers", "#38BDF8", ["SLA deadline auto-set", "Status audit logging", "Chronic issue flagging", "Worker score refresh", "Availability updates"]),
        (500, 120, "Procedures", "#A78BFA", ["assign_worker", "escalate_overdue", "generate_monthly_report", "Transaction-safe ops", "Role-checked actions"]),
        (940, 120, "Functions / Rules", "#34D399", ["Performance scoring", "Resolution-time calc", "Priority → SLA mapping", "Specialization match", "Integrity constraints"]),
    ]
    for x, y, title, color, items in cards:
        rounded_rect(d, (x, y, x + 400, y + 560), 18, "#1E293B", color, 3)
        d.text((x + 28, y + 30), title, font=font(26, True), fill=color)
        yy = y + 110
        for item in items:
            rounded_rect(d, (x + 28, yy, x + 372, yy + 60), 10, "#0F172A", None, 0)
            d.text((x + 48, yy + 16), item, font=font(16), fill="#E2E8F0")
            yy += 78
    img.save(os.path.join(BASE, "diagram-plsql.png"))
    print("plsql ok")


if __name__ == "__main__":
    organize_screenshots()
    make_architecture()
    make_workflow()
    make_erd_overview()
    make_roles()
    make_plsql()
    print("DONE")
