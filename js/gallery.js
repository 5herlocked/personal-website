// Dynamic photo gallery functionality

let allPhotos = [];
let currentFilter = 'all';
let currentPhotoIndex = 0;

// Load and display photos
async function loadPhotos() {
    try {
        const response = await fetch('data/photos.json');
        allPhotos = await response.json();
        displayPhotos(allPhotos);
        setupLightbox();
    } catch (error) {
        console.error('Error loading photos:', error);
        document.querySelector('.gallery-grid').innerHTML =
            '<p class="error">Failed to load photos. Please try again later.</p>';
    }
}

// Display photos in the grid
function displayPhotos(photos) {
    const galleryGrid = document.querySelector('.gallery-grid');

    if (photos.length === 0) {
        galleryGrid.innerHTML = '<p class="no-photos">No photos found.</p>';
        return;
    }

    galleryGrid.innerHTML = photos.map((photo, index) => `
        <div class="gallery-item" data-category="${photo.category}" data-index="${index}">
            <img src="images/${photo.file}" alt="${photo.title}" loading="lazy">
            <div class="gallery-overlay">
                <h3>${photo.title}</h3>
                <p>${photo.category}</p>
            </div>
        </div>
    `).join('');

    // Attach click handlers for lightbox
    document.querySelectorAll('.gallery-item').forEach((item, index) => {
        item.addEventListener('click', () => {
            currentPhotoIndex = index;
            openLightbox();
        });
    });
}

// Setup filter buttons
const filterButtons = document.querySelectorAll('.filter-btn');
filterButtons.forEach(button => {
    button.addEventListener('click', () => {
        // Update active state
        filterButtons.forEach(btn => btn.classList.remove('active'));
        button.classList.add('active');

        // Filter photos
        const category = button.getAttribute('data-filter');
        currentFilter = category;

        if (category === 'all') {
            displayPhotos(allPhotos);
        } else {
            const filtered = allPhotos.filter(photo => photo.category === category);
            displayPhotos(filtered);
        }
    });
});

// Lightbox functionality
function setupLightbox() {
    const lightbox = document.getElementById('lightbox');
    const lightboxClose = document.querySelector('.lightbox-close');
    const lightboxPrev = document.querySelector('.lightbox-prev');
    const lightboxNext = document.querySelector('.lightbox-next');

    if (lightboxClose) {
        lightboxClose.addEventListener('click', closeLightbox);
    }

    if (lightbox) {
        lightbox.addEventListener('click', (e) => {
            if (e.target === lightbox) {
                closeLightbox();
            }
        });
    }

    if (lightboxPrev) {
        lightboxPrev.addEventListener('click', showPreviousPhoto);
    }

    if (lightboxNext) {
        lightboxNext.addEventListener('click', showNextPhoto);
    }

    // Keyboard navigation
    document.addEventListener('keydown', (e) => {
        if (lightbox && lightbox.classList.contains('active')) {
            if (e.key === 'Escape') {
                closeLightbox();
            } else if (e.key === 'ArrowLeft') {
                showPreviousPhoto();
            } else if (e.key === 'ArrowRight') {
                showNextPhoto();
            }
        }
    });
}

function openLightbox() {
    const lightbox = document.getElementById('lightbox');
    const lightboxContent = document.querySelector('.lightbox-content');

    if (lightbox && lightboxContent) {
        const photo = allPhotos[currentPhotoIndex];
        lightboxContent.innerHTML = `
            <img src="images/${photo.file}" alt="${photo.title}">
            <div class="lightbox-info">
                <h3>${photo.title}</h3>
                <p>${photo.description || photo.category}</p>
            </div>
        `;
        lightbox.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

function closeLightbox() {
    const lightbox = document.getElementById('lightbox');
    if (lightbox) {
        lightbox.classList.remove('active');
        document.body.style.overflow = 'auto';
    }
}

function showNextPhoto() {
    currentPhotoIndex = (currentPhotoIndex + 1) % allPhotos.length;
    openLightbox();
}

function showPreviousPhoto() {
    currentPhotoIndex = (currentPhotoIndex - 1 + allPhotos.length) % allPhotos.length;
    openLightbox();
}

// Initialize when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadPhotos);
} else {
    loadPhotos();
}
