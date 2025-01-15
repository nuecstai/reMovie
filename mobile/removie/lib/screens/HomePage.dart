import 'package:flutter/material.dart';
import 'package:removie/screens/LoginPage.dart';
import 'package:removie/utils/MovieSearchDelegate.dart';
import 'package:removie/screens/ProfilePage.dart';
import 'package:removie/screens/movie_details_screen.dart';
import '../utils/carousel_widget.dart';
import '../utils/MovieSectionWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/tmdb_api.dart';
import 'package:removie/screens/favourite_movies_screen.dart';
import 'search_results_screen.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool isLoggedIn = false;
  String selectedGenre = 'Action'; // Default genre
  List<Map<String, dynamic>> popularMovies = [];
  List<Map<String, dynamic>> topRatedMovies = [];
  List<Map<String, dynamic>> upcomingMovies = [];
  List<Map<String, dynamic>> genreMovies = [];

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    fetchMovieData();
    fetchMoviesByGenre(selectedGenre);
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    setState(() {
      isLoggedIn = token != null;
    });
  }

  Future<void> fetchMovieData() async {
    TMDBApi tmdbApi = TMDBApi();
    Map<String, dynamic> movieData = await tmdbApi.fetchMovieData();
    
    setState(() {
      popularMovies = movieData['popularMovies'];
      topRatedMovies = movieData['topRatedMovies'];
      upcomingMovies = movieData['upcomingMovies'];
    });
  }

  // Fetch movies based on the selected genre
  Future<void> fetchMoviesByGenre(String genre) async {
    TMDBApi tmdbApi = TMDBApi();
    List<Map<String, dynamic>> genreData = await tmdbApi.fetchMoviesByGenre(genre);
    setState(() {
      genreMovies = genreData;
      selectedGenre = genre;
    });
  }

  void navigateToMovieDetails(int movieId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MovieDetailsScreen(movieId: movieId)),
    );
  }

  // Handle Bottom Navigation Bar taps
  void _onItemTapped(int index) {
  if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoriteMoviesScreen(),
      ),
    );
  } else {
    setState(() {
      _selectedIndex = index;
    });
  }
}

  // Navigate to Search Results Screen
  void navigateToSearchResults(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(query: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200, 
              height: 200,
              child: Image.asset('assets/images/logo.png'),
            ),
          ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final query = await showSearch(
                context: context,
                delegate: MovieSearchDelegate(),
              );
              if (query != null) {
                navigateToSearchResults(query);
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ListView(
            children: [
              if (popularMovies.isEmpty)
                const Center(
                  child: Text(
                    'No movies available',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              else
                CarouselWidget(
                  movies: popularMovies,
                  onMovieTap: navigateToMovieDetails,
                ),
              const SizedBox(height: 30),
              MovieSectionWidget(
                title: 'Top Rated Movies',
                movies: topRatedMovies,
                onMovieTap: navigateToMovieDetails,
              ),
              MovieSectionWidget(
                title: 'Upcoming Movies',
                movies: upcomingMovies,
                onMovieTap: navigateToMovieDetails,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Text(
                      "Select Genre: ",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    DropdownButton<String>(
                      value: selectedGenre,
                      dropdownColor: Colors.black,
                      iconEnabledColor: Colors.white,
                      items: <String>[
                        'Action', 'Adventure', 'Animation', 'Comedy', 'Crime',
                        'Documentary', 'Drama', 'Family', 'Fantasy', 'History',
                        'Horror', 'Music', 'Mystery', 'Romance', 'Science Fiction',
                        'TV Movie', 'Thriller', 'War', 'Western'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedGenre = newValue!;
                        });
                        fetchMoviesByGenre(selectedGenre);
                      },
                      menuMaxHeight: 200,
                    ),
                  ],
                ),
              ),
              MovieSectionWidget(
                title: 'Movies in $selectedGenre',
                movies: genreMovies,
                onMovieTap: navigateToMovieDetails,
              ),
            ],
          ),
          Container(color: Colors.green, child: const Center(child: Text('Favs Page Placeholder'))),
          // Always provide a valid widget for Profile
          isLoggedIn ? const ProfilePage() : const LoginPage(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
