async function doLogin(email, password, triggerBtn) {
    const alertEl = document.getElementById('alert');
    if (triggerBtn) setButtonLoading(triggerBtn, true, 'Signing in…');

    try {
        const { user, token } = await api('/login', {
            method: 'POST',
            body: JSON.stringify({ email, password })
        });

        setUser(user, token);
        window.location.href = ROLE_ROUTES[user.role] || '/';
    } finally {
        if (triggerBtn) setButtonLoading(triggerBtn, false);
    }
}

document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const alertEl = document.getElementById('alert');
    const btn = document.getElementById('loginBtn');

    if (!email.includes('@')) {
        showAlert(alertEl, 'Enter a valid campus email address');
        return;
    }

    try {
        await doLogin(email, password, btn);
    } catch (err) {
        showAlert(alertEl, err.message);
    }
});

document.getElementById('demoGrid').addEventListener('click', async (e) => {
    const card = e.target.closest('.role-card');
    if (!card) return;

    const email = card.dataset.email;
    document.getElementById('email').value = email;
    document.getElementById('password').value = 'Password123';
    sessionStorage.removeItem('user');

    const alertEl = document.getElementById('alert');
    try {
        card.classList.add('is-loading');
        card.disabled = true;
        await doLogin(email, 'Password123');
    } catch (err) {
        showAlert(alertEl, err.message);
        card.classList.remove('is-loading');
        card.disabled = false;
    }
});

document.getElementById('passwordToggle').addEventListener('click', () => {
    const input = document.getElementById('password');
    const button = document.getElementById('passwordToggle');
    const showing = input.type === 'text';
    input.type = showing ? 'password' : 'text';
    button.textContent = showing ? 'Show' : 'Hide';
    button.setAttribute('aria-label', showing ? 'Show password' : 'Hide password');
});

document.getElementById('forgotToggle').addEventListener('click', () => {
    const panel = document.getElementById('resetPanel');
    panel.hidden = !panel.hidden;
    if (!panel.hidden) {
        document.getElementById('resetEmail').value = document.getElementById('email').value.trim();
        document.getElementById('resetEmail').focus();
    }
});

document.getElementById('forgotForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('resetEmail').value.trim();
    const btn = document.getElementById('sendCodeBtn');
    try {
        setButtonLoading(btn, true, 'Generating…');
        const result = await api('/forgot-password', {
            method: 'POST',
            body: JSON.stringify({ email })
        });

        const resetForm = document.getElementById('resetForm');
        resetForm.hidden = false;
        document.getElementById('resetCodeNotice').innerHTML = result.demo_code
            ? `<strong>Local demo reset code: ${escapeHtml(result.demo_code)}</strong><br>
               <span style="color:var(--muted)">Expires in ${result.expires_in_minutes} minutes. In production this would be emailed.</span>`
            : escapeHtml(result.message);
        if (result.demo_code) document.getElementById('resetCode').value = result.demo_code;
    } catch (err) {
        showAlert(document.getElementById('alert'), err.message);
    } finally {
        setButtonLoading(btn, false);
    }
});

document.getElementById('resetForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const password = document.getElementById('newPassword').value;
    const confirm = document.getElementById('confirmPassword').value;
    if (password !== confirm) {
        showAlert(document.getElementById('alert'), 'Passwords do not match');
        return;
    }

    const btn = document.getElementById('resetPasswordBtn');
    try {
        setButtonLoading(btn, true, 'Updating…');
        await api('/reset-password', {
            method: 'POST',
            body: JSON.stringify({
                email: document.getElementById('resetEmail').value.trim(),
                code: document.getElementById('resetCode').value.trim(),
                new_password: password
            })
        });

        document.getElementById('email').value = document.getElementById('resetEmail').value.trim();
        document.getElementById('password').value = password;
        document.getElementById('resetPanel').hidden = true;
        e.target.reset();
        showAlert(document.getElementById('alert'), 'Password updated. Sign in with your new password.', 'success');
    } catch (err) {
        showAlert(document.getElementById('alert'), err.message);
    } finally {
        setButtonLoading(btn, false);
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
