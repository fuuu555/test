// =================== 購物車功能 cart.js ===================

// [0] 更新購物車數量顯示（獨立函數）
window.updateCartCount = async function() {
    const cartCount = document.getElementById("cartCount");
    if (!cartCount) return;

    try {
        const res = await fetch('/aonix/jsp/cart_list.jsp');
        if (!res.ok) throw new Error("無法取得購物車：" + res.status);
        const data = await res.json();
        if (data.status === "success" && data.items) {
            const count = data.items.reduce((sum, item) => sum + item.quantity, 0);
            cartCount.textContent = count.toString();
        } else {
            cartCount.textContent = "0";
        }
    } catch (e) {
        cartCount.textContent = "0";
        console.error("更新購物車數量失敗:", e);
    }
};

// [1] 加入購物車（主全域 function，只這裡宣告！）
window.addToCart = async function(productId, quantity = 1) {
    try {
        const res = await fetch('/aonix/jsp/cart_add.jsp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({ productId, quantity })
        });
        if (!res.ok) throw new Error("API 回傳錯誤：" + res.status);
        const data = await res.json();
        if (data.status === 'success') {
            await updateCartDisplay();
            await updateCartCount(); // 更新 header 的 cartCount
            alert("已加入購物車！");
        } else if (data.status === 'error' && data.message === '請先登入') {
            alert("請先登入會員才能加入購物車！");
            window.location.href = "/aonix/pages/login.html";
        } else {
            alert(data.message || "加入購物車失敗！");
        }
    } catch (e) {
        alert("加入購物車時發生錯誤：" + (e.message || e));
    }
};

// [2] 移除購物車商品
window.removeFromCart = async function(productId) {
    try {
        await fetch('/aonix/jsp/cart_remove.jsp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({ productId })
        });
        await updateCartDisplay();
        await updateCartCount(); // 更新 header 的 cartCount
    } catch (e) {
        alert("移除購物車時發生錯誤：" + (e.message || e));
    }
};

// [3] 調整購物車清單商品數量
window.updateQuantity = async function(productId, delta) {
    try {
        const resList = await fetch('/aonix/jsp/cart_list.jsp');
        if (!resList.ok) throw new Error("無法取得購物車清單：" + resList.status);
        const cart = await resList.json();
        if (!cart.items) return;
        const item = cart.items.find(i => i.productId === productId);
        if (!item) return;
        let newQty = item.quantity + delta;
        if (newQty <= 0) {
            await window.removeFromCart(productId);
            return;
        }
        await fetch('/aonix/jsp/cart_update.jsp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({ productId, quantity: newQty })
        });
        await updateCartDisplay();
        await updateCartCount(); // 更新 header 的 cartCount
    } catch (e) {
        alert("更新數量時發生錯誤：" + (e.message || e));
    }
};

// [4] 顯示購物車內容（購物車彈窗/Bar）
window.updateCartDisplay = async function() {
    const cartItems = document.getElementById("cartItems");
    const cartCount = document.getElementById("cartCount");
    const cartTotal = document.getElementById("cartTotal");
    if (!cartItems || !cartCount || !cartTotal) return;

    try {
        const res = await fetch('/aonix/jsp/cart_list.jsp');
        if (!res.ok) throw new Error("無法取得購物車：" + res.status);
        const data = await res.json();
        if (data.status !== "success" || !data.items || !data.items.length) {
            cartItems.innerHTML = `<div class="empty-cart">
                <iconify-icon icon="mdi:cart-off"></iconify-icon>
                <p>您的購物車是空的</p></div>`;
            cartCount.textContent = "0";
            cartTotal.textContent = "0";
            return;
        }
        let total = 0, count = 0, html = "";
        for (const item of data.items) {
            total += Number(item.price) * item.quantity;
            count += item.quantity;
            html += `<div class="cart-item">
                <img src="${item.image || '/imgs/no-image.png'}" alt="${item.name}">
                <div class="cart-item-info">
                    <h7>${item.name}</h7>
                    <div class="price-quantity">
                        <span class="price">$${Number(item.price).toLocaleString()}</span>
                        <div class="quantity-controls">
                            <button onclick="updateQuantity('${item.productId}', -1)">-</button>
                            <span>${item.quantity}</span>
                            <button onclick="updateQuantity('${item.productId}', 1)">+</button>
                        </div>
                    </div>
                </div>
                <button class="remove-item" onclick="removeFromCart('${item.productId}')">
                    <iconify-icon icon="mdi:delete"></iconify-icon>
                </button>
            </div>`;
        }
        cartItems.innerHTML = html;
        cartCount.textContent = count;
        cartTotal.textContent = total.toLocaleString();
        await updateCartCount(); // 確保 header 的 cartCount 與彈窗一致
    } catch (e) {
        if (cartItems) cartItems.innerHTML = `<div class="empty-cart">載入購物車失敗</div>`;
        if (cartCount) cartCount.textContent = "0";
        if (cartTotal) cartTotal.textContent = "0";
    }
};

// [5] 結帳
window.checkout = async function() {
    try {
        const res = await fetch('/aonix/jsp/cart_checkout.jsp', { method: 'POST' });
        if (!res.ok) throw new Error("API 錯誤：" + res.status);
        const data = await res.json();
        if (data.status === 'success') {
            alert(`訂單成立！`);
            await updateCartDisplay();
            await updateCartCount(); // 更新 header 的 cartCount
            window.location.href = "/aonix/pages/store.html";
        } else {
            alert(data.message || "結帳失敗！");
        }
    } catch (e) {
        alert("結帳過程發生錯誤：" + (e.message || e));
    }
};

// [6] 彈窗切換
window.toggleCart = function () {
    const cartModal = document.getElementById("cartModal");
    if (!cartModal) {
        alert("購物車視窗不存在");
        return;
    }
    updateCartDisplay();
    cartModal.style.display = cartModal.style.display === "block" ? "none" : "block";
};

// [7] 頁面載入時自動刷新
document.addEventListener("DOMContentLoaded", () => {
    updateCartDisplay();
    updateCartCount(); // 確保頁面載入時更新 header 的 cartCount
});