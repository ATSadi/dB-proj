const user = requireAuth(['worker']);
if (!user) throw new Error('unauthorized');

initNavbar('Worker Portal');
const alertEl = document.getElementById('alert');
const workerId = user.worker?.worker_id;

async function loadStats() {
    if (!user.worker) return;
    document.getElementById('workerStats').innerHTML = `
        <div class="stat-card"><div class="value">${user.worker.specialization}</div><div class="label">Specialization</div></div>
        <div class="stat-card"><div class="value">${user.worker.performance_score}</div><div class="label">Performance Score</div></div>
        <div class="stat-card"><div class="value">${user.worker.is_available === 'Y' ? 'Yes' : 'Busy'}</div><div class="label">Available</div></div>`;
}

async function loadComplaints() {
    if (!workerId) {
        document.getElementById('complaintsBody').innerHTML =
            '<tr><td colspan="7" class="empty-state">Worker profile not found</td></tr>';
        return;
    }

    const complaints = await api(`/complaints?worker_id=${workerId}`);
    const tbody = document.getElementById('complaintsBody');

    if (!complaints.length) {
        tbody.innerHTML = '<tr><td colspan="7" class="empty-state">No assigned complaints</td></tr>';
        return;
    }

    tbody.innerHTML = complaints.map(c => {
        const actions = [];
        if (c.status === 'assigned') {
            actions.push(`<button class="btn btn-sm btn-primary" onclick="updateStatus(${c.complaint_id}, 'in_progress')">Start</button>`);
        }
        if (c.status === 'in_progress') {
            actions.push(`<button class="btn btn-sm btn-primary" onclick="updateStatus(${c.complaint_id}, 'resolved')">Resolve</button>`);
        }

        return `
        <tr>
            <td>#${c.complaint_id}</td>
            <td>${c.building} ${c.room_no}</td>
            <td>${c.category}</td>
            <td>${badgePriority(c.priority)}</td>
            <td>${badgeStatus(c.status)}</td>
            <td>${formatDate(c.sla_deadline)}</td>
            <td>${actions.join(' ') || '—'}</td>
        </tr>`;
    }).join('');
}

window.updateStatus = async (id, status) => {
    try {
        await api(`/complaints/${id}/status`, {
            method: 'PATCH',
            body: JSON.stringify({ status })
        });
        showAlert(alertEl, `Status updated to ${status}`, 'success');
        loadComplaints();
    } catch (err) {
        showAlert(alertEl, err.message);
    }
};

loadStats();
loadComplaints();
