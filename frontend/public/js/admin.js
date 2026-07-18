const user = requireAuth(['admin', 'supervisor']);
if (!user) throw new Error('unauthorized');

initNavbar(user.role === 'admin' ? 'Admin Dashboard' : 'Supervisor Dashboard');
const alertEl = document.getElementById('alert');

let queueComplaints = [];
let submitted = [];
let directoryData = { students: [], workers: [], locations: [] };
let csvStudents = [];

if (user.role !== 'admin') {
    document.querySelectorAll('.admin-only').forEach(el => el.remove());
}

const now = new Date();
document.getElementById('reportMonth').value = now.getMonth() + 1;
document.getElementById('reportYear').value = now.getFullYear();

function showSection(name) {
    if (name === 'directory' && user.role !== 'admin') return;
    document.querySelectorAll('.dash-section').forEach(el => {
        el.hidden = el.id !== `section-${name}`;
    });
    document.querySelectorAll('#sectionTabs .chip').forEach(chip => {
        chip.classList.toggle('active', chip.dataset.section === name);
    });
}

function renderDirectory() {
    if (user.role !== 'admin') return;
    const { students, workers, locations } = directoryData;
    const query = document.getElementById('studentSearch').value.trim().toLowerCase();
    const shownStudents = students.filter(student =>
        `${student.name} ${student.roll_no} ${student.email}`.toLowerCase().includes(query)
    );

    document.getElementById('directoryStats').innerHTML = `
        <div class="stat-card"><div class="value">${students.length}</div><div class="label">Students</div></div>
        <div class="stat-card accent-success"><div class="value">${workers.length}</div><div class="label">Workers</div></div>
        <div class="stat-card"><div class="value">${locations.length}</div><div class="label">Locations</div></div>`;

    document.getElementById('studentsBody').innerHTML = shownStudents.length
        ? shownStudents.map(student => `
            <tr>
                <td>#${student.user_id}</td>
                <td>${escapeHtml(student.name)}</td>
                <td>${escapeHtml(student.roll_no)}</td>
                <td>${escapeHtml(student.email)}</td>
            </tr>`).join('')
        : '<tr><td colspan="4" class="empty-state">No students found</td></tr>';

    document.getElementById('directoryWorkersBody').innerHTML = workers.length
        ? workers.map(worker => `
            <tr>
                <td>${escapeHtml(worker.name)}</td>
                <td>${escapeHtml(worker.specialization)}</td>
                <td>${worker.is_available === 'Y' ? 'Available' : 'Busy'}</td>
            </tr>`).join('')
        : '<tr><td colspan="3" class="empty-state">No workers</td></tr>';

    document.getElementById('directoryLocationsBody').innerHTML = locations.length
        ? locations.map(location => `
            <tr>
                <td>${escapeHtml(location.building)} · ${escapeHtml(location.floor)} / ${escapeHtml(location.room_no)}</td>
                <td>${escapeHtml(location.location_type)}</td>
            </tr>`).join('')
        : '<tr><td colspan="2" class="empty-state">No locations</td></tr>';
}

async function loadDirectory() {
    if (user.role !== 'admin') return;
    directoryData = await api('/admin/directory');
    renderDirectory();
}

function parseCsv(text) {
    const records = [];
    let record = [];
    let field = '';
    let quoted = false;

    for (let i = 0; i < text.length; i += 1) {
        const char = text[i];
        const next = text[i + 1];
        if (char === '"' && quoted && next === '"') {
            field += '"';
            i += 1;
        } else if (char === '"') {
            quoted = !quoted;
        } else if (char === ',' && !quoted) {
            record.push(field.trim());
            field = '';
        } else if ((char === '\n' || char === '\r') && !quoted) {
            if (char === '\r' && next === '\n') i += 1;
            record.push(field.trim());
            field = '';
            if (record.some(value => value !== '')) records.push(record);
            record = [];
        } else {
            field += char;
        }
    }
    record.push(field.trim());
    if (record.some(value => value !== '')) records.push(record);

    if (records.length < 2) throw new Error('CSV must include a header and at least one student');
    const headers = records[0].map(value => value.replace(/^\uFEFF/, '').toLowerCase());
    const required = ['name', 'roll_no', 'email'];
    required.forEach(header => {
        if (!headers.includes(header)) throw new Error(`Missing CSV column: ${header}`);
    });

    return records.slice(1).map(row => {
        const item = {};
        headers.forEach((header, index) => { item[header] = row[index] || ''; });
        return {
            name: item.name.trim(),
            roll_no: item.roll_no.trim(),
            email: item.email.trim()
        };
    }).filter(row => row.name || row.roll_no || row.email);
}

