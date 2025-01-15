async function addFavouriteMovie(movieId) {
    const token = localStorage.getItem('jwtToken'); // Retrieve the token from local storage

    if (!token) {
        alert("You need to log in to add a favorite movie.");
        return;
    }

    try {
        const response = await fetch('http://localhost:5000/api/user/add-favourite', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}` // Include the token in the Authorization header
            },
            body: JSON.stringify({ movieId }) // Sending only the TMDB movieId
        });

        if (response.ok) {
            const data = await response.json();
            alert(data.message); // Show success message
        } else {
            const contentType = response.headers.get("content-type");
            if (contentType && contentType.includes("application/json")) {
                const errorData = await response.json();
                if (errorData.message === "Movie is already in your favorites.") {
                    alert("This movie is already in your favorites."); // Specific alert for duplicate movie
                } else {
                    alert(`Failed to add favorite: ${errorData.message}`);
                }
            } else {
                const errorText = await response.text();
                console.error('Error:', errorText);
                alert('An error occurred: ' + errorText);
            }
        }
    } catch (error) {
        console.error('Error adding favorite:', error);
        alert('An error occurred while adding the favorite movie. Please try again.');
    }
}
