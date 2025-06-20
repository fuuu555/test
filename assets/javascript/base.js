
// Dynamic loader
document.addEventListener("DOMContentLoaded", function () {
    fetch("/aonix/pages/header.html")
        .then(response => response.text())
        .then(data => {
            document.querySelector("header").innerHTML = data;
        });

    fetch("/aonix/pages/footer.html")
        .then(response => response.text())
        .then(data => {
            document.querySelector("footer").innerHTML = data;
        });

    fetch("/aonix/pages/base.html")
        .then(response => response.text())
        .then(data => {
            document.body.insertAdjacentHTML("afterbegin", data);

            // Add event listener for account icon after header is loaded
            document.getElementById("accountIcon").addEventListener("click", handleAccountRedirect);

            // Check for developer mode cookie and set stylesheet accordingly
            const developerMode = getCookie("developerMode");
            let link = document.querySelector('link[href="/aonix/assets/stylesheets/developer.css"]');
            if (!link) {
                link = document.createElement("link");
                link.rel = "stylesheet";
                link.href = "/aonix/assets/stylesheets/developer.css";
                document.head.appendChild(link);
            }
            link.disabled = developerMode !== "true";
            if (developerMode === "true") {
                document.head.appendChild(link); // Ensure developer.css is the last stylesheet
            }
        });
});

// Checks for user login status (HTML session check)
function handleAccountRedirect() {
    fetch('/aonix/jsp/check_login.jsp')
        .then(resp => resp.text())
        .then(result => {
            if (result.trim() === "logged_in") { // 這裡要和 check_login.jsp 回傳一致
                window.location.href = "/aonix/pages/member.html";
            } else {
                window.location.href = "/aonix/pages/login.html";
            }
        })
        .catch(() => {
            window.location.href = "/aonix/pages/login.html";
        });
}

// Toggle developer mode stylesheet
window.toggleDeveloperMode = function () {
    let link = document.querySelector('link[href="/aonix/assets/stylesheets/developer.css"]');
    if (!link) {
        link = document.createElement("link");
        link.rel = "stylesheet";
        link.href = "/aonix/assets/stylesheets/developer.css";
        document.head.appendChild(link);
    }
    link.disabled = !link.disabled;
    setCookie("developerMode", !link.disabled, 7);
    if (!link.disabled) {
        document.head.appendChild(link); // Ensure developer.css is the last stylesheet
    }
};

// Helper function to set a cookie
export function setCookie(name, value, days) {
    const date = new Date();
    date.setTime(date.getTime() + days * 24 * 60 * 60 * 1000);
    const expires = "expires=" + date.toUTCString();
    document.cookie = name + "=" + value + ";" + expires + ";path=/";
}

// Helper function to get a cookie
export function getCookie(name) {
    const nameEQ = name + "=";
    const ca = document.cookie.split(";");
    for (let i = 0; i < ca.length; i++) {
        let c = ca[i];
        while (c.charAt(0) === " ") c = c.substring(1, c.length);
        if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
    }
    return null;
}
