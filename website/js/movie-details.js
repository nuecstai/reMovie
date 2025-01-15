// api key and movie id parameters

const API_KEY = 'YOUR_API_KEY';
const movieId = new URLSearchParams(window.location.search).get('id');

// function to get movie details
async function fetchMovieDetails(movieId) {
    const url = `https://api.themoviedb.org/3/movie/${movieId}?api_key=${API_KEY}&language=en-US`;
    try {
        const response = await fetch(url);
        const movie = await response.json();
        displayMovieDetails(movie);
    } catch (error) {
        console.error("Error fetching movie details:", error);
    }
}

// function to display movie details
function displayMovieDetails(movie) {
    document.querySelector('.anime__details__title h3').textContent = movie.title;

    const originalTitle = movie.original_title ? `(${movie.original_title})` : '';
    document.querySelector('.anime__details__title span').textContent = originalTitle;

    document.querySelector('.anime__details__text p').textContent = movie.overview;

    const ratingElement = document.querySelector('.anime__details__rating span');
    if (ratingElement) ratingElement.textContent = `${movie.vote_count} Votes`;

    const starsContainer = document.querySelector('.anime__details__rating .rating');
    if (starsContainer) {
        starsContainer.innerHTML = '';
        const totalStars = 5;
        const fullStars = Math.floor(movie.vote_average / 2);

        for (let i = 0; i < totalStars; i++) {
            if (i < fullStars) {
                starsContainer.innerHTML += '<a><i class="fa fa-star"></i></a>';
            } else if (i === fullStars && movie.vote_average % 2 !== 0) {
                starsContainer.innerHTML += '<a><i class="fa fa-star-half-o"></i></a>';
            } else {
                starsContainer.innerHTML += '<a><i class="fa fa-star-o"></i></a>';
            }
        }
    }

    const detailsLeft = document.querySelector('.anime__details__widget .col-lg-6');
    if (detailsLeft) {
        detailsLeft.innerHTML = `
            <li><span>Studios:</span> ${movie.production_companies.map(company => company.name).join(', ') || 'N/A'}</li>
            <li><span>Date aired:</span> ${movie.release_date || 'N/A'}</li>
            <li><span>Genre:</span> ${movie.genres.map(genre => genre.name).join(', ') || 'N/A'}</li>
        `;
    }

    const detailsRight = document.querySelector('.anime__details__widget .col-lg-5');
    if (detailsRight) {
        detailsRight.innerHTML = `
            <li><span>Scores:</span> ${movie.vote_average}</li>
            <li><span>Rating:</span> ${movie.adult ? '18+' : 'PG-13'}</li>
            <li><span>Duration:</span> ${movie.runtime} min</li>
        `;
    }

    const posterPath = `https://image.tmdb.org/t/p/w500${movie.poster_path}`;
    const posterElement = document.querySelector('.anime__details__pic');
    if (posterElement) posterElement.style.backgroundImage = `url(${posterPath})`;

    document.querySelector('.follow-btn').href = '#';
}

fetchMovieDetails(movieId);

// function to get similar movies
async function fetchSimilarMovies(movieId) {
    const url = `https://api.themoviedb.org/3/movie/${movieId}/similar?api_key=${API_KEY}&language=en-US&page=1`;
    try {
        const response = await fetch(url);
        const data = await response.json();
        return data.results;
    } catch (error) {
        console.error("Error fetching similar movies:", error);
        return [];
    }
}

// function to display similar movies
function displaySimilarMovies(movies) {
    const sidebarContainer = document.querySelector('.anime__details__sidebar');
    if (!sidebarContainer) return;

    sidebarContainer.innerHTML = '';
    const sectionTitle = document.createElement('div');
    sectionTitle.classList.add('section-title');
    sectionTitle.innerHTML = '<h5>You Might Like...</h5>';
    sidebarContainer.appendChild(sectionTitle);

    movies = movies.slice(0,5)

    movies.forEach(movie => {
        const movieItem = document.createElement('div');
        movieItem.classList.add('product__sidebar__view__item', 'set-bg');
        const backdropPath = `https://image.tmdb.org/t/p/w500${movie.backdrop_path}`;

        movieItem.style.backgroundImage = `url(${backdropPath})`;
        movieItem.innerHTML = `
            <div class="view"><i class="fa fa-eye"></i>${movie.popularity}</div>
            <h5><a href="movie-details.html?id=${movie.id}">${movie.title}</a></h5>
        `;

        sidebarContainer.appendChild(movieItem);
    });
}

