const API__KEY = '0eaa94d65e689aa18580569f96d442d8';

// Function to fetch movies based on search query
async function fetchSearchResults(query) {
    const url = `https://api.themoviedb.org/3/search/movie?api_key=${API__KEY}&query=${encodeURIComponent(query)}&language=en-US`;
    try {
        const response = await fetch(url);
        const data = await response.json();
        return data.results;
    } catch (error) {
        console.error("Error fetching search results:", error);
        return [];
    }
}

// Function to render movies inside the container
function renderMovies(movies) {
    const searchResultsContainer = document.getElementById('search-results-container');
    searchResultsContainer.innerHTML = ''; // Clear the container before rendering new content

    if (movies.length === 0) {
        searchResultsContainer.innerHTML = '<p>No movies found.</p>';
        return;
    }

    movies.forEach(movie => {
        const movieItem = document.createElement('div');
        movieItem.classList.add('col-lg-3', 'col-md-6', 'col-sm-6');

        // Set the movie poster image or a default image if not available
        const posterPath = `https://image.tmdb.org/t/p/w500${movie.poster_path}`;

        movieItem.innerHTML = `
            <div class="product__item"><a href="movie-details.html?id=${movie.id}">
                <div class="product__item__pic set-bg" style="background-image: url(${posterPath});">
                    <div class="ep">Rating: ${movie.vote_average}</div>
                    <div class="comment"><i class="fa fa-comments"></i> ${movie.vote_count}</div>
                    <div class="view"><i class="fa fa-eye"></i> ${movie.popularity}</div>
                </div>
                <div class="product__item__text">
                    <ul>
                        <li>Active</li>
                        <li>Movie</li>
                    </ul>
                    <h5>${movie.title}</a></h5>
                </div>
            </div>
        `;

        searchResultsContainer.appendChild(movieItem);
    });
}

// Extract the search query from the URL
const urlParams = new URLSearchParams(window.location.search);
const query = urlParams.get('query');

// Fetch and render the results if the query exists
if (query) {
    fetchSearchResults(query).then(movies => {
        renderMovies(movies); // Render the search results
    });
}


// Function to handle the form submit (via Enter or button click)
function handleSearchSubmit(event) {
    event.preventDefault(); // Prevent the form from submitting normally

    const query = document.getElementById('search-input').value.trim();
    if (!query) return;

    // Redirect to searched.html with the search query as a URL parameter
    window.location.href = `searched.html?query=${encodeURIComponent(query)}`;
}
// Function to handle the Enter key press in the search input field
function handleEnterKey(event) {
    // Check if the key pressed is Enter (key code 13)
    if (event.key === 'Enter') {
        event.preventDefault(); // Prevent the default form submission behavior

        const query = document.getElementById('search-input').value.trim();
        if (query) {
            // Redirect to searched.html with the query as a URL parameter
            window.location.href = `searched.html?query=${encodeURIComponent(query)}`;
        }
    }
}
