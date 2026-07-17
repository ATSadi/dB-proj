const user = requireAuth(['worker']);
if (!user) throw new Error('unauthorized');

initNavbar('Worker Portal');
const alertEl = document.getElementById('alert');
const workerId = user.worker?.worker_id;

let allJobs = [];
let jobFilter = 'active';

function renderStats() {
    if (!user.worker) return;
    const active = allJobs.filter(c => !['resolved', 'closed'].includes(c.status)).length;
    const overdue = allJobs.filter(c => isOverdue(c.sla_deadline, c.status)).length;
    const done = allJobs.filter(c => ['resolved', 'closed'].includes(c.status)).length;

    document.getElementById('workerStats').innerHTML = `
        <div class="stat-card"><div class="value">${escapeHtml(user.worker.specialization)}</div><div class="label">Specialization</div></div>
        <div class="stat-card"><div class="value">${Number(user.worker.performance_score).toFixed(1)}</div><div class="label">Performance</div></div>
        <div class="stat-card accent-warning"><div class="value">${active}</div><div class="label">Active jobs</div></div>
        <div class="stat-card accent-danger"><div class="value">${overdue}</div><div class="label">Overdue</div></div>
        <div class="stat-card accent-success"><div class="value">${done}</div><div class="label">Completed</div></div>
        <div class="stat-card"><div class="value">${user.worker.is_available === 'Y' ? 'Yes' : 'Busy'}</div><div class="label">Available</div></div>`;
}

function filteredJobs() {
    return allJobs.filter(c => {
        const done = ['resolved', 'closed'].includes(c.status);
        if (jobFilter === 'active') return !done;
        if (jobFilter === 'done') return done;
        return true;
    });
}

function slaCell(c) {
    const overdue = isOverdue(c.sla_deadline, c.status);
    return `<span class="${overdue ? 'sla-warn' : 'sla-ok'}" title="${formatDate(c.sla_deadline)}">${formatRelative(c.sla_deadline)}</span>`;
}

function actionButtons(c) {
    const actions = [];
    if (c.status === 'assigned') {
        actions.push(`<button class="btn btn-sm btn-primary" onclick="updateStatus(${c.complaint_id}, 'in_progress')">Start</button>`);
    }
    if (c.status === 'in_progress') {
        actions.push(`<button class="btn btn-sm btn-success" onclick="updateStatus(${c.complaint_id}, 'resolved')">Resolve</button>`);
    }
    return actions.join(' ') || '—';
}

function renderJobs() {
    const jobs = filteredJobs();
    const tbody = document.getElementById('complaintsBody');
    const cards = document.getElementById('complaintsCards');

    if (!jobs.length) {
        tbody.innerHTML = '<tr><td colspan="8" class="empty-state">No jobs in this view</td></tr>';
        cards.innerHTML = '<div class="empty-state">No jobs in this view</div>';
        return;
    }

    tbody.innerHTML = jobs.map(c => `
        <tr class="${isOverdue(c.sla_deadline, c.status) ? 'row-overdue' : ''}">
            <td>#${c.complaint_id}</td>
            <td>${escapeHtml(c.building)} ${escapeHtml(c.room_no)}</td>
            <td>${escapeHtml(c.category)}</td>
            <td>${badgePriority(c.priority)}</td>
            <td>${badgeStatus(c.status)}</td>
            <td>${slaCell(c)}</td>
            <td>${escapeHtml(c.student_name || '—')}</td>
            <td>${actionButtons(c)}</td>
        </tr>`).join('');

    cards.innerHTML = jobs.map(c => `
        <div class="complaint-card">
            <div class="title">#${c.complaint_id} · ${escapeHtml(c.category)}</div>
            <div class="sub">${escapeHtml(c.building)} ${escapeHtml(c.room_no)} · ${escapeHtml(c.student_name || 'Student')}</div>
            <div class="meta">${badgePriority(c.priority)} ${badgeStatus(c.status)} ${slaCell(c)}</div>
            <p class="sub">${escapeHtml((c.description || '').slice(0, 140))}</p>
            <div class="actions">${actionButtons(c)}</div>
        </div>`).join('');
}

async function loadComplaints() {
    if (!workerId) {
        document.getElementById('complaintsBody').innerHTML =
            '<tr><td colspan="8" class="empty-state">Worker profile not found</td></tr>';
        return;
    }

    allJobs = await api(`/complaints?worker_id=${workerId}`);
    renderStats();
    renderJobs();
}

window.updateStatus = async (id, status) => {
    try {
        await api(`/complaints/${id}/status`, {
            method: 'PATCH',
            body: JSON.stringify({ status })
        });
        showAlert(alertEl, `Status updated to ${status.replace('_', ' ')}`, 'success');
        await loadComplaints();
    } catch (err) {
        showAlert(alertEl, err.message);
    }
};

document.getElementById('jobFilters').addEventListener('click', (e) => {
    const chip = e.target.closest('.chip');
    if (!chip) return;
    jobFilter = chip.dataset.filter;
    document.querySelectorAll('#jobFilters .chip').forEach(c => c.classList.toggle('active', c === chip));
    renderJobs();
});

document.getElementById('refreshBtn').addEventListener('click', () => {
    loadComplaints().catch(err => showAlert(alertEl, err.message));
});

document.getElementById('toggleAvailBtn').addEventListener('click', async () => {
    if (!workerId || !user.worker) return;
    const next = user.worker.is_available === 'Y' ? 'N' : 'Y';
    const btn = document.getElementById('toggleAvailBtn');
    try {
        setButtonLoading(btn, true, 'Updating…');
        const result = await api(`/workers/${workerId}/availability`, {
            method: 'PATCH',
            body: JSON.stringify({ is_available: next })
        });
        user.worker.is_available = result.is_available;
        setUser(user);
        showAlert(alertEl, `Availability set to ${next === 'Y' ? 'available' : 'busy'}`, 'success');
        renderStats();
    } catch (err) {
        showAlert(alertEl, err.message);
    } finally {
        setButtonLoading(btn, false);
    }
});

loadComplaints().catch(err => showAlert(alertEl, err.message));