async function fetchMightLike(movieId) {
    const similarMovies = await fetchSimilarMovies(movieId);
    displaySimilarMovies(similarMovies);
}

fetchMightLike(movieId);

// listener for add favorites button
document.addEventListener("DOMContentLoaded", () => {
    const addFavouriteButton = document.getElementById("addFavourites");

    if (addFavouriteButton) {
        addFavouriteButton.addEventListener("click", () => {
            addFavouriteMovie(movieId);
        });
    } else {
        console.log("Add Favourites button not found.");
    }
});

// listener for add watchlist button
document.addEventListener("DOMContentLoaded", () => {
    const addWatchlistButton = document.getElementById("addWatchlist");

    if (addWatchlistButton) {
        addWatchlistButton.addEventListener("click", () => {
            addWatchlistMovie(movieId);
        });
    } else {
        console.log("Add Watchlist button not found.");
    }
});

// function to get reviews for the movie
async function fetchReviews(movieId) {
    try {
        const response = await fetch(`http://localhost:5000/api/review/${movieId}/reviews`);
        console.log("Response Status: ", response.status); // Log the response status

        if (response.ok) {
            const reviews = await response.json();
            console.log("Fetched reviews: ", reviews); // Log the reviews data
            return reviews; // Return reviews to be used in loadReviews
        } else {
            console.error('Failed to fetch reviews:', response.statusText);
            return []; // Return an empty array in case of failure
        }
    } catch (error) {
        console.error('Error fetching reviews:', error);
        return []; // Return an empty array in case of error
    }
}

// function to delete review
async function deleteReview(reviewId) {
    try {
        const response = await fetch(`http://localhost:5000/api/review/${reviewId}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('jwtToken')}` // Pass token for authorization
            }
        });

        if (response.ok) {
            alert('Review deleted successfully.');
            loadReviews(movieId); // Reload reviews after deletion
        } else {
            const errorData = await response.json();
            alert(errorData.message || 'Error deleting review.');
        }
    } catch (error) {
        console.error('Error deleting review:', error);
        alert('An error occurred while deleting the review.');
    }
}

