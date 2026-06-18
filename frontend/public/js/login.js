document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('email').value.trim();
    const alertEl = document.getElementById('alert');

    try {
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
    } catch (err) {
        showAlert(alertEl, err.message);
    }
});

// Redirect if already logged in
const existing = getUser();
if (existing) {
    const routes = {
        student: '/student.html',
        worker: '/worker.html',
        supervisor: '/admin.html',
        admin: '/admin.html'
    };
    window.location.href = routes[existing.role] || '/';
}
