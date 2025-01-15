const API_KEY = '0eaa94d65e689aa18580569f96d442d8';
const genreId = new URLSearchParams(window.location.search).get('genre'); // Gets the genre ID from the URL query

// Function to fetch movies by genre
async function fetchMoviesByGenre(genreId, page) {
    const url = `https://api.themoviedb.org/3/discover/movie?api_key=${API_KEY}&with_genres=${genreId}&page=${page}&language=en-US`;
    try {
        const response = await fetch(url);
        const data = await response.json();
        return data.results; // Return the movie results to the calling function
    } catch (error) {
        console.error("Error fetching movies by genre:", error);
        return []; // Return an empty array if there’s an error
    }
}


// Function to display movies
function displayMovies(movies) {
    const container = document.getElementById('genre-movies-container');
    container.innerHTML = ''; // Clear any existing content

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

        container.appendChild(movieItem);
    });
}


let currentPage = 1;

async function loadMovies() {
    const movies = await fetchMoviesByGenre(genreId, currentPage);
    displayMovies(movies); // Pass the movie data to displayMovies
}


function changePage(newPage) {
    if (newPage > 0) {
        currentPage = newPage;
        loadMovies();

        // Scroll to the top of the page
        window.scrollTo(0, 0);

        // Update the page number display
        document.getElementById("pageNumber").textContent = `Page ${currentPage}`;

        // Enable or disable the prevPage and nextPage buttons
        document.getElementById("prevPage").disabled = currentPage === 1;

        // Assuming 500 is the max pages for TMDB API (based on their docs)
        document.getElementById("nextPage").disabled = currentPage >= 500;
    }
}

// Function to fetch the list of genres
async function fetchGenres() {
    const url = `https://api.themoviedb.org/3/genre/movie/list?api_key=${API_KEY}&language=en-US`;
    try {
        const response = await fetch(url);
        const data = await response.json();
        return data.genres; // Return the list of genres
    } catch (error) {
        console.error("Error fetching genres:", error);
        return []; // Return an empty array if there’s an error
    }
}

// Function to set the genre name in the breadcrumb and section title
async function setGenreName() {
    const genres = await fetchGenres();
    const genre = genres.find(g => g.id === parseInt(genreId));
    const genreName = genre ? genre.name : 'Genre';

    // Update the breadcrumb and section title with the genre name
    document.getElementById("bread-genre").textContent = genreName;
    document.getElementById("section-title").textContent = genreName;
}

// Initial load
loadMovies();
setGenreName();
document.getElementById("prevPage").addEventListener("click", () => changePage(currentPage - 1));
document.getElementById("nextPage").addEventListener("click", () => changePage(currentPage + 1));
document.getElementById("prevPage").disabled = currentPage === 1;
document.getElementById("pageNumber").textContent = `Page ${currentPage}`;
