const user = requireAuth(['student']);
if (!user) throw new Error('unauthorized');

initNavbar('Student Portal');
const alertEl = document.getElementById('alert');

async function loadLocations() {
    const locations = await api('/locations');
    const select = document.getElementById('locationId');
    select.innerHTML = locations.map(l =>
        `<option value="${l.location_id}">${l.building} / Floor ${l.floor} / ${l.room_no} (${l.location_type})</option>`
    ).join('');
}

async function loadComplaints() {
    const complaints = await api(`/complaints?student_id=${user.user_id}`);
    const tbody = document.getElementById('complaintsBody');

    if (!complaints.length) {
        tbody.innerHTML = '<tr><td colspan="7" class="empty-state">No complaints yet</td></tr>';
        return;
    }

    tbody.innerHTML = complaints.map(c => `
        <tr>
            <td>#${c.complaint_id}</td>
            <td>${c.building} ${c.room_no}</td>
            <td>${c.category}</td>
            <td>${badgePriority(c.priority)}</td>
            <td>${badgeStatus(c.status)}</td>
            <td>${formatDate(c.sla_deadline)}</td>
            <td>${c.status === 'resolved' ? `<button class="btn btn-sm btn-primary" onclick="openFeedback(${c.complaint_id})">Rate</button>` : '—'}</td>
        </tr>
    `).join('');
}

window.openFeedback = async (complaintId) => {
    const rating = prompt('Rate 1-5:');
    if (!rating || rating < 1 || rating > 5) return;
    const comment = prompt('Comment (optional):') || '';

    try {
        await api('/feedback', {
            method: 'POST',
            body: JSON.stringify({
                complaint_id: complaintId,
                student_id: user.user_id,
                rating: Number(rating),
                comment
            })
        });
        showAlert(alertEl, 'Feedback submitted!', 'success');
        loadComplaints();
    } catch (err) {
        showAlert(alertEl, err.message);
    }
};

document.getElementById('complaintForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
        await api('/complaints', {
            method: 'POST',
            body: JSON.stringify({
                student_id: user.user_id,
                location_id: Number(document.getElementById('locationId').value),
                category: document.getElementById('category').value,
                priority: document.getElementById('priority').value,
                description: document.getElementById('description').value
            })
        });
        showAlert(alertEl, 'Complaint submitted successfully!', 'success');
        e.target.reset();
        loadComplaints();
    } catch (err) {
        showAlert(alertEl, err.message);
    }
});

loadLocations();
loadComplaints();
