const api_Key = '0eaa94d65e689aa18580569f96d442d8';
const genreDropdown = document.getElementById('genre-dropdown');

// Function to fetch genres and add them to the dropdown
async function fetchGenresForNavbar() {
    const url = `https://api.themoviedb.org/3/genre/movie/list?api_key=${api_Key}&language=en-US`;
    try {
        const response = await fetch(url);
        const data = await response.json();
        const genres = data.genres;

        // Populate genre dropdown
        genres.forEach(genre => {
            const genreItem = document.createElement('li');
            genreItem.innerHTML = `<a href="./movies.html?genre=${genre.id}">${genre.name}</a>`;
            genreDropdown.appendChild(genreItem);
        });
    } catch (error) {
        console.error("Error fetching genres:", error);
    }
}

// Call the function to populate genres
fetchGenresForNavbar();