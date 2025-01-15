import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteMoviesScreen extends StatefulWidget {
  const FavoriteMoviesScreen({super.key});

  @override
  _FavoriteMoviesScreenState createState() => _FavoriteMoviesScreenState();
}

class _FavoriteMoviesScreenState extends State<FavoriteMoviesScreen> {
  List<Map<String, dynamic>> favouriteMovies = [];
  List<Map<String, dynamic>> watchlistMovies = [];
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  // Check if the user is logged in by checking the token in SharedPreferences
  Future<void> checkLoginStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      setState(() {
        isLoggedIn = token != null;
      });

      if (isLoggedIn) {
        // Await both fetches and handle errors if needed
        await Future.wait([
          fetchUserFavorites(),
          fetchUserWatchlist(),
        ]);
      }
    } catch (e) {
      print("Error in checkLoginStatus: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  final String apiKey = 'YOUR_API_KEY';
  final String baseUrl = 'https://api.themoviedb.org/3';

  // Function to fetch movie details using TMDBMovieId
  Future<Map<String, dynamic>> fetchMovieDetailsById(int tmdbMovieId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/movie/$tmdbMovieId?api_key=$apiKey&language=en-US'));

      if (response.statusCode == 200) {
        final movieData = json.decode(response.body);
        return {
          'title': movieData['title'],
          'poster_path': 'https://image.tmdb.org/t/p/w500${movieData['poster_path']}',
          'overview': movieData['overview'],
          'release_date': movieData['release_date'],
          'genres': movieData['genres'].map((genre) => genre['name']).toList(),
          'id': tmdbMovieId,
        };
      } else {
        print('Failed to fetch movie details for movie ID: $tmdbMovieId');
        return {};
      }
    } catch (e) {
      print('Error fetching movie details by ID: $e');
      return {};
    }
  }

  // Function to fetch user's favorite movies
  Future<void> fetchUserFavorites() async {
    await _fetchUserMovies('favourites', (movies) {
      setState(() {
        favouriteMovies = movies;
      });
    });
  }

  // Function to fetch user's watchlist movies
  Future<void> fetchUserWatchlist() async {
    await _fetchUserMovies('watchlist', (movies) {
      setState(() {
        watchlistMovies = movies;
      });
    });
  }

  // Generic function to fetch movies from backend
  Future<void> _fetchUserMovies(String endpoint, Function(List<Map<String, dynamic>>) updateList) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/user/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        List<Map<String, dynamic>> moviesDetails = [];
        for (var movie in data) {
          final tmdbMovieId = movie['tmdbMovieId'];
          final movieDetails = await fetchMovieDetailsById(tmdbMovieId);
          if (movieDetails.isNotEmpty) {
            moviesDetails.add(movieDetails);
          }
        }

        updateList(moviesDetails);
      } else {
        throw Exception('Failed to load $endpoint movies');
      }
    } catch (e) {
      print('Error fetching $endpoint movies: $e');
    }
  }

  // Retrieve the JWT token from SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Remove a movie from the user's watchlist
  Future<void> removeFromWatchlist(int movieId) async {
    await _removeMovie('remove-watchlist', movieId, fetchUserWatchlist);
  }

  // Remove a movie from the user's favorites
  Future<void> removeFromFavourites(int movieId) async {
    await _removeMovie('remove-favourite', movieId, fetchUserFavorites);
  }

  // Generic function to remove a movie
  Future<void> _removeMovie(String endpoint, int movieId, Function refreshList) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/user/$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'MovieId': movieId}),
      );

      if (response.statusCode == 200) {
        refreshList();
      } else {
        throw Exception('Failed to remove movie');
      }
    } catch (e) {
      print('Error removing movie: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Movies', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white, // Set back button color to white
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : !isLoggedIn
              ? const Center(child: Text('You need to log in to view your movies', style: TextStyle(color: Colors.white)))
              : ListView(
                  children: [
                    _buildMovieSection('Favorites', favouriteMovies, removeFromFavourites),
                    _buildMovieSection('Watchlist', watchlistMovies, removeFromWatchlist),
                  ],
                ),
    );
  }

  Widget _buildMovieSection(String title, List<Map<String, dynamic>> movies, Function(int) onRemove) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        movies.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No movies here yet', style: TextStyle(color: Colors.white)),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.6,
                ),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    color: Colors.black,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          movie['poster_path'],
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.cover,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            movie['title'] ?? 'No Title',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => onRemove(movie['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}
