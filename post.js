// Individual blog post page functionality

// Get post ID from URL parameters
function getPostId() {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('id');
}

// Load post metadata
async function loadPostMetadata(postId) {
    try {
        const response = await fetch('blog/posts.json');
        const posts = await response.json();
        return posts.find(post => post.id === postId);
    } catch (error) {
        console.error('Error loading post metadata:', error);
        return null;
    }
}

// Load and render markdown content
async function loadMarkdownContent(filename) {
    try {
        const response = await fetch(`blog/posts/${filename}`);
        const markdown = await response.text();

        // Configure marked options
        marked.setOptions({
            breaks: true,
            gfm: true,
            headerIds: true,
            mangle: false
        });

        return marked.parse(markdown);
    } catch (error) {
        console.error('Error loading markdown:', error);
        return null;
    }
}

// Format date to readable format
function formatDate(dateString) {
    const options = { year: 'numeric', month: 'long', day: 'numeric' };
    return new Date(dateString).toLocaleDateString('en-US', options);
}

// Display the blog post
async function displayPost() {
    const postId = getPostId();

    if (!postId) {
        document.getElementById('post-content').innerHTML =
            '<p class="error">No post ID specified.</p>';
        return;
    }

    // Load metadata
    const metadata = await loadPostMetadata(postId);

    if (!metadata) {
        document.getElementById('post-content').innerHTML =
            '<p class="error">Post not found.</p>';
        return;
    }

    // Update page title and heading
    document.getElementById('post-title').textContent = `${metadata.title} - Shardul Vaidya`;
    document.getElementById('post-heading').textContent = metadata.title;
    document.getElementById('post-date').textContent = formatDate(metadata.date);

    // Add tags
    const tagsContainer = document.getElementById('post-tags');
    tagsContainer.innerHTML = metadata.tags.map(tag =>
        `<span class="tag">${tag}</span>`
    ).join('');

    // Load and render markdown content
    const htmlContent = await loadMarkdownContent(metadata.file);

    if (htmlContent) {
        document.getElementById('post-content').innerHTML = htmlContent;

        // Add syntax highlighting to code blocks if needed
        highlightCodeBlocks();
    } else {
        document.getElementById('post-content').innerHTML =
            '<p class="error">Failed to load post content.</p>';
    }
}

// Add basic syntax highlighting classes to code blocks
function highlightCodeBlocks() {
    const codeBlocks = document.querySelectorAll('pre code');
    codeBlocks.forEach(block => {
        block.classList.add('code-block');
    });
}

// Initialize when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', displayPost);
} else {
    displayPost();
}
