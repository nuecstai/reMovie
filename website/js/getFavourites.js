async function fetchUserFavorites() {
    try {
        const response = await fetch('http://localhost:5000/api/user/favourites', {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('jwtToken')}` // Add JWT token from local storage
            }
        });

        if (!response.ok) {
            const errorData = await response.json(); // Get error details from the response
            throw new Error(errorData.message || 'Failed to fetch favourite movies');
        }

        const favouriteMovies = await response.json();
        console.log(favouriteMovies); // Debugging: Check the received data

        // Fetch complete movie data from TMDB for each favorite movie
        const moviePromises = favouriteMovies.map(async (favMovie) => {
            const movieResponse = await fetch(`https://api.themoviedb.org/3/movie/${favMovie.tmdbMovieId}?api_key=YOUR_API_KEY`);
            if (!movieResponse.ok) {
                throw new Error(`Failed to fetch movie with ID ${favMovie.tmdbMovieId}`);
            }
            return await movieResponse.json();
        });

        // Wait for all movie data to be fetched
        const completeMovies = await Promise.all(moviePromises);

        // Call the function to render movies in the DOM
        renderFavouriteMovies(completeMovies);
    } catch (error) {
        console.error('Error fetching favourite movies:', error);
    }
}

function renderFavouriteMovies(movies) {
    const favouriteMoviesContainer = document.getElementById('favourite-movies-container');
    favouriteMoviesContainer.innerHTML = ''; // Clear the container before rendering new content

    if (movies.length === 0) {
        // If no favorite movies, display a message
        favouriteMoviesContainer.innerHTML = `
            <div class="no-favourites-message">
                <p style="color: white">You have no favorite movies. Start adding some!</p>
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
                <button class="remove-favourite-btn" data-movie-id="${movie.id}">×</button>
                </div>
                <div class="product__item__text"><a href="movie-details.html?id=${movie.id}">
                    <h5>${movie.title}</a></h5>
                </div>
            </div>
        `;

        favouriteMoviesContainer.appendChild(movieItem);
    });

    // Attach event listeners to the "Remove" buttons
    const removeButtons = document.querySelectorAll('.remove-favourite-btn');
    removeButtons.forEach(button => {
        button.addEventListener('click', async (e) => {
            const movieId = e.target.getAttribute('data-movie-id');
            await removeFromFavourites(movieId);
        });
    });
}


async function removeFromFavourites(movieId) {
    try {
        const response = await fetch('http://localhost:5000/api/user/remove-favourite', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('jwtToken')}`, // Add JWT token from local storage
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ MovieId: movieId }) // Send the movie ID to remove
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Failed to remove movie from favorites');
        }

        // After successful removal, re-fetch the favorites to update the UI
        console.log(`Movie with ID ${movieId} removed from favorites.`);
        fetchUserFavorites(); // Re-fetch and render updated favorites
    } catch (error) {
        console.error('Error removing movie from favorites:', error);
    }
}

document.addEventListener('DOMContentLoaded', fetchUserFavorites);
