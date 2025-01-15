// Initialize the hero carousel
const hero_s = $(".hero__slider");

hero_s.owlCarousel({
    loop: true,
    margin: 0,
    items: 1,
    dots: true,
    nav: true,
    navText: ["<span class='arrow_carrot-left'></span>", "<span class='arrow_carrot-right'></span>"],
    animateOut: 'fadeOut',
    animateIn: 'fadeIn',
    smartSpeed: 1200,
    autoHeight: false,
    autoplay: true,
    mouseDrag: false
});

// Function to fetch popular movies
async function fetchPopularMovies() {
    const API_KEY = 'YOUR_API_KEY';
    const url = `https://api.themoviedb.org/3/movie/popular?api_key=${API_KEY}&language=en-US&page=1`;
    try {
        const response = await fetch(url);
        const data = await response.json();
        return data.results.slice(0, 5); // Get the first 4 popular movies
    } catch (error) {
        console.error("Error fetching popular movies:", error);
        return [];
    }
}

// Function to create carousel items for popular movies
function createCarouselItems(movies) {
    const carouselContainer = $(".hero__slider");
    carouselContainer.empty(); // Clear the existing content

    movies.forEach(movie => {
        const backdropPath = `https://image.tmdb.org/t/p/w1280${movie.backdrop_path}`;

        const movieItem = `
            <div class="hero__items set-bg" style="background-image: url(${backdropPath});">
                <div class="row">
                    <div class="col-lg-6">
                        <div class="hero__text">
                            <h2>${movie.title}</h2>
                            <p>${movie.overview}</p>
                            <a href="movie-details.html?id=${movie.id}"><span>Details</span> <i class="fa fa-angle-right"></i></a>
                        </div>
                    </div>
                </div>
            </div>
        `;

        carouselContainer.append(movieItem); // Append the item to the carousel container
    });

    // After dynamically appending the items, re-initialize Owl Carousel
    hero_s.trigger('destroy.owl.carousel');
    hero_s.owlCarousel({
        loop: true,
        margin: 0,
        items: 1,
        dots: true,
        nav: true,
        navText: ["<span class='arrow_carrot-left'></span>", "<span class='arrow_carrot-right'></span>"],
        animateOut: 'fadeOut',
        animateIn: 'fadeIn',
        smartSpeed: 1200,
        autoHeight: false,
        autoplay: true,
        mouseDrag: false
    });
}

// Initialize and load popular movies into the carousel
async function initializeCarousel() {
    const popularMovies = await fetchPopularMovies();
    createCarouselItems(popularMovies); // Populate the carousel with the fetched movies
}

// Call the function when the page loads
initializeCarousel();
