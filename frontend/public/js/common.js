const API = '/api';

const ROLE_ROUTES = {
    student: '/student.html',
    worker: '/worker.html',
    supervisor: '/admin.html',
    admin: '/admin.html'
};

const ROLE_LABELS = {
    student: 'Student',
    worker: 'Worker',
    supervisor: 'Supervisor',
    admin: 'Admin'
};

function getUser() {
    const data = sessionStorage.getItem('user');
    return data ? JSON.parse(data) : null;
}

function setUser(user) {
    sessionStorage.setItem('user', JSON.stringify(user));
}

function logout() {
    sessionStorage.removeItem('user');
    window.location.href = '/';
}

function requireAuth(allowedRoles) {
    const user = getUser();
    if (!user) {
        window.location.href = '/?login=1';
        return null;
    }
    if (allowedRoles && !allowedRoles.includes(user.role)) {
        window.location.href = ROLE_ROUTES[user.role] || '/';
        return null;
    }
    return user;
}

async function api(path, options = {}) {
    const res = await fetch(API + path, {
        headers: { 'Content-Type': 'application/json', ...options.headers },
        ...options
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.error || 'Request failed');
    return data;
}

function badgePriority(priority) {
    return `<span class="badge badge-${priority}">${priority}</span>`;
}

function badgeStatus(status) {
    return `<span class="badge badge-${status}">${String(status).replace('_', ' ')}</span>`;
}

function formatDate(iso) {
    if (!iso) return '—';
    return new Date(iso).toLocaleString();
}

function formatRelative(iso) {
    if (!iso) return '—';
    const diff = new Date(iso) - Date.now();
    const abs = Math.abs(diff);
    const hrs = Math.round(abs / 3600000);
    const mins = Math.round(abs / 60000);
    if (diff < 0) {
        if (hrs >= 24) return `${Math.round(hrs / 24)}d overdue`;
        if (hrs >= 1) return `${hrs}h overdue`;
        return `${mins}m overdue`;
    }
    if (hrs >= 24) return `${Math.round(hrs / 24)}d left`;
    if (hrs >= 1) return `${hrs}h left`;
    return `${mins}m left`;
}

function isOverdue(iso, status) {
    if (!iso || ['resolved', 'closed'].includes(status)) return false;
    return new Date(iso) < new Date();
}

function showAlert(container, message, type = 'error') {
    if (!container) return;
    container.innerHTML = `<div class="alert alert-${type}">${message}</div>`;
    setTimeout(() => { container.innerHTML = ''; }, 4000);
}

function setButtonLoading(btn, loading, label = 'Please wait…') {
    if (!btn) return;
    if (loading) {
        btn.dataset.label = btn.innerHTML;
        btn.disabled = true;
        btn.classList.add('is-loading');
        btn.innerHTML = `<span class="spinner"></span> ${label}`;
    } else {
        btn.disabled = false;
        btn.classList.remove('is-loading');
        btn.innerHTML = btn.dataset.label || btn.innerHTML;
    }
}

function escapeHtml(str) {
    return String(str ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function initNavbar(pageTitle) {
    const user = getUser();
    const nav = document.getElementById('navbar');
    if (!nav || !user) return;

    nav.innerHTML = `
        <div class="nav-left">
            <button type="button" class="nav-toggle" id="navToggle" aria-label="Menu">☰</button>
            <h1>${pageTitle}</h1>
        </div>
        <div class="user-info" id="navMenu">
            <span class="user-chip">${escapeHtml(user.name)} · ${ROLE_LABELS[user.role] || user.role}</span>
            <a class="nav-link" href="${ROLE_ROUTES[user.role] || '/'}">Dashboard</a>
            <button class="btn btn-secondary btn-sm" onclick="logout()">Logout</button>
        </div>`;

    const toggle = document.getElementById('navToggle');
    const menu = document.getElementById('navMenu');
    if (toggle && menu) {
        toggle.addEventListener('click', () => menu.classList.toggle('open'));
    }
}

function openModal(id) {
    const el = document.getElementById(id);
    if (el) el.classList.add('open');
}

function closeModal(id) {
    const el = document.getElementById(id);
    if (el) el.classList.remove('open');
}