function renderQueue() {
    const status = document.getElementById('queueStatus').value;
    const q = document.getElementById('queueSearch').value.trim().toLowerCase();
    const rows = queueComplaints.filter(c => {
        if (status && c.status !== status) return false;
        if (!q) return true;
        const hay = `${c.category} ${c.building} ${c.room_no} ${c.student_name} ${c.worker_name || ''}`.toLowerCase();
        return hay.includes(q);
    });

    const tbody = document.getElementById('queueBody');
    const cards = document.getElementById('queueCards');

    if (!rows.length) {
        tbody.innerHTML = '<tr><td colspan="8" class="empty-state">No complaints in queue</td></tr>';
        cards.innerHTML = '<div class="empty-state">No complaints in queue</div>';
        return;
    }

    tbody.innerHTML = rows.map(c => `
        <tr class="${isOverdue(c.sla_deadline, c.status) ? 'row-overdue' : ''}">
            <td>#${c.complaint_id}</td>
            <td>${escapeHtml(c.student_name)}</td>
            <td>${escapeHtml(c.building)} ${escapeHtml(c.room_no)}</td>
            <td>${escapeHtml(c.category)}</td>
            <td>${badgePriority(c.priority)}</td>
            <td>${badgeStatus(c.status)}</td>
            <td>${escapeHtml(c.worker_name || '—')}</td>
            <td><span class="${isOverdue(c.sla_deadline, c.status) ? 'sla-warn' : 'sla-ok'}">${formatRelative(c.sla_deadline)}</span></td>
        </tr>`).join('');

    cards.innerHTML = rows.map(c => `
        <div class="complaint-card">
            <div class="title">#${c.complaint_id} · ${escapeHtml(c.category)}</div>
            <div class="sub">${escapeHtml(c.student_name)} · ${escapeHtml(c.building)} ${escapeHtml(c.room_no)}</div>
            <div class="meta">${badgePriority(c.priority)} ${badgeStatus(c.status)}</div>
        </div>`).join('');
}

function updateComplaintPreview() {
    const id = Number(document.getElementById('assignComplaint').value);
    const preview = document.getElementById('complaintPreview');
    const c = submitted.find(x => x.complaint_id === id);
    if (!c) {
        preview.hidden = true;
        preview.innerHTML = '';
        return;
    }
    preview.hidden = false;
    preview.innerHTML = `
        <strong>#${c.complaint_id}</strong> · ${badgePriority(c.priority)} ${badgeStatus(c.status)}<br>
        <span style="color:var(--muted)">${escapeHtml(c.building)} ${escapeHtml(c.room_no)} · ${escapeHtml(c.student_name)}</span><br>
        <span style="font-size:0.82rem">${escapeHtml(c.description || '')}</span>`;
}

