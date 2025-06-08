// member.js
document.addEventListener("DOMContentLoaded", () => {
    const menuItems = document.querySelectorAll(".menu-item");
    const contentArea = document.querySelector(".preferences-content");

    // 檢查用戶登錄狀態
    fetch('/aonix/jsp/check_login.jsp')
        .then(resp => resp.text())
        .then(result => {
            if (result.trim() !== "logged_in") {
                window.location.href = "/aonix/pages/login.html";
            }
        })
        .catch(error => {
            console.error("Error checking login status:", error);
            window.location.href = "/aonix/pages/login.html";
        });

    // 加載訂單歷史
    async function loadShoppingHistory(userId) {
        try {
            const response = await fetch(`/aonix/jsp/get_orders.jsp?userId=${encodeURIComponent(userId)}`);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const orders = await response.json();
            const shoppingHistoryContainer = document.getElementById("shopping-history");

            if (!orders || orders.length === 0) {
                shoppingHistoryContainer.textContent = "No orders found";
                return;
            }

            shoppingHistoryContainer.innerHTML = "";
            orders.sort((a, b) => new Date(b.order_date) - new Date(a.order_date));

            for (const order of orders) {
                const orderDiv = document.createElement("div");
                orderDiv.classList.add("order");

                const orderHeader = document.createElement("div");
                orderHeader.classList.add("order-header");
                orderHeader.textContent = `Order Date: ${new Date(order.order_date).toLocaleString()}`;
                orderDiv.appendChild(orderHeader);

                const orderItemsDiv = document.createElement("div");
                orderItemsDiv.classList.add("order-items");

                order.items.forEach(item => {
                    const historyItem = document.createElement("div");
                    historyItem.innerHTML = `
                        <a href="/aonix/pages/product_review.html?id=${item.product_id}">${item.item_name}</a>
                        <a href="/aonix/pages/product_review.html?id=${item.product_id}">
                            <img src="${item.image_url || '/aonix/images/default_product.png'}" alt="${item.item_name}">
                        </a>`;
                    orderItemsDiv.appendChild(historyItem);
                });

                orderDiv.appendChild(orderItemsDiv);
                shoppingHistoryContainer.appendChild(orderDiv);
            }
        } catch (error) {
            console.error("Error loading orders:", error);
            document.getElementById("shopping-history").textContent = "Error loading orders";
        }
    }

    // 加載評論歷史
    function createReviewItem(review, productName, reviewDate) {
        const reviewItem = document.createElement("div");
        reviewItem.classList.add("review-item");

        const stars = Array(5).fill('').map((_, i) => `
            <iconify-icon 
                icon="${i < review.rating ? 'mdi:star' : 'mdi:star-outline'}"
                width="20" 
                height="20"
            ></iconify-icon>
        `).join('');

        reviewItem.innerHTML = `
            <div class="review-header">
                <div class="review-product">${productName}</div>
                <div class="review-date">${reviewDate}</div>
            </div>
            <div class="review-rating">${stars}</div>
            <div class="review-text">${review.content}</div>
        `;
        return reviewItem;
    }

    async function loadReviewHistory(userId) {
        try {
            const response = await fetch(`/aonix/jsp/get_user_reviews.jsp?userId=${encodeURIComponent(userId)}`);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const reviews = await response.json();
            const reviewsContainer = document.getElementById("reviews");

            if (!reviews || reviews.length === 0) {
                reviewsContainer.innerHTML = '<div class="no-reviews">No reviews yet</div>';
                return;
            }

            reviewsContainer.innerHTML = "";
            reviews.sort((a, b) => new Date(b.date) - new Date(a.date));

            for (const review of reviews) {
                const reviewDate = new Date(review.date).toLocaleString();
                const reviewItem = createReviewItem(review, review.product_name, reviewDate);
                reviewsContainer.appendChild(reviewItem);
            }
        } catch (error) {
            console.error("Error loading reviews:", error);
            document.getElementById("reviews").innerHTML = '<div class="error">Error loading reviews</div>';
        }
    }

    // 顯示個人資料
    async function showProfile() {
        contentArea.innerHTML = `
            <h2>Profile</h2>
            <div class="profile-info">
                <div class="image-box"><img id="user-photo" alt="User Photo" draggable="false"></div>
                <div class="profile-details">
                    <label for="user-displayName">Display Name:</label>
                    <div class="input-container">
                        <input type="text" id="user-displayName" disabled>
                        <button id="edit-displayName-button">
                            <iconify-icon icon="lucide:edit"></iconify-icon>
                        </button>
                        <button id="save-displayName-button" style="display:none;">
                            <iconify-icon icon="mdi:content-save"></iconify-icon>
                        </button>
                    </div>
                    <label for="user-email">Email:</label>
                    <div class="input-container">
                        <input type="text" id="user-email" disabled>
                        <button id="edit-email-button">
                            <iconify-icon icon="lucide:edit"></iconify-icon>
                        </button>
                        <button id="save-email-button" style="display:none;">
                            <iconify-icon icon="mdi:content-save"></iconify-icon>
                        </button>
                    </div>
                    <label for="user-uid">UID:</label>
                    <div class="input-container">
                        <input type="text" id="user-uid" disabled>
                    </div>
                    <label for="user-photoURL">Photo URL:</label>
                    <div class="input-container">
                        <input type="text" id="user-photoURL" disabled>
                        <button id="edit-photoURL-button">
                            <iconify-icon icon="lucide:edit"></iconify-icon>
                        </button>
                        <button id="save-photoURL-button" style="display:none;">
                            <iconify-icon icon="mdi:content-save"></iconify-icon>
                        </button>
                    </div>
                </div>
            </div>
        `;

        try {
            const response = await fetch('/aonix/jsp/get_profile.jsp');
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const user = await response.json();

            const uidInput = document.getElementById("user-uid");
            const displayNameInput = document.getElementById("user-displayName");
            const photoURLInput = document.getElementById("user-photoURL");
            const emailInput = document.getElementById("user-email");

            uidInput.value = user.id || '';
            emailInput.value = user.email || '';
            displayNameInput.value = user.displayName || '';
            photoURLInput.value = user.photoURL || '';
            document.getElementById("user-photo").src = user.photoURL || '/aonix/images/default_user.png';

            // 附加編輯與儲存功能
            attachEditSaveFunctionality("displayName", displayNameInput);
            attachEditSaveFunctionality("photoURL", photoURLInput);
            attachEditSaveFunctionality("email", emailInput);
        } catch (error) {
            console.error("Error loading profile:", error);
            contentArea.innerHTML += '<div class="error">Error loading profile</div>';
        }
    }

    function attachEditSaveFunctionality(field, inputElement) {
        const editButton = document.getElementById(`edit-${field}-button`);
        const saveButton = document.getElementById(`save-${field}-button`);

        if (editButton && saveButton) {
            editButton.addEventListener("click", () => {
                inputElement.disabled = false;
                inputElement.style.border = "1px solid red";
                inputElement.style.cursor = "text";
                editButton.style.display = "none";
                saveButton.style.display = "inline";
            });

            saveButton.addEventListener("click", async () => {
                const newValue = inputElement.value;
                try {
                    const response = await fetch('/aonix/jsp/update_profile.jsp', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ field, value: newValue })
                    });
                    if (!response.ok) throw new Error(`HTTP ${response.status}`);
                    const result = await response.json();
                    if (result.status === "success") {
                        inputElement.disabled = true;
                        inputElement.style.border = "";
                        inputElement.style.cursor = "not-allowed";
                        editButton.style.display = "inline";
                        saveButton.style.display = "none";
                    } else {
                        alert(`Failed to update ${field}: ${result.message}`);
                    }
                } catch (error) {
                    console.error(`Error updating ${field}:`, error);
                    alert(`Error updating ${field}`);
                }
            });
        }
    }

    // 顯示訂單頁面
    function showOrders() {
        contentArea.innerHTML = `
            <h2>Orders</h2>
            <div id="shopping-history" class="shopping-history-container"></div>
        `;
        fetch('/aonix/jsp/get_user_id.jsp')
            .then(resp => {
                if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
                return resp.json();
            })
            .then(data => {
                if (data.userId) {
                    loadShoppingHistory(data.userId);
                } else {
                    throw new Error("User ID not found");
                }
            })
            .catch(error => {
                console.error("Error fetching user ID:", error);
                document.getElementById("shopping-history").textContent = "Error loading orders";
            });
    }

    // 顯示評論頁面
    function showReviews() {
        contentArea.innerHTML = `
            <h2>Reviews</h2>
            <div id="reviews" class="reviews-container"></div>
        `;
        fetch('/aonix/jsp/get_user_id.jsp')
            .then(resp => {
                if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
                return resp.json();
            })
            .then(data => {
                if (data.userId) {
                    loadReviewHistory(data.userId);
                } else {
                    throw new Error("User ID not found");
                }
            })
            .catch(error => {
                console.error("Error fetching user ID:", error);
                document.getElementById("reviews").textContent = "Error loading reviews";
            });
    }

    // 顯示 My Cards 頁面
    function showMyProfile() {
        contentArea.innerHTML = `
            <h2>My Cards</h2>
            <div class="my-profile-info">
                <!-- Add profile content here -->
            </div>
        `;
    }

    // 選單點擊事件
    menuItems.forEach(item => {
        item.addEventListener("click", () => {
            menuItems.forEach(i => i.classList.remove("active"));
            item.classList.add("active");

            const content = item.querySelector("span").textContent;
            switch (content) {
                case "Profile":
                    showProfile();
                    break;
                case "Orders":
                    showOrders();
                    break;
                case "Reviews":
                    showReviews();
                    break;
                case "My Cards":
                    showMyProfile();
                    break;
            }
        });
    });

    // 登出功能
    const logoutButton = document.getElementById("logout-button");
    if (logoutButton) {
        logoutButton.addEventListener("click", async () => {
            try {
                const response = await fetch('/aonix/jsp/logout.jsp');
                const result = await response.text();
                if (result.trim() === "success") {
                    window.location.href = "/aonix/pages/login.html";
                } else {
                    alert("Logout failed!");
                }
            } catch (error) {
                console.error("Error logging out:", error);
                alert("Logout request error!");
            }
        });
    }

    // 預設顯示 Profile 頁面
    if (menuItems.length > 0) {
        menuItems[0].click();
    }
});