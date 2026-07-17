async function doLogin(email, triggerBtn) {
    const alertEl = document.getElementById('alert');
    if (triggerBtn) setButtonLoading(triggerBtn, true, 'Signing in…');

    try {
        const { user } = await api('/login', {
            method: 'POST',
            body: JSON.stringify({ email })
        });

        setUser(user);
        window.location.href = ROLE_ROUTES[user.role] || '/';
    } finally {
        if (triggerBtn) setButtonLoading(triggerBtn, false);
    }
}

document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('email').value.trim();
    const alertEl = document.getElementById('alert');
    const btn = document.getElementById('loginBtn');

    if (!email.includes('@')) {
        showAlert(alertEl, 'Enter a valid campus email address');
        return;
    }

    try {
        await doLogin(email, btn);
    } catch (err) {
        showAlert(alertEl, err.message);
    }
});

document.getElementById('demoGrid').addEventListener('click', async (e) => {
    const card = e.target.closest('.role-card');
    if (!card) return;

    const email = card.dataset.email;
    document.getElementById('email').value = email;
    sessionStorage.removeItem('user');

    const alertEl = document.getElementById('alert');
    try {
        card.classList.add('is-loading');
        card.disabled = true;
        await doLogin(email);
    } catch (err) {
        showAlert(alertEl, err.message);
        card.classList.remove('is-loading');
        card.disabled = false;
    }
});

const existing = getUser();
const sessionBanner = document.getElementById('sessionBanner');
if (existing && sessionBanner) {
    sessionBanner.hidden = false;
    sessionBanner.innerHTML = `
        <div class="session-banner-body">
            <p>Signed in as <strong>${escapeHtml(existing.name)}</strong>
            <span class="badge badge-assigned">${ROLE_LABELS[existing.role] || existing.role}</span></p>
            <div class="session-actions">
                <a class="btn btn-primary btn-sm" href="${ROLE_ROUTES[existing.role] || '/'}">Continue to portal</a>
                <button type="button" class="btn btn-secondary btn-sm" id="switchLogout">Switch account</button>
            </div>
        </div>`;
    document.getElementById('switchLogout').addEventListener('click', logout);
}