async function loadDashboard() {
    const [dash, reports, submittedList, allComplaints, workers] = await Promise.all([
        api('/dashboard'),
        api('/reports'),
        api('/complaints?status=submitted'),
        api('/complaints'),
        api('/workers')
    ]);

    submitted = submittedList;
    queueComplaints = allComplaints;

    document.getElementById('dashStats').innerHTML = `
        <div class="stat-card accent-danger"><div class="value">${dash.overdue.length}</div><div class="label">Overdue</div></div>
        <div class="stat-card accent-warning"><div class="value">${submitted.length}</div><div class="label">Awaiting assign</div></div>
        <div class="stat-card"><div class="value">${dash.chronic.length}</div><div class="label">Chronic issues</div></div>
        <div class="stat-card accent-success"><div class="value">${dash.workers.length}</div><div class="label">Workers</div></div>`;

    document.getElementById('topCategories').innerHTML = dash.topCategories.length
        ? `<div class="table-wrap"><table><thead><tr><th>Category</th><th>Count</th></tr></thead><tbody>
            ${dash.topCategories.map(c => `<tr><td>${escapeHtml(c.category)}</td><td>${c.cnt}</td></tr>`).join('')}
           </tbody></table></div>`
        : '<div class="empty-state">No category data this month</div>';

    document.getElementById('overdueBody').innerHTML = dash.overdue.length
        ? dash.overdue.map(r => `
            <tr>
                <td>#${r.complaint_id}</td>
                <td>${escapeHtml(r.category)}</td>
                <td>${badgePriority(r.priority)}</td>
                <td class="sla-warn">${r.hours_overdue}h</td>
                <td>${escapeHtml(r.building)} ${escapeHtml(r.room_no)}</td>
                <td>${escapeHtml(r.worker_name || '—')}</td>
            </tr>`).join('')
        : '<tr><td colspan="6" class="empty-state">No overdue complaints</td></tr>';

    document.getElementById('workersBody').innerHTML = dash.workers.map(w => `
        <tr>
            <td>${escapeHtml(w.worker_name)}</td>
            <td>${escapeHtml(w.specialization)}</td>
            <td>${w.calculated_score ?? w.cached_score}</td>
            <td>${w.open_assignments}</td>
            <td>${w.completed_assignments}</td>
            <td>${w.overdue_count}</td>
            <td>${w.is_available === 'Y' ? 'Yes' : 'Busy'}</td>
        </tr>`).join('');

    document.getElementById('chronicBody').innerHTML = dash.chronic.length
        ? dash.chronic.map(c => `
            <tr>
                <td>${escapeHtml(c.building)} / ${escapeHtml(c.room_no)}</td>
                <td>${escapeHtml(c.category)}</td>
                <td>${c.complaint_count}</td>
                <td>${formatDate(c.flagged_at)}</td>
            </tr>`).join('')
        : '<tr><td colspan="4" class="empty-state">No chronic issues</td></tr>';

    document.getElementById('reportsBody').innerHTML = reports.length
        ? reports.map(r => `
            <tr>
                <td>${r.month}/${r.year}</td>
                <td>${r.total_complaints}</td>
                <td>${r.resolved_count}</td>
                <td>${r.avg_resolution_hrs ?? '—'}</td>
                <td>${r.total_cost}</td>
            </tr>`).join('')
        : '<tr><td colspan="5" class="empty-state">No reports yet</td></tr>';

    document.getElementById('assignWorker').innerHTML = workers
        .sort((a, b) => (a.is_available === 'Y' ? -1 : 1) - (b.is_available === 'Y' ? -1 : 1))
        .map(w =>
            `<option value="${w.worker_id}">${escapeHtml(w.name)} (${escapeHtml(w.specialization)}) · score ${w.performance_score} ${w.is_available === 'Y' ? '' : '· busy'}</option>`
        ).join('');

    document.getElementById('assignComplaint').innerHTML = submitted.length
        ? submitted.map(c =>
            `<option value="${c.complaint_id}">#${c.complaint_id} — ${escapeHtml(c.category)} @ ${escapeHtml(c.building)} ${escapeHtml(c.room_no)}</option>`
        ).join('')
        : '<option value="">No submitted complaints</option>';

    updateComplaintPreview();
    renderQueue();
}

document.getElementById('sectionTabs').addEventListener('click', (e) => {
    const chip = e.target.closest('.chip');
    if (!chip) return;
    showSection(chip.dataset.section);
    if (chip.dataset.section === 'directory') {
        loadDirectory().catch(err => showAlert(alertEl, err.message));
    }
});

document.getElementById('assignComplaint').addEventListener('change', updateComplaintPreview);
document.getElementById('queueStatus').addEventListener('change', renderQueue);
document.getElementById('queueSearch').addEventListener('input', renderQueue);
document.getElementById('refreshBtn').addEventListener('click', () => {
    loadDashboard().catch(err => showAlert(alertEl, err.message));
});

document.getElementById('assignForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const complaintId = document.getElementById('assignComplaint').value;
    if (!complaintId) return;
    const btn = document.getElementById('assignBtn');

    try {
        setButtonLoading(btn, true, 'Assigning…');
        await api('/assignments', {
            method: 'POST',
            body: JSON.stringify({
                complaint_id: Number(complaintId),
                worker_id: Number(document.getElementById('assignWorker').value),
                supervisor_id: user.user_id
            })
        });
        showAlert(alertEl, 'Worker assigned successfully!', 'success');
        await loadDashboard();
    } catch (err) {
        showAlert(alertEl, err.message);
    } finally {
        setButtonLoading(btn, false);
    }
});

document.getElementById('reportForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('reportBtn');
    try {
        setButtonLoading(btn, true, 'Generating…');
        await api('/reports/generate', {
            method: 'POST',
            body: JSON.stringify({
                month: Number(document.getElementById('reportMonth').value),
                year: Number(document.getElementById('reportYear').value)
            })
        });
        showAlert(alertEl, 'Report generated!', 'success');
        showSection('reports');
        await loadDashboard();
    } catch (err) {
        showAlert(alertEl, err.message);
    } finally {
        setButtonLoading(btn, false);
    }
});

