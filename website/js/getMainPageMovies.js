const apiKey = 'YOUR_API_KEY';
const trendingMoviesUrl = `https://api.themoviedb.org/3/trending/movie/week?api_key=${apiKey}`;
const topRatedMoviesUrl = `https://api.themoviedb.org/3/movie/top_rated?api_key=${apiKey}&language=en-US&page=1`;
const upcomingMoviesUrl = `https://api.themoviedb.org/3/movie/upcoming?api_key=${apiKey}&language=en-US&page=1`;

async function fetchTrendingMovies() {
    try {
        const response = await fetch(trendingMoviesUrl);
        const data = await response.json();
        const trendingMovies = data.results.slice(0, 8); // Limit to the first 9 movies
        displayTrending(trendingMovies);
    } catch (error) {
        console.error("Error fetching trending movies:", error);
    }
}

async function fetchTopRatedMovies() {
    try {
        const response = await fetch(topRatedMoviesUrl);
        const data = await response.json();
        const topRatedMovies = data.results.slice(0, 8); // Limit to the first 9 movies
        displayTopRated(topRatedMovies);
    } catch (error) {
        console.error("Error fetching top rated movies:", error);
    }
}

async function fetchUpcomingMovies() {
    try {
        const response = await fetch(upcomingMoviesUrl);
        const data = await response.json();
        const upComingMovies = data.results.slice(0, 8); // Limit to the first 9 movies
        displayUpcoming(upComingMovies);
    } catch (error) {
        console.error("Error fetching upcoming movies:", error);
    }
}

function displayTrending(trendingMovies) {
    const moviesContainer = document.getElementById('trending-movies');

    trendingMovies.forEach(movie => {
        const movieItem = `
                <div class="col-lg-3 col-md-6 col-sm-6">
                    <div class="product__item"><a href="movie-details.html?id=${movie.id}">
                        <div class="product__item__pic set-bg" style="background-image: url('https://image.tmdb.org/t/p/w500${movie.poster_path}');">
                            <div class="ep">Rating: ${movie.vote_average}</div>
                            <div class="comment"><i class="fa fa-comments"></i> ${movie.vote_count}</div>
                            <div class="view"><i class="fa fa-eye"></i> ${movie.popularity}</div>
                        </div>
                        <div class="product__item__text">
                            <ul>
                                <li>${movie.release_date}</li>
                                <li>Movie</li>
                            </ul>
                            <h5>${movie.title}</a></h5>
                        </div>
                    </div>
                </div>
            `;
        moviesContainer.innerHTML += movieItem;
    });
}

function displayTopRated(topRatedMovies) {
    const moviesContainer = document.getElementById('top-rated-movies');
    moviesContainer.innerHTML = ''; // Clear existing content

    topRatedMovies.forEach(movie => {
        const movieItem = `
                <div class="col-lg-3 col-md-6 col-sm-6">
                    <div class="product__item"><a href="movie-details.html?id=${movie.id}">
                        <div class="product__item__pic set-bg" style="background-image: url('https://image.tmdb.org/t/p/w500${movie.poster_path}');">
                            <div class="ep">Rating: ${movie.vote_average}</div>
                            <div class="comment"><i class="fa fa-comments"></i> ${movie.vote_count}</div>
                            <div class="view"><i class="fa fa-eye"></i> ${movie.popularity}</div>
                        </div>
                        <div class="product__item__text">
                            <ul>
                                <li>${movie.release_date}</li>
                                <li>Movie</li>
                            </ul>
                            <h5><a href="movie-details.html?id=${movie.id}">${movie.title}</a></h5>
                        </div>
                    </div>
                </div>
            `;
        moviesContainer.innerHTML += movieItem;
    });
}

function displayUpcoming(movies) {
    const moviesContainer = document.getElementById('upcoming-movies');
    moviesContainer.innerHTML = ''; // Clear existing content

    movies.forEach(movie => {
        const movieItem = `
                <div class="col-lg-3 col-md-6 col-sm-6">
                    <div class="product__item"><a href="movie-details.html?id=${movie.id}">
                        <div class="product__item__pic set-bg" style="background-image: url('https://image.tmdb.org/t/p/w500${movie.poster_path}');">
                            <div class="ep">Rating: ${movie.vote_average}</div>
                            <div class="comment"><i class="fa fa-comments"></i> ${movie.vote_count}</div>
                            <div class="view"><i class="fa fa-eye"></i> ${movie.popularity}</div>
                        </div>
                        <div class="product__item__text">
                            <ul>
                                <li>${movie.release_date}</li>
                                <li>Movie</li>
                            </ul>
                            <h5><a href="movie-details.html?id=${movie.id}">${movie.title}</a></h5>
                        </div>
                    </div>
                </div>
            `;
        moviesContainer.innerHTML += movieItem;
    });
}

// Fetch trending movies on page load
window.onload = fetchTrendingMovies();
window.onload = fetchTopRatedMovies();
window.onload = fetchUpcomingMovies();
