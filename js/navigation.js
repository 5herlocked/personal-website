// Centralized navigation component

function createNavigation(activePage = '') {
    const nav = document.querySelector('nav.navbar');
    if (!nav) return;

    const navItems = [
        { href: 'index.html', text: 'Home', hash: '#home', page: 'home' },
        { href: 'index.html#about', text: 'About', page: 'about' },
        { href: 'index.html#interests', text: 'Interests', page: 'interests' },
        { href: 'photography.html', text: 'Photography', page: 'photography' },
        { href: 'blog.html', text: 'Blog', page: 'blog' },
        { href: 'quotes.html', text: 'Quotes', page: 'quotes' }
    ];

    // Generate navigation HTML
    const navHTML = `
        <div class="nav-container">
            <div class="nav-logo">
                <span class="logo-bracket">[</span>
                <span class="logo-text">Shardul Vaidya</span>
                <span class="logo-bracket">]</span>
            </div>
            <ul class="nav-menu">
                ${navItems.map(item => `
                    <li><a href="${item.href}" class="nav-link ${activePage === item.page ? 'active' : ''}">${item.text}</a></li>
                `).join('')}
            </ul>
            <div class="nav-toggle">
                <span></span>
                <span></span>
                <span></span>
            </div>
        </div>
    `;

    nav.innerHTML = navHTML;
}

// Auto-detect active page and initialize
function initNavigation() {
    const path = window.location.pathname;
    const filename = path.split('/').pop() || 'index.html';

    let activePage = '';
    if (filename === 'index.html' || filename === '') {
        activePage = 'home';
    } else if (filename === 'photography.html') {
        activePage = 'photography';
    } else if (filename === 'blog.html') {
        activePage = 'blog';
    } else if (filename === 'post.html') {
        activePage = 'blog';
    } else if (filename === 'quotes.html') {
        activePage = 'quotes';
    }

    createNavigation(activePage);
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initNavigation);
} else {
    initNavigation();
}
