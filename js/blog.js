// Blog listing page functionality

let allPosts = [];
let currentFilter = 'all';

// Load and display blog posts
async function loadBlogPosts() {
    try {
        const response = await fetch('blog/posts.json');
        allPosts = await response.json();

        // Sort posts by date (newest first)
        allPosts.sort((a, b) => new Date(b.date) - new Date(a.date));

        displayPosts(allPosts);
        setupFilterButtons();
    } catch (error) {
        console.error('Error loading blog posts:', error);
        document.getElementById('posts-grid').innerHTML =
            '<p class="error">Failed to load blog posts. Please try again later.</p>';
    }
}

// Display posts in the grid
function displayPosts(posts) {
    const postsGrid = document.getElementById('posts-grid');

    if (posts.length === 0) {
        postsGrid.innerHTML = '<p class="no-posts">No posts found.</p>';
        return;
    }

    postsGrid.innerHTML = posts.map(post => `
        <article class="post-card" data-tags="${post.tags.join(' ')}">
            <div class="post-card-content">
                <time class="post-card-date">${formatDate(post.date)}</time>
                <h2 class="post-card-title">
                    <a href="post.html?id=${post.id}">${post.title}</a>
                </h2>
                <p class="post-card-excerpt">${post.excerpt}</p>
                <div class="post-card-tags">
                    ${post.tags.map(tag => `<span class="tag">${tag}</span>`).join('')}
                </div>
                <a href="post.html?id=${post.id}" class="read-more">
                    Read more
                    <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                        <path d="M6 12L10 8L6 4" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                </a>
            </div>
        </article>
    `).join('');
}

// Format date to readable format
function formatDate(dateString) {
    const options = { year: 'numeric', month: 'long', day: 'numeric' };
    return new Date(dateString).toLocaleDateString('en-US', options);
}

// Setup filter buttons
function setupFilterButtons() {
    const filterButtons = document.querySelectorAll('.filter-btn');

    filterButtons.forEach(button => {
        button.addEventListener('click', () => {
            // Update active state
            filterButtons.forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');

            // Filter posts
            const tag = button.getAttribute('data-tag');
            currentFilter = tag;

            if (tag === 'all') {
                displayPosts(allPosts);
            } else {
                const filtered = allPosts.filter(post => post.tags.includes(tag));
                displayPosts(filtered);
            }
        });
    });
}

// Initialize when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadBlogPosts);
} else {
    loadBlogPosts();
}
