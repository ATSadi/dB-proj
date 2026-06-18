const user = requireAuth(['admin', 'supervisor']);
if (!user) throw new Error('unauthorized');

initNavbar('Admin Dashboard');
const alertEl = document.getElementById('alert');

async function loadDashboard() {
    const [dash, reports, submitted] = await Promise.all([
        api('/dashboard'),
        api('/reports'),
        api('/complaints?status=submitted')
    ]);

    document.getElementById('dashStats').innerHTML = `
        <div class="stat-card"><div class="value">${dash.overdue.length}</div><div class="label">Overdue</div></div>
        <div class="stat-card"><div class="value">${dash.chronic.length}</div><div class="label">Chronic Issues</div></div>
        <div class="stat-card"><div class="value">${dash.workers.length}</div><div class="label">Workers</div></div>
        <div class="stat-card"><div class="value">${submitted.length}</div><div class="label">Awaiting Assignment</div></div>`;

    document.getElementById('overdueBody').innerHTML = dash.overdue.length
        ? dash.overdue.map(r => `
            <tr>
                <td>#${r.complaint_id}</td>
                <td>${r.category}</td>
                <td>${badgePriority(r.priority)}</td>
                <td>${r.hours_overdue}h</td>
                <td>${r.building} ${r.room_no}</td>
                <td>${r.worker_name || '—'}</td>
            </tr>`).join('')
        : '<tr><td colspan="6" class="empty-state">No overdue complaints</td></tr>';

    document.getElementById('workersBody').innerHTML = dash.workers.map(w => `
        <tr>
            <td>${w.worker_name}</td>
            <td>${w.specialization}</td>
            <td>${w.calculated_score ?? w.cached_score}</td>
            <td>${w.open_assignments}</td>
            <td>${w.completed_assignments}</td>
            <td>${w.overdue_count}</td>
            <td>${w.is_available === 'Y' ? 'Yes' : 'No'}</td>
        </tr>`).join('');

    document.getElementById('chronicBody').innerHTML = dash.chronic.length
        ? dash.chronic.map(c => `
            <tr>
                <td>${c.building} / ${c.room_no}</td>
                <td>${c.category}</td>
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

    const workers = await api('/workers');
    document.getElementById('assignWorker').innerHTML = workers.map(w =>
        `<option value="${w.worker_id}">${w.name} (${w.specialization}) ${w.is_available === 'Y' ? '' : '[busy]'}</option>`
    ).join('');

    document.getElementById('assignComplaint').innerHTML = submitted.length
        ? submitted.map(c =>
            `<option value="${c.complaint_id}">#${c.complaint_id} — ${c.category} @ ${c.building} ${c.room_no}</option>`
        ).join('')
        : '<option value="">No submitted complaints</option>';
}

document.getElementById('assignForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const complaintId = document.getElementById('assignComplaint').value;
    if (!complaintId) return;

    try {
        await api('/assignments', {
            method: 'POST',
            body: JSON.stringify({
                complaint_id: Number(complaintId),
                worker_id: Number(document.getElementById('assignWorker').value),
                supervisor_id: user.user_id
            })
        });
        showAlert(alertEl, 'Worker assigned successfully!', 'success');
        loadDashboard();
    } catch (err) {
        showAlert(alertEl, err.message);
    }
});

document.getElementById('reportForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
        await api('/reports/generate', {
            method: 'POST',
            body: JSON.stringify({
                month: Number(document.getElementById('reportMonth').value),
                year: Number(document.getElementById('reportYear').value)
            })
        });
        showAlert(alertEl, 'Report generated!', 'success');
        loadDashboard();
    } catch (err) {
        showAlert(alertEl, err.message);
    }
});

loadDashboard();
