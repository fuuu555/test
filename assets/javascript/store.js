let allProducts = [];
let filteredProducts = [];
let currentPage = 0;
let productsPerPage = parseInt(localStorage.getItem("productsPerPage"), 10) || 3;

document.addEventListener("DOMContentLoaded", () => {
    fetchAllProducts();

    document.getElementById('products-per-page').addEventListener('change', (e) => {
        productsPerPage = parseInt(e.target.value, 10);
        localStorage.setItem("productsPerPage", productsPerPage);
        displayProductsForPage(0);
        updatePaginationButtons();
    });

    document.getElementById('next-button').addEventListener('click', () => {
        const totalPages = Math.ceil(filteredProducts.length / productsPerPage);
        if (currentPage < totalPages - 1) {
            currentPage++;
            displayProductsForPage(currentPage);
            updatePaginationButtons();
        }
    });
    document.getElementById('prev-button').addEventListener('click', () => {
        if (currentPage > 0) {
            currentPage--;
            displayProductsForPage(currentPage);
            updatePaginationButtons();
        }
    });

    document.getElementById('filterSearchInput').addEventListener('input', function (e) {
        filterProducts(e.target.value);
    });

    document.querySelectorAll('.category-item').forEach(el => {
        el.addEventListener('click', function () {
            const cat = this.getAttribute('data-category');
            filteredProducts = allProducts.filter(
                p => (p.category || '').toLowerCase().includes(cat.toLowerCase())
            );
            currentPage = 0;
            displayProductsForPage(0);
            updatePaginationButtons();
        });
    });

    document.querySelectorAll(".category-btn").forEach(btn => {
        btn.addEventListener("click", function (e) {
            e.stopPropagation();
            const header = btn.closest('.category-header');
            if (!header) return;
            const content = header.nextElementSibling;
            if (content && content.classList.contains('category-dropdown-content')) {
                content.classList.toggle("active");
                const icon = btn.querySelector("iconify-icon");
                if (icon) {
                    icon.classList.toggle("active");
                    icon.style.transform = icon.classList.contains("active") ? "rotate(180deg)" : "rotate(0deg)";
                }
            }
        });
    });
});

async function fetchAllProducts() {
    try {
        const resp = await fetch('/aonix/jsp/get_products.jsp');
        const data = await resp.json();
        console.log("Fetched products:", data);
        if (!Array.isArray(data)) throw new Error('商品資料不是 array');
        allProducts = data;
        filteredProducts = allProducts;
        displayProductsForPage(0);
        updatePaginationButtons();
    } catch (e) {
        document.getElementById("productGrid").innerHTML = "商品載入失敗";
        console.error("Fetch products error:", e);
    }
}

function filterProducts(term) {
    term = (term || "").toLowerCase();
    filteredProducts = allProducts.filter(
        p => (p.name||'').toLowerCase().includes(term) ||
             (p.description||'').toLowerCase().includes(term) ||
             (p.category||'').toLowerCase().includes(term)
    );
    currentPage = 0;
    displayProductsForPage(0);
    updatePaginationButtons();
}

function displayProductsForPage(page) {
    currentPage = page;
    const start = page * productsPerPage, end = start + productsPerPage;
    displayProducts(filteredProducts.slice(start, end));
}

function displayProducts(products) {
    console.log("Displaying products:", products);
    const grid = document.getElementById('productGrid');
    if (!products.length) {
        grid.innerHTML = "<div>沒有商品</div>"; return;
    }
    grid.innerHTML = products.map(product => `
        <div class="product-card">
            <div class="product-img">
                <a href="product_review.html?id=${product.id}">
                    <img src="${(product.images && product.images[0]) || '/imgs/no-image.png'}" alt="${product.name}" draggable="false">
                </a>
            </div>
            <div class="product-details">
                <div class="product-brand">${product.brand||''}</div>
                <div class="product-name">
                    <a href="product_review.html?id=${product.id}"><h5>${product.name}</h5></a>
                </div>
                <div class="product-tags">
                    ${(product.features||[]).slice(0,3).map(f=>`<div class="tag">${f}</div>`).join("")}
                </div>
                <div class="product-description">${product.description||''}</div>
                <div class="product-bottom">
                    <div class="product-bottom-left">
                        <div class="product-rating">
                            <span class="rating">${product.averageRating || 0.0}
                            <iconify-icon icon="mdi:star" class="star-icon"></iconify-icon></span>
                            <span class="rating-count">(${product.reviewsCount || 0} reviews)</span>
                        </div>
                    </div>
                    <div class="product-bottom-right">
                        <div class="product-price">$${Number(product.price).toLocaleString()}</div>
                        <button class="add-to-cart-btn" onclick="addToCart('${product.id}')">Purchase</button>
                    </div>
                </div>
            </div>
        </div>
    `).join("");
}

function updatePaginationButtons() {
    const totalPages = Math.ceil(filteredProducts.length / productsPerPage);
    document.getElementById('prev-button').disabled = (currentPage === 0);
    document.getElementById('next-button').disabled = (currentPage >= totalPages - 1);
}