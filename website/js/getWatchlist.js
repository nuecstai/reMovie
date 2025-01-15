async function fetchUserWatchlist() {
    try {
        const response = await fetch('http://localhost:5000/api/user/watchlist', {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('jwtToken')}` // Add JWT token from local storage
            }
        });

        if (!response.ok) {
            const errorData = await response.json(); // Get error details from the response
            throw new Error(errorData.message || 'Failed to fetch watchlist movies');
        }

        const watchlistMovies = await response.json();
        console.log(watchlistMovies); // Debugging: Check the received data

        // Fetch complete movie data from TMDB for each watchlist movie
        const moviePromises = watchlistMovies.map(async (watchMovie) => {
            const movieResponse = await fetch(`https://api.themoviedb.org/3/movie/${watchMovie.tmdbMovieId}?api_key=YOUR_API_KEY`);
            if (!movieResponse.ok) {
                throw new Error(`Failed to fetch movie with ID ${watchMovie.tmdbMovieId}`);
            }
            return await movieResponse.json();
        });

        // Wait for all movie data to be fetched
        const completeMovies = await Promise.all(moviePromises);

        // Call the function to render movies in the DOM
        renderWatchlistMovies(completeMovies);
    } catch (error) {
        console.error('Error fetching watchlist movies:', error);
    }
}

function renderWatchlistMovies(movies) {
    const watchlistContainer = document.getElementById('watchlist-container');
    watchlistContainer.innerHTML = ''; // Clear the container before rendering new content

    if (movies.length === 0) {
        // If no watchlist movies, display a message
        watchlistContainer.innerHTML = `
            <div class="no-watchlist-message">
                <p style="color: white">You have no movies in your watchlist. Start adding some!</p>
            </div>
        `;
        return; // Exit the function as there's nothing more to render
    }

    movies.forEach(movie => {
        const movieItem = document.createElement('div');
        movieItem.classList.add('col-lg-3', 'col-md-6', 'col-sm-6');

        // Set the movie poster image or a default image if not available
        const posterPath = movie.poster_path ? `https://image.tmdb.org/t/p/w500${movie.poster_path}` : 'path/to/default-image.jpg';

        movieItem.innerHTML = `
            <div class="product__item">
                <div class="product__item__pic set-bg" style="background-image: url(${posterPath});">
                <button class="remove-watchlist-btn" data-movie-id="${movie.id}">×</button>
                </div>
                <div class="product__item__text"><a href="movie-details.html?id=${movie.id}">
                    <h5>${movie.title}</a></h5>
                </div>
            </div>
        `;

        watchlistContainer.appendChild(movieItem);
    });

    // Attach event listeners to the "Remove" buttons
    const removeButtons = document.querySelectorAll('.remove-watchlist-btn');
    removeButtons.forEach(button => {
        button.addEventListener('click', async (e) => {
            const movieId = e.target.getAttribute('data-movie-id');
            await removeFromWatchlist(movieId);
        });
    });
}

async function removeFromWatchlist(movieId) {
    try {
        const response = await fetch('http://localhost:5000/api/user/remove-watchlist', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('jwtToken')}`, // Add JWT token from local storage
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ MovieId: movieId }) // Send the movie ID to remove
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Failed to remove movie from watchlist');
        }

        // After successful removal, re-fetch the watchlist to update the UI
        console.log(`Movie with ID ${movieId} removed from watchlist.`);
        fetchUserWatchlist(); // Re-fetch and render updated watchlist
    } catch (error) {
        console.error('Error removing movie from watchlist:', error);
    }
}

document.addEventListener('DOMContentLoaded', fetchUserWatchlist);
