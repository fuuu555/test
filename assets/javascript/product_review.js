document.addEventListener('DOMContentLoaded', async () => {
    const urlParams = new URLSearchParams(window.location.search);
    const productId = urlParams.get('id');
    let currentRating = 0;
    let quantity = 1;
    let currentUser = null; // TODO: 從 session 取得用戶資訊

    if (!productId) {
        console.error('Product ID is missing from URL');
        document.querySelector('.reviews-list').innerHTML = '<p class="error">錯誤：未提供商品 ID</p>';
        return;
    }
    
    // Fetch product details
    fetch(`/aonix/jsp/get_products.jsp?id=${productId}`)
        .then(res => {
            if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
            return res.json();
        })
        .then(data => {
            console.log("Fetched product:", data);
            if (data.error) throw new Error(data.error);
            const product = Array.isArray(data) ? data.find(p => p.id === productId) : data;
            if (!product) throw new Error('Product not found');
            document.querySelector('.product-name').textContent = product.name;
            document.querySelector('.product-description').textContent = product.longdescription || product.description;
            const priceElement = document.querySelector('.product-price');
            priceElement.textContent = `$${Number(product.price).toLocaleString()}`;
            document.querySelector('.product-image').innerHTML = `<img src="${(product.images && product.images[0]) || '/imgs/no-image.png'}" alt="${product.name}" />`;
        })
        .catch(err => {
            console.error('Error fetching product:', err);
            document.querySelector('.product-name').textContent = '載入商品失敗';
            document.querySelector('.product-description').textContent = err.message;
        });

    // Fetch cart data
    try {
        const res = await fetch(`/aonix/jsp/cart_list.jsp`);
        if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
        const data = await res.json();
        if (data.status === 'success' && data.items) {
            const item = data.items.find(i => i.productId === productId);
            if (item) {
                quantity = item.quantity || 1;
                document.getElementById('quantity').textContent = quantity;
                updatePriceDisplay();
            }
        }
        await window.updateCartCount(); // Update cart count in header
    } catch (err) {
        console.error('Error fetching cart:', err);
    }

    // Handle star rating interactions
    const stars = document.querySelectorAll('.star-icon');
    const ratingText = document.querySelector('.rating-text');
    stars.forEach((star, idx) => {
        star.addEventListener('click', () => {
            currentRating = idx + 1;
            updateStarsDisplay(currentRating);
            if (ratingText) ratingText.textContent = `你選擇了 ${currentRating} 顆星`;
        });
        star.addEventListener('mouseenter', () => updateStarsDisplay(idx + 1));
        star.addEventListener('mouseleave', () => updateStarsDisplay(currentRating));
    });
    function updateStarsDisplay(rating) {
        stars.forEach((star, i) => {
            star.setAttribute('icon', i < rating ? 'mdi:star' : 'mdi:star-outline');
        });
    }

    // Fetch and display rating summary
    function updateRatingSummary() {
        fetch(`/aonix/jsp/get_review.jsp?productId=${productId}`)
            .then(res => {
                if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
                return res.text();
            })
            .then(text => {
                if (!text || text.trim() === "") {
                    throw new Error("Empty response from server");
                }
                const data = JSON.parse(text);
                console.log("Rating summary:", data);
                if (data.error) throw new Error(data.error);
                const reviews = Array.isArray(data) ? data : [];
                const totalReviews = reviews.length;
                const averageRating = totalReviews > 0 ? (reviews.reduce((sum, r) => sum + r.rating, 0) / totalReviews).toFixed(1) : '0.0';
                document.querySelector('.rating-number').textContent = averageRating;
                document.querySelector('.total-reviews').textContent = `(${totalReviews} 則評論)`;

                const avgStars = document.createElement('div');
                avgStars.className = 'star';
                for (let i = 1; i <= 5; i++) {
                    const star = document.createElement('iconify-icon');
                    star.setAttribute('width', '24');
                    star.setAttribute('height', '24');
                    star.setAttribute('icon', i <= Math.round(averageRating) ? 'mdi:star' : 'mdi:star-outline');
                    star.style.color = 'gold';
                    avgStars.appendChild(star);
                }
                const oldStars = document.querySelector('.average-rating .star');
                if (oldStars) oldStars.replaceWith(avgStars);
                else document.querySelector('.average-rating').appendChild(avgStars);
            })
            .catch(err => {
                console.error('Error fetching rating summary:', err);
                document.querySelector('.rating-number').textContent = 'N/A';
                document.querySelector('.total-reviews').textContent = '(0 則評論)';
            });
    }

    // Fetch and display reviews
    function loadReviews() {
        fetch(`/aonix/jsp/get_review.jsp?productId=${productId}`)
            .then(res => {
                if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
                return res.text();
            })
            .then(text => {
                if (!text || text.trim() === "") {
                    throw new Error("Empty response from server");
                }
                try {
                    const data = JSON.parse(text);
                    console.log("Loaded reviews:", data);
                    if (data.error) throw new Error(data.error);
                    const reviews = Array.isArray(data) ? data : [];
                    const reviewList = document.querySelector('.reviews-list');
                    reviewList.innerHTML = '<h2 class="text-glow">商品評論</h2>';
                    if (!reviews.length) {
                        reviewList.innerHTML += '<p class="no-reviews">暫無評論</p>';
                        return;
                    }
                    reviews.sort((a, b) => new Date(b.date) - new Date(a.date));
                    reviewList.innerHTML += reviews.map(review => `
                        <div class="review-item">
                            <div class="review-header">
                                <div class="star">
                                    ${Array(5).fill('').map((_, i) =>
                                        `<iconify-icon icon="${i < review.rating ? 'mdi:star' : 'mdi:star-outline'}" width="20" height="20" style="color: gold;"></iconify-icon>`
                                    ).join('')}
                                </div>
                                <span class="review-date">${new Date(review.date).toLocaleDateString()}</span>
                            </div>
                            <div class="review-content">${review.content}</div>
                        </div>
                    `).join('');
                } catch (err) {
                    console.error('Error parsing JSON:', err, 'Raw response:', text);
                    throw new Error('JSON 格式錯誤 - ' + err.message);
                }
            })
            .catch(err => {
                console.error('Error fetching reviews:', err);
                document.querySelector('.reviews-list').innerHTML = '<p class="error">載入評論失敗：' + err.message + '</p>';
            });
    }

    // Load recommended products
    async function loadRecommendedProducts() {
        try {
            const res = await fetch(`/aonix/jsp/get_products.jsp`);
            if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
            const data = await res.json();
            console.log("Fetched products for recommendations:", data);
            if (data.error) throw new Error(data.error);

            const products = Array.isArray(data) ? data : [];
            // Filter out current product and get random 3 products
            const recommendedProducts = products
                .filter(product => product.id !== productId)
                .sort(() => 0.5 - Math.random())
                .slice(0, 3);

            const productsGrid = document.querySelector('.products-grid');
            if (!productsGrid) {
                console.warn('Products grid element not found in DOM');
                return;
            }
            productsGrid.innerHTML = recommendedProducts.map(product => `
                <div class="card product-card" onclick="location.href='/aonix/pages/product_review.html?id=${product.id}'">
                    <img src="${(product.images && product.images[0]) || '/imgs/no-image.png'}" alt="${product.name}">
                    <h3>${product.name}</h3>
                    <div class="price">$${Number(product.price).toLocaleString()}</div>
                </div>
            `).join('');
        } catch (error) {
            console.error('Error loading recommended products:', error);
            const productsGrid = document.querySelector('.products-grid');
            if (productsGrid) {
                productsGrid.innerHTML = '<p class="error">載入推薦商品失敗</p>';
            }
        }
    }

    // Handle review submission
    const reviewForm = document.getElementById('reviewForm');
    if (reviewForm) {
        reviewForm.addEventListener('submit', function (e) {
            e.preventDefault();
            if (!currentRating) {
                alert('請先點選星星給分！');
                return;
            }
            const content = reviewForm.querySelector('textarea').value.trim();
            if (content.length < 10) {
                alert('評論內容至少需要10個字！');
                return;
            }
            fetch('/aonix/jsp/add_review.jsp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    productId,
                    rating: currentRating,
                    content,
                    // userId: currentUser?.id || 'anonymous'
                })
            })
            .then(res => {
                if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
                return res.json();
            })
            .then(data => {
                if (data.status === 'success') {
                    reviewForm.reset();
                    updateStarsDisplay(0);
                    if (ratingText) ratingText.textContent = '請選擇評分';
                    updateRatingSummary();
                    loadReviews();
                } else {
                    alert(data.message || '提交失敗');
                }
            })
            .catch(err => {
                console.error('Error submitting review:', err);
                alert('提交評論失敗：' + err.message);
            });
        });
    }

    // Update quantity and sync with backend
    function updateQuantityLocal(change) {
        quantity = Math.max(1, quantity + change);
        document.getElementById('quantity').textContent = quantity;
        updatePriceDisplay();
        // Sync with backend
        fetch('/aonix/jsp/cart_update.jsp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({ productId, quantity })
        })
        .then(res => {
            if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
            return res.json();
        })
        .then(data => {
            if (data.status !== 'success') {
                console.error('Failed to update cart quantity:', data.message);
                alert('更新數量失敗，請重試');
                // Rollback local quantity
                fetch(`/aonix/jsp/cart_list.jsp`).then(res => res.json()).then(data => {
                    if (data.status === 'success' && data.items) {
                        const item = data.items.find(i => i.productId === productId);
                        if (item) quantity = item.quantity;
                        document.getElementById('quantity').textContent = quantity;
                        updatePriceDisplay();
                    }
                });
            } else {
                window.updateCartCount(); // Update cart count on success
            }
        })
        .catch(err => console.error('Error updating cart:', err));
    }

    document.querySelector('.quantity-decrease').addEventListener('click', () => updateQuantityLocal(-1));
    document.querySelector('.quantity-increase').addEventListener('click', () => updateQuantityLocal(1));
    
    function updatePriceDisplay() {
        const priceElement = document.querySelector('.product-price');
        if (priceElement && priceElement.dataset.basePrice) {
            const basePrice = parseFloat(priceElement.dataset.basePrice);
            priceElement.textContent = `$${Number(basePrice * quantity).toLocaleString()}`;
        }
    }

    document.querySelector('.add-to-cart-btn').addEventListener('click', () => {
        console.log("Calling addToCart from product_review:", { productId, quantity });
        window.addToCart(productId, quantity); // Call global addToCart from cart.js
    });

    // Initialize page
    updateRatingSummary();
    loadReviews();
    loadRecommendedProducts(); // Call the new function
    window.updateCartCount(); // Update cart count
});