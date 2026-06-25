async function doLogin(email) {
    const alertEl = document.getElementById('alert');
    const { user } = await api('/login', {
        method: 'POST',
        body: JSON.stringify({ email })
    });

    setUser(user);

    const routes = {
        student: '/student.html',
        worker: '/worker.html',
        supervisor: '/admin.html',
        admin: '/admin.html'
    };
    window.location.href = routes[user.role] || '/';
}

document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('email').value.trim();
    const alertEl = document.getElementById('alert');

    try {
        await doLogin(email);
    } catch (err) {
        showAlert(alertEl, err.message);
    }
});

window.quickLogin = async (email) => {
    sessionStorage.removeItem('user');
    document.getElementById('email').value = email;
    const alertEl = document.getElementById('alert');
    try {
        await doLogin(email);
    } catch (err) {
        showAlert(alertEl, err.message);
    }
};

// Show who is logged in — do NOT auto-redirect (allows switching accounts)
const existing = getUser();
const sessionBanner = document.getElementById('sessionBanner');
if (existing && sessionBanner) {
    const routes = {
        student: '/student.html',
        worker: '/worker.html',
        supervisor: '/admin.html',
        admin: '/admin.html'
    };
    sessionBanner.innerHTML = `
        <p>Currently logged in as <strong>${existing.name}</strong> (${existing.role}).
        <a href="${routes[existing.role] || '/'}">Go to your portal</a>
        or logout to switch account.</p>
        <button type="button" class="btn btn-secondary btn-sm" onclick="logout()" style="margin-top:0.5rem">Logout</button>`;
    sessionBanner.style.display = 'block';
}
