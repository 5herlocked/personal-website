# Personal Portfolio Website

A modern, sleek personal portfolio website built with pure HTML5, CSS3, and vanilla JavaScript. Features a beautiful Tokyo Night color theme with smooth animations and interactive effects.

## Features

- **Tokyo Night Theme**: Stunning dark theme inspired by the popular Tokyo Night color scheme
- **Responsive Design**: Fully responsive layout that works on all devices
- **Smooth Animations**: Eye-catching animations and transitions throughout
- **Photography Gallery**: Dedicated photography showcase page with filtering capabilities
- **Interactive Effects**:
  - Typing animation in hero section
  - Parallax scrolling effects
  - 3D tilt effects on hover
  - Smooth page transitions
  - Lightbox for image viewing
- **No Dependencies**: Built with pure web technologies - no frameworks or libraries

## Structure

```
personal-website/
├── index.html          # Main landing page
├── photography.html    # Photography gallery page
├── styles.css          # All styles with Tokyo Night theme
├── script.js           # Interactive JavaScript features
└── README.md          # This file
```

## Pages

### Home (index.html)
- Hero section with animated typing effect
- About section highlighting professional focus
- Interests section showcasing hobbies and passions
- Smooth scroll navigation

### Photography (photography.html)
- Gallery grid with category filtering
- Placeholder cards for photography showcase
- Lightbox modal for full-size image viewing
- Keyboard navigation support

## Color Palette (Tokyo Night)

- **Background**: `#1a1b26` - Deep night blue
- **Foreground**: `#c0caf5` - Soft white-blue
- **Accent Blue**: `#7aa2f7`
- **Accent Cyan**: `#7dcfff`
- **Accent Purple**: `#bb9af7`
- **Accent Green**: `#9ece6a`
- **Accent Yellow**: `#e0af68`
- **Accent Red**: `#f7768e`

## Customization

### Adding Your Own Photos

Replace the placeholder divs in `photography.html` with your actual images:

```html
<div class="gallery-item" data-category="landscape">
    <img src="path/to/your/image.jpg" alt="Description">
</div>
```

### Updating Content

- Edit `index.html` to update your bio, skills, and interests
- Modify the `textArray` in `script.js` to change the typing animation text
- Adjust colors in `styles.css` by modifying the CSS variables in `:root`

## Browser Support

- Chrome (recommended)
- Firefox
- Safari
- Edge
- Opera

## Performance

- No external dependencies
- Minimal HTTP requests
- Optimized CSS animations
- Fast load times
- Accessibility-friendly with reduced motion support

## Development

Simply open `index.html` in your browser to view the site locally. No build process or server required!

For a local development server:
```bash
python -m http.server 8000
# or
npx serve
```

Then visit `http://localhost:8000`

## Deployment

This site can be deployed to any static hosting service:
- GitHub Pages
- Netlify
- Vercel
- Cloudflare Pages
- AWS S3
- Your own server

## License

Free to use and modify for your personal portfolio.

---

Built with ❤️ using pure HTML5, CSS3, and JavaScript
