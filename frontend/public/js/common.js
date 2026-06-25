const API = '/api';

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
        const routes = {
            student: '/student.html',
            worker: '/worker.html',
            supervisor: '/admin.html',
            admin: '/admin.html'
        };
        window.location.href = routes[user.role] || '/';
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
    return `<span class="badge badge-${status}">${status.replace('_', ' ')}</span>`;
}

function formatDate(iso) {
    if (!iso) return '—';
    return new Date(iso).toLocaleString();
}

function showAlert(container, message, type = 'error') {
    container.innerHTML = `<div class="alert alert-${type}">${message}</div>`;
    setTimeout(() => { container.innerHTML = ''; }, 4000);
}

function initNavbar(pageTitle) {
    const user = getUser();
    const nav = document.getElementById('navbar');
    if (nav && user) {
        nav.innerHTML = `
            <h1>${pageTitle}</h1>
            <div class="user-info">
                <span>${user.name} (${user.role})</span>
                <button class="btn btn-secondary btn-sm" onclick="logout()">Logout</button>
            </div>`;
    }
}
