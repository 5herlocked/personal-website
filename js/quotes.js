// Quotes page functionality

let allQuotes = [];

// Load and display quotes
async function loadQuotes() {
    try {
        const response = await fetch('data/quotes.json');
        allQuotes = await response.json();
        displayQuotes(allQuotes);
    } catch (error) {
        console.error('Error loading quotes:', error);
        document.getElementById('quotes-grid').innerHTML =
            '<p class="error">Failed to load quotes. Please try again later.</p>';
    }
}

// Display quotes in the grid
function displayQuotes(quotes) {
    const quotesGrid = document.getElementById('quotes-grid');

    if (quotes.length === 0) {
        quotesGrid.innerHTML = '<p class="no-posts">No quotes found.</p>';
        return;
    }

    quotesGrid.innerHTML = quotes.map(quote => `
        <article class="quote-card">
            <div class="quote-card-content">
                <blockquote class="quote-text">"${quote.text}"</blockquote>
                <div class="quote-attribution">
                    <p class="quote-author">— ${quote.author}</p>
                    <p class="quote-source">${quote.source}</p>
                </div>
            </div>
        </article>
    `).join('');
}

// Initialize when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadQuotes);
} else {
    loadQuotes();
}
