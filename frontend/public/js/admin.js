const user = requireAuth(['admin', 'supervisor']);
if (!user) throw new Error('unauthorized');

initNavbar(user.role === 'admin' ? 'Admin Dashboard' : 'Supervisor Dashboard');
const alertEl = document.getElementById('alert');

let queueComplaints = [];
let submitted = [];

const now = new Date();
document.getElementById('reportMonth').value = now.getMonth() + 1;
document.getElementById('reportYear').value = now.getFullYear();

function showSection(name) {
    document.querySelectorAll('.dash-section').forEach(el => {
        el.hidden = el.id !== `section-${name}`;
    });
    document.querySelectorAll('#sectionTabs .chip').forEach(chip => {
        chip.classList.toggle('active', chip.dataset.section === name);
    });
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

showSection('assign');
loadDashboard().catch(err => showAlert(alertEl, err.message));
