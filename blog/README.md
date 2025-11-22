# Blog System Documentation

This directory contains the blog system for Shardul Vaidya's personal website. The blog supports writing posts in Markdown and automatically renders them with the Tokyo Night theme.

## Directory Structure

```
blog/
├── README.md           # This file
├── posts.json          # Blog post index/metadata
└── posts/              # Markdown files for blog posts
    ├── welcome-to-my-blog.md
    └── getting-started-with-docker.md
```

## How to Add a New Blog Post

### Step 1: Write Your Post in Markdown

Create a new `.md` file in the `blog/posts/` directory:

```bash
touch blog/posts/my-new-post.md
```

Write your content using standard Markdown syntax. The system supports:

- **Headings** (h1-h6)
- **Lists** (ordered and unordered)
- **Code blocks** with syntax highlighting
- **Blockquotes**
- **Links** and **images**
- **Tables**
- **Bold** and *italic* text
- And all standard Markdown features

Example post structure:

```markdown
# My Post Title

Introduction paragraph here.

## Section 1

Content with **bold** and *italic* text.

### Code Example

\`\`\`javascript
function greet(name) {
  console.log(`Hello, ${name}!`);
}
\`\`\`

## Conclusion

Wrap up your thoughts here.
```

### Step 2: Add Metadata to posts.json

Open `blog/posts.json` and add an entry for your new post:

```json
{
  "id": "my-new-post",
  "title": "My Awesome New Post",
  "date": "2025-11-23",
  "excerpt": "A brief summary of what this post is about (1-2 sentences).",
  "tags": ["tutorial", "javascript", "web-dev"],
  "file": "my-new-post.md"
}
```

**Field descriptions:**
- `id`: URL-friendly identifier (used in the URL: `post.html?id=my-new-post`)
- `title`: Display title shown on the blog listing and post page
- `date`: Publication date in YYYY-MM-DD format (used for sorting)
- `excerpt`: Short description shown on the blog listing page
- `tags`: Array of tags for filtering (can add new tags as needed)
- `file`: The markdown filename in the `posts/` directory

### Step 3: Test Your Post

1. Open `blog.html` in your browser to see the post listed
2. Click on the post to view the full rendered content
3. Verify formatting, links, and code blocks appear correctly

## Supported Markdown Features

### Code Blocks

Inline code: \`const x = 5;\`

Code blocks with language:
\`\`\`python
def hello_world():
    print("Hello, World!")
\`\`\`

### Blockquotes

> This is a blockquote. It will be styled with the Tokyo Night theme colors.

### Lists

**Unordered:**
- Item 1
- Item 2
  - Nested item

**Ordered:**
1. First item
2. Second item
3. Third item

### Links and Images

[Link text](https://example.com)

![Alt text](path/to/image.jpg)

### Tables

| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

## Filtering and Tags

The blog listing page includes filter buttons for different tags. Available tags are automatically shown based on what's used in posts.

Common tags you might want to use:
- `tutorial` - How-to guides and tutorials
- `devops` - DevOps and infrastructure topics
- `aws` - AWS-specific content
- `kubernetes` - K8s and container orchestration
- `meta` - Blog-related or personal posts
- `photography` - Photography-related content
- `genai` - Generative AI and ML topics

You can create new tags at any time by adding them to a post's `tags` array in `posts.json`. They'll automatically appear in the filter menu.

## Styling

Blog posts are automatically styled with the Tokyo Night theme to match the rest of the website. Custom styles can be modified in `blog-styles.css`.

Key style features:
- Gradient headings (cyan to blue)
- Syntax-highlighted code blocks
- Responsive card layouts
- Smooth hover animations
- Dark theme optimized for readability

## Tips for Writing

1. **Use descriptive headings** - They create automatic anchor links
2. **Include code examples** - They're syntax highlighted automatically
3. **Write engaging excerpts** - They appear on the blog listing page
4. **Choose relevant tags** - They help readers find related content
5. **Date format matters** - Use YYYY-MM-DD for proper sorting
6. **Test locally** - Always preview before committing

## Deployment

The blog is served as static files through Caddy. After adding new posts:

1. Commit your changes:
   ```bash
   git add blog/posts.json blog/posts/your-new-post.md
   git commit -m "Add new blog post: Your Post Title"
   ```

2. Push to your repository:
   ```bash
   git push
   ```

3. Deploy using your deployment script:
   ```bash
   ./deploy-caddy.sh
   ```

The blog will be live at `https://yourdomain.com/blog.html`

## Troubleshooting

**Post not showing up?**
- Check that `posts.json` is valid JSON
- Verify the `file` field matches the actual filename
- Ensure the markdown file is in `blog/posts/`

**Formatting looks wrong?**
- Check your Markdown syntax
- Look for unclosed code blocks or broken tables
- View browser console for JavaScript errors

**Images not loading?**
- Use relative paths from the website root
- Ensure images are committed to the repository
- Check file permissions

## Future Enhancements

Possible additions to consider:
- RSS feed generation
- Search functionality
- Reading time estimates
- Related posts suggestions
- Social sharing buttons
- Comments system integration
- Dark/light theme toggle

---

For questions or issues, refer to the main project README or open an issue.