if (user.role === 'admin') {
    document.getElementById('studentSearch').addEventListener('input', renderDirectory);

    document.getElementById('studentForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = document.getElementById('studentBtn');
        try {
            setButtonLoading(btn, true, 'Adding…');
            await api('/admin/students', {
                method: 'POST',
                body: JSON.stringify({
                    name: document.getElementById('studentName').value,
                    roll_no: document.getElementById('studentRoll').value,
                    email: document.getElementById('studentEmail').value
                })
            });
            e.target.reset();
            showAlert(alertEl, 'Student account added', 'success');
            await loadDirectory();
        } catch (err) {
            showAlert(alertEl, err.message);
        } finally {
            setButtonLoading(btn, false);
        }
    });

    document.getElementById('workerForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = document.getElementById('workerBtn');
        try {
            setButtonLoading(btn, true, 'Adding…');
            await api('/admin/workers', {
                method: 'POST',
                body: JSON.stringify({
                    name: document.getElementById('workerName').value,
                    roll_no: document.getElementById('workerRoll').value,
                    email: document.getElementById('workerEmail').value,
                    specialization: document.getElementById('workerSpecialization').value
                })
            });
            e.target.reset();
            showAlert(alertEl, 'Worker account and profile added', 'success');
            await Promise.all([loadDirectory(), loadDashboard()]);
        } catch (err) {
            showAlert(alertEl, err.message);
        } finally {
            setButtonLoading(btn, false);
        }
    });

    document.getElementById('locationForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = document.getElementById('locationBtn');
        try {
            setButtonLoading(btn, true, 'Adding…');
            await api('/admin/locations', {
                method: 'POST',
                body: JSON.stringify({
                    building: document.getElementById('locationBuilding').value,
                    floor: document.getElementById('locationFloor').value,
                    room_no: document.getElementById('locationRoom').value,
                    location_type: document.getElementById('locationType').value
                })
            });
            e.target.reset();
            showAlert(alertEl, 'Campus location added', 'success');
            await loadDirectory();
        } catch (err) {
            showAlert(alertEl, err.message);
        } finally {
            setButtonLoading(btn, false);
        }
    });

    document.getElementById('studentCsv').addEventListener('change', async (e) => {
        const file = e.target.files[0];
        const preview = document.getElementById('csvPreview');
        const importBtn = document.getElementById('importCsvBtn');
        csvStudents = [];
        importBtn.disabled = true;
        preview.hidden = true;
        document.getElementById('csvResult').innerHTML = '';
        if (!file) return;

        try {
            csvStudents = parseCsv(await file.text());
            if (csvStudents.length > 2000) throw new Error('CSV is limited to 2,000 students');
            preview.hidden = false;
            preview.innerHTML = `<strong>${csvStudents.length} students ready</strong><br>
                <span style="color:var(--muted)">First row: ${escapeHtml(csvStudents[0]?.name || '—')} · ${escapeHtml(csvStudents[0]?.roll_no || '—')}</span>`;
            importBtn.disabled = csvStudents.length === 0;
        } catch (err) {
            showAlert(alertEl, err.message);
        }
    });

    document.getElementById('importCsvBtn').addEventListener('click', async () => {
        if (!csvStudents.length) return;
        const btn = document.getElementById('importCsvBtn');
        try {
            setButtonLoading(btn, true, 'Importing…');
            const result = await api('/admin/students/bulk', {
                method: 'POST',
                body: JSON.stringify({ students: csvStudents })
            });
            const errors = result.errors.slice(0, 5).map(item =>
                `<li>Row ${item.row}: ${escapeHtml(item.email)} — ${escapeHtml(item.error)}</li>`
            ).join('');
            document.getElementById('csvResult').innerHTML = `
                <div class="alert ${result.failed ? 'alert-error' : 'alert-success'}">
                    Inserted ${result.inserted} of ${result.total}; ${result.failed} failed.
                </div>
                ${errors ? `<ul class="chain-list">${errors}</ul>` : ''}`;
            csvStudents = [];
            document.getElementById('studentCsv').value = '';
            document.getElementById('csvPreview').hidden = true;
            await loadDirectory();
        } catch (err) {
            showAlert(alertEl, err.message);
        } finally {
            setButtonLoading(btn, false);
            btn.disabled = true;
        }
    });

    document.getElementById('downloadTemplateBtn').addEventListener('click', () => {
        const content = 'name,roll_no,email\nJohn Student,STU2026001,john.student@stu.edu\nJane Student,STU2026002,jane.student@stu.edu\n';
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([content], { type: 'text/csv' }));
        link.download = 'student-import-template.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    });
}

showSection('assign');
loadDashboard().catch(err => showAlert(alertEl, err.message));
