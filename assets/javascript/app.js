document.addEventListener('DOMContentLoaded', () => {
    // 登入功能
    const loginFormElement = document.getElementById('login-form');
    if (loginFormElement) {
        loginFormElement.addEventListener('submit', (event) => {
            event.preventDefault();
            const email = document.getElementById('login-email').value;
            const password = document.getElementById('login-password').value;

            fetch('/aonix/jsp/login.jsp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `email=${encodeURIComponent(email)}&password=${encodeURIComponent(password)}`
            })
            .then(response => response.text())
            .then(result => {
                if (result.trim() === 'success') {
                    window.location.href = '/aonix/pages/member.html';
                } else {
                    document.getElementById('login-error').textContent = result;
                }
            });
        });
    }

    // 註冊功能
    const registerFormElement = document.getElementById('register-form');
    if (registerFormElement) {
        registerFormElement.addEventListener('submit', (event) => {
            event.preventDefault();
            const email = document.getElementById('register-email').value;
            const password = document.getElementById('register-password').value;
            const confirm = document.getElementById('confirm-password').value;

            if (password !== confirm) {
                document.getElementById('register-error').textContent = "Passwords do not match.";
                return;
            }

            fetch('/aonix/jsp/register.jsp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `email=${encodeURIComponent(email)}&password=${encodeURIComponent(password)}`
            })
            .then(response => response.text())
            .then(result => {
                if (result.trim() === 'success') {
                    window.location.href = '/aonix/pages/login.html';
                } else {
                    document.getElementById('register-error').textContent = result;
                }
            });
        });
    }

    // 表單切換
    const showRegisterLink = document.getElementById('show-register');
    const showLoginLink = document.getElementById('show-login');
    const loginFormDiv = document.getElementById('login-form');
    const registerFormDiv = document.getElementById('register-form');

    const googleSignInButton = document.getElementById('google-signin');
    const githubSignInButton = document.getElementById('github-signin');
    const guestLoginButton = document.getElementById('guest-login');
    const divider = document.getElementById('divider');

    if (showRegisterLink && showLoginLink && loginFormDiv && registerFormDiv) {
        showRegisterLink.addEventListener('click', (e) => {
            e.preventDefault();
            loginFormDiv.classList.add('hidden');
            registerFormDiv.classList.remove('hidden');
            if (googleSignInButton) googleSignInButton.style.display = 'none';
            if (githubSignInButton) githubSignInButton.style.display = 'none';
            if (guestLoginButton) guestLoginButton.style.display = 'none';
            if (divider) divider.style.display = 'none';
        });
        showLoginLink.addEventListener('click', (e) => {
            e.preventDefault();
            registerFormDiv.classList.add('hidden');
            loginFormDiv.classList.remove('hidden');
            if (googleSignInButton) googleSignInButton.style.display = 'block';
            if (githubSignInButton) githubSignInButton.style.display = 'block';
            if (guestLoginButton) guestLoginButton.style.display = 'block';
            if (divider) divider.style.display = 'block';
        });
    }
});

// Toggle password visibility
document.querySelectorAll('.toggle-password').forEach(function (toggle) {
    toggle.addEventListener('click', function () {
        const input = this.previousElementSibling; 
        const icon = this.querySelector('iconify-icon');
        if (input.type === "password") {
            input.type = "text";
            icon.setAttribute('icon', 'mdi:eye');
        } else {
            input.type = "password";
            icon.setAttribute('icon', 'mdi:eye-off');
        }
    });
});

document.querySelectorAll('#guest-login').forEach(function (btn) {
    btn.addEventListener('click', function (e) {
        e.preventDefault();  // 防止表單送出或刷新
        window.location.href = '/aonix/pages/member.html';
    });
});

document.querySelectorAll('#guest-login').forEach(function (btn) {
    btn.addEventListener('click', function (e) {
        e.preventDefault();
        fetch('/aonix/jsp/guest_login.jsp')
            .then(resp => resp.text())
            .then(result => {
                if (result.trim() === 'success') {
                    window.location.href = '/aonix/pages/member.html';
                } else {
                    alert('訪客登入失敗，請重試！');
                }
            })
            .catch(error => {
                console.error('訪客登入錯誤:', error);
                alert('訪客登入請求失敗！');
            });
    });
});