// function to get movie reviews
async function loadReviews(movieId) {
    try {
        const reviews = await fetchReviews(movieId); // Get reviews data
        const reviewsContainer = document.getElementById('reviewsContainer');
        const noReviewsMessage = document.getElementById('noReviewsMessage');

        let loggedInUsername = '';
        const token = localStorage.getItem('jwtToken');
        if (token) {
            const decoded = jwt_decode(token);
            loggedInUsername = decoded.sub;
        }

        if (!reviewsContainer || !noReviewsMessage) {
            console.error('Review container or "no reviews" message element not found.');
            return;
        }

        reviewsContainer.innerHTML = ''; // Clear current reviews

        if (!Array.isArray(reviews) || reviews.length === 0) {
            noReviewsMessage.style.display = 'block';
        } else {
            noReviewsMessage.style.display = 'none';

            reviews.forEach(review => {
                const reviewElement = document.createElement('div');
                reviewElement.classList.add('anime__review__item');
                reviewElement.setAttribute('data-review-id', review.id); // Set the data attribute

                const actionButtons = (review.user.username === loggedInUsername || loggedInUsername === 'admin')
                    ? `<div class="review-actions">
                            <button class="editReviewButton" data-review-id="${review.id}">
                                <i class="fa fa-pencil"></i>
                            </button>
                            <button class="deleteReviewButton" data-review-id="${review.id}">
                                <i class="fa fa-trash"></i>
                            </button>
                        </div>`
                    : '';

                // Create the review content HTML structure
                reviewElement.innerHTML = `
                    <div class="anime__review__item__pic">
                        <img src="img/anime/review-1.jpg" alt="Reviewer Avatar">
                    </div>
                    <div class="anime__review__item__text">
                        <h6>${review.user.username} - <span>${new Date().toLocaleTimeString()}</span></h6>
                        <p>${review.content}</p>
                        ${actionButtons}
                        <div class="rating">
                            <span class="rating-number">${review.rating}/5</span> 
                            <span class="rating-star">★</span>
                        </div>
                    </div>
                `;

                if (review.user.username === loggedInUsername) {
                    const editButton = reviewElement.querySelector('.editReviewButton');
                    editButton.addEventListener('click', () => showEditForm(review.id, review.content, review.rating));
                }

                reviewsContainer.appendChild(reviewElement);
            });

            // Add event listener to delete buttons
            document.querySelectorAll('.deleteReviewButton').forEach(button => {
                button.addEventListener('click', async (event) => {
                    const reviewId = event.currentTarget.getAttribute('data-review-id'); // Use currentTarget
                    if (reviewId) {
                        await deleteReview(reviewId); // Call delete function
                        await loadReviews(movieId); // Reload reviews
                    } else {
                        console.error('Review ID is null.');
                    }
                });
            });

        }
    } catch (error) {
        console.error('Error loading reviews:', error);
    }
}


// function to add review
document.addEventListener('DOMContentLoaded', function () {
    const stars = document.querySelectorAll('.star');
    const reviewRating = document.getElementById('reviewRating');
    const reviewContent = document.getElementById('reviewContent');
    let selectedRating = 0;

    // Highlight the hovered star
    stars.forEach(star => {
        star.addEventListener('mouseenter', () => {
            const value = parseInt(star.getAttribute('data-value'));
            highlightHoveredStar(value);
        });

        star.addEventListener('mouseleave', () => {
            highlightHoveredStar(selectedRating);
        });

        star.addEventListener('click', () => {
            selectedRating = parseInt(star.getAttribute('data-value'));
            reviewRating.value = selectedRating;
            highlightHoveredStar(selectedRating); // Update the selected rating after click
        });
    });

    // Function to highlight only the hovered star
    function highlightHoveredStar(rating) {
        stars.forEach(star => {
            const value = parseInt(star.getAttribute('data-value'));
            if (value <= rating) {
                star.classList.add('hover');
            } else {
                star.classList.remove('hover');
            }
        });
    }

    // Submit form
    document.getElementById('reviewForm').addEventListener('submit', async function (e) {
        e.preventDefault();
        const content = reviewContent.value;
        const rating = selectedRating;

        if (!content || rating === 0) {
            alert('Please provide both a comment and a rating.');
            return;
        }

        try {
            // Send the review data to the server (modify the API URL as needed)
            const response = await fetch('http://localhost:5000/api/review/add', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('jwtToken')}`
                },
                body: JSON.stringify({
                    tmdbMovieId: movieId, // Pass the movieId here
                    content: content,
                    rating: rating
                })
            });

            if (response.ok) {
                const data = await response.json();
                alert(data.message);

                // Optionally reload reviews here
                loadReviews(movieId);

                // Clear the text field and reset selected stars
                reviewContent.value = ''; // Clear the text area
                reviewRating.value = ''; // Clear the hidden rating input
                selectedRating = 0; // Reset the selected rating

                // Remove the 'selected' and 'hover' classes from all stars
                stars.forEach(star => {
                    star.classList.remove('selected', 'hover');
                });
            } else {
                const errorData = await response.json();
                alert(`Failed to add review: ${errorData.message}`);
            }
        } catch (error) {
            console.error('Error adding review:', error);
            alert('An error occurred while adding the review.');
        }
    });
});

document.addEventListener('DOMContentLoaded', () => {
    // Now safe to run your functions
    loadReviews(movieId);
});

// function to edit review
async function editReview(reviewId, updatedContent, updatedRating) {
    try {
        const response = await fetch(`http://localhost:5000/api/review/${reviewId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('jwtToken')}` // Pass token for authorization
            },
            body: JSON.stringify({
                content: updatedContent,
                rating: updatedRating
            })
        });

        if (response.ok) {
            alert('Review updated successfully.');
            loadReviews(movieId); // Reload reviews after editing
        } else {
            const errorData = await response.json();
            alert(errorData.message || 'Error editing review.');
        }
    } catch (error) {
        console.error('Error editing review:', error);
        alert('An error occurred while editing the review.');
    }
}

