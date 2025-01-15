import 'package:flutter/material.dart';
import 'package:removie/screens/movie_details_screen.dart';
import '../utils/tmdb_api.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    searchMovies(widget.query);
  }

  Future<void> searchMovies(String query) async {
    TMDBApi tmdbApi = TMDBApi();
    List<Map<String, dynamic>> results = await tmdbApi.searchMovies(query);
    setState(() {
      searchResults = results;
    });
  }

  void navigateToMovieDetails(int movieId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MovieDetailsScreen(movieId: movieId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white, // Set back button color to white
        ),
      ),
      backgroundColor: Colors.black, // Set background color to black
      body: searchResults.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final movie = searchResults[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Card(
                    color: Colors.black,
                    child: ListTile(
                      leading: Image.network(
                        movie['poster_path'] ?? '',
                        width: 80, // Increase poster width
                        fit: BoxFit.cover,
                      ),
                      title: Text(
                        movie['title'] ?? 'No Title',
                        style: const TextStyle(
                          color: Colors.white, // Set title color to white
                          fontWeight: FontWeight.bold,
                          fontSize: 18, // Increase font size
                        ),
                      ),
                      onTap: () => navigateToMovieDetails(movie['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
