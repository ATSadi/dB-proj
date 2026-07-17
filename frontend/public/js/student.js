const user = requireAuth(['student']);
if (!user) throw new Error('unauthorized');

initNavbar('Student Portal');
const alertEl = document.getElementById('alert');

let allComplaints = [];
let statusFilter = '';
let searchQuery = '';
let feedbackComplaintId = null;
let selectedRating = 0;

async function loadLocations() {
    const locations = await api('/locations');
    const select = document.getElementById('locationId');
    select.innerHTML = locations.map(l =>
        `<option value="${l.location_id}">${escapeHtml(l.building)} / Floor ${escapeHtml(l.floor)} / ${escapeHtml(l.room_no)}</option>`
    ).join('');
}

function renderStats(complaints) {
    const open = complaints.filter(c => !['resolved', 'closed'].includes(c.status)).length;
    const awaiting = complaints.filter(c => c.status === 'resolved').length;
    const closed = complaints.filter(c => c.status === 'closed').length;
    document.getElementById('studentStats').innerHTML = `
        <div class="stat-card"><div class="value">${complaints.length}</div><div class="label">Total</div></div>
        <div class="stat-card accent-warning"><div class="value">${open}</div><div class="label">Open</div></div>
        <div class="stat-card accent-success"><div class="value">${awaiting}</div><div class="label">Awaiting rating</div></div>
        <div class="stat-card"><div class="value">${closed}</div><div class="label">Closed</div></div>`;
}

function filteredComplaints() {
    return allComplaints.filter(c => {
        if (statusFilter && c.status !== statusFilter) return false;
        if (!searchQuery) return true;
        const hay = `${c.category} ${c.building} ${c.room_no} ${c.description || ''}`.toLowerCase();
        return hay.includes(searchQuery);
    });
}

function slaCell(c) {
    const overdue = isOverdue(c.sla_deadline, c.status);
    const cls = overdue ? 'sla-warn' : 'sla-ok';
    return `<span class="${cls}" title="${formatDate(c.sla_deadline)}">${formatRelative(c.sla_deadline)}</span>`;
}

function actionCell(c) {
    if (c.status === 'resolved') {
        return `<button class="btn btn-sm btn-primary" onclick="openFeedback(${c.complaint_id})">Rate</button>`;
    }
    return '—';
}

function renderComplaints() {
    const complaints = filteredComplaints();
    const tbody = document.getElementById('complaintsBody');
    const cards = document.getElementById('complaintsCards');

    if (!complaints.length) {
        tbody.innerHTML = '<tr><td colspan="8" class="empty-state">No complaints match this filter</td></tr>';
        cards.innerHTML = '<div class="empty-state">No complaints match this filter</div>';
        return;
    }

    tbody.innerHTML = complaints.map(c => `
        <tr class="${isOverdue(c.sla_deadline, c.status) ? 'row-overdue' : ''}">
            <td>#${c.complaint_id}</td>
            <td>${escapeHtml(c.building)} ${escapeHtml(c.room_no)}</td>
            <td>${escapeHtml(c.category)}</td>
            <td>${badgePriority(c.priority)}</td>
            <td>${badgeStatus(c.status)}</td>
            <td>${slaCell(c)}</td>
            <td>${escapeHtml(c.worker_name || '—')}</td>
            <td>${actionCell(c)}</td>
        </tr>`).join('');

    cards.innerHTML = complaints.map(c => `
        <div class="complaint-card">
            <div class="title">#${c.complaint_id} · ${escapeHtml(c.category)}</div>
            <div class="sub">${escapeHtml(c.building)} ${escapeHtml(c.room_no)} · ${escapeHtml(c.worker_name || 'Unassigned')}</div>
            <div class="meta">${badgePriority(c.priority)} ${badgeStatus(c.status)} ${slaCell(c)}</div>
            <p class="sub">${escapeHtml((c.description || '').slice(0, 120))}${(c.description || '').length > 120 ? '…' : ''}</p>
            <div class="actions">${actionCell(c)}</div>
        </div>`).join('');
}

async function loadComplaints() {
    allComplaints = await api(`/complaints?student_id=${user.user_id}`);
    renderStats(allComplaints);
    renderComplaints();
}

window.openFeedback = (complaintId) => {
    feedbackComplaintId = complaintId;
    selectedRating = 0;
    document.getElementById('feedbackId').textContent = complaintId;
    document.getElementById('feedbackComment').value = '';
    document.querySelectorAll('#starRow .star-btn').forEach(b => b.classList.remove('active'));
    openModal('feedbackModal');
};

document.getElementById('starRow').addEventListener('click', (e) => {
    const btn = e.target.closest('.star-btn');
    if (!btn) return;
    selectedRating = Number(btn.dataset.rating);
    document.querySelectorAll('#starRow .star-btn').forEach(b => {
        b.classList.toggle('active', Number(b.dataset.rating) <= selectedRating);
    });
});

document.getElementById('cancelFeedback').addEventListener('click', () => closeModal('feedbackModal'));

document.getElementById('submitFeedback').addEventListener('click', async () => {
    const alertElLocal = alertEl;
    if (!selectedRating) {
        showAlert(alertElLocal, 'Select a rating from 1 to 5');
        return;
    }
    const btn = document.getElementById('submitFeedback');
    try {
        setButtonLoading(btn, true, 'Saving…');
        await api('/feedback', {
            method: 'POST',
            body: JSON.stringify({
                complaint_id: feedbackComplaintId,
                student_id: user.user_id,
                rating: selectedRating,
                comment: document.getElementById('feedbackComment').value.trim()
            })
        });
        closeModal('feedbackModal');
        showAlert(alertElLocal, 'Feedback submitted — thank you!', 'success');
        await loadComplaints();
    } catch (err) {
        showAlert(alertElLocal, err.message);
    } finally {
        setButtonLoading(btn, false);
    }
});

document.getElementById('statusFilters').addEventListener('click', (e) => {
    const chip = e.target.closest('.chip');
    if (!chip) return;
    statusFilter = chip.dataset.status;
    document.querySelectorAll('#statusFilters .chip').forEach(c => c.classList.toggle('active', c === chip));
    renderComplaints();
});

document.getElementById('searchBox').addEventListener('input', (e) => {
    searchQuery = e.target.value.trim().toLowerCase();
    renderComplaints();
});

document.getElementById('description').addEventListener('input', (e) => {
    document.getElementById('descCount').textContent = `${e.target.value.length} / 500`;
});

document.getElementById('complaintForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('submitBtn');
    try {
        setButtonLoading(btn, true, 'Submitting…');
        await api('/complaints', {
            method: 'POST',
            body: JSON.stringify({
                student_id: user.user_id,
                location_id: Number(document.getElementById('locationId').value),
                category: document.getElementById('category').value,
                priority: document.getElementById('priority').value,
                description: document.getElementById('description').value.trim()
            })
        });
        showAlert(alertEl, 'Complaint submitted successfully!', 'success');
        e.target.reset();
        document.getElementById('descCount').textContent = '0 / 500';
        await loadComplaints();
    } catch (err) {
        showAlert(alertEl, err.message);
    } finally {
        setButtonLoading(btn, false);
    }
});

document.getElementById('refreshBtn').addEventListener('click', () => loadComplaints().catch(err => showAlert(alertEl, err.message)));

loadLocations().catch(err => showAlert(alertEl, err.message));
loadComplaints().catch(err => showAlert(alertEl, err.message));