// function for edit form
function showEditForm(reviewId, currentContent, currentRating) {
    // Find the review element
    const reviewElement = document.querySelector(`.anime__review__item[data-review-id="${reviewId}"]`);
    if (!reviewElement) return;

    // Get the position of the review element relative to the viewport
    const rect = reviewElement.getBoundingClientRect();

    // Remove any existing edit form
    const existingForm = document.querySelector('.edit-form');
    if (existingForm) existingForm.remove();

    // Create the edit form
    const editForm = document.createElement('div');
    editForm.classList.add('edit-form');
    editForm.innerHTML = `
        <textarea id="editContent">${currentContent}</textarea>
        <div class="star-rating">
            ${[1, 2, 3, 4, 5].map(i => `
                <span class="star" data-value="${i}">★</span>
            `).join('')}
        </div>
        <div class="edit-form-buttons">
            <button class="saveButton">Save</button>
            <button class="cancelButton">Cancel</button>
        </div>
    `;

    // Append the form to the body
    document.body.appendChild(editForm);

    // Position the edit form near the center of the review item
    const formWidth = editForm.offsetWidth; // Get the width of the form
    const formHeight = editForm.offsetHeight; // Get the height of the form

    editForm.style.position = 'absolute';
    editForm.style.top = `${rect.top + window.scrollY + (rect.height / 2) - (formHeight / 2)}px`; // Vertically center
    editForm.style.left = `${rect.left + window.scrollX + (rect.width / 2) - (formWidth / 2)}px`; // Horizontally center

    // Select the stars in the edit form
    const stars = editForm.querySelectorAll('.star');
    let selectedRating = currentRating;

    // Function to highlight the hovered star
    function highlightHoveredStar(stars, rating) {
        stars.forEach(star => {
            const value = parseInt(star.getAttribute('data-value'));
            if (value <= rating) {
                star.classList.add('hover', 'filled'); // Add filled class for selected rating
            } else {
                star.classList.remove('hover', 'filled');
            }
        });
    }

    // Initialize the stars with the current rating
    highlightHoveredStar(stars, selectedRating); // Highlight stars based on the current rating

    // Highlight the hovered star
    stars.forEach(star => {
        star.addEventListener('mouseenter', () => {
            const value = parseInt(star.getAttribute('data-value'));
            highlightHoveredStar(stars, value);
        });

        star.addEventListener('mouseleave', () => {
            highlightHoveredStar(stars, selectedRating);
        });

        star.addEventListener('click', () => {
            selectedRating = parseInt(star.getAttribute('data-value'));
            highlightHoveredStar(stars, selectedRating);
        });
    });

    // Attach event listener for Save button
    const saveButton = editForm.querySelector('.saveButton');
    saveButton.addEventListener('click', () => submitEdit(reviewId, selectedRating));

    // Attach event listener for Cancel button
    const cancelButton = editForm.querySelector('.cancelButton');
    cancelButton.addEventListener('click', cancelEdit);
}

function cancelEdit() {
    const editFormOverlay = document.querySelector('.edit-form');
    if (editFormOverlay) editFormOverlay.remove();
}

async function submitEdit(reviewId, updatedRating) {
    const updatedContent = document.getElementById('editContent').value;

    if (!updatedContent.trim()) {
        alert('Content cannot be empty.');
        return;
    }

    await editReview(reviewId, updatedContent, updatedRating);

    cancelEdit(); // Remove the edit form after saving
}
