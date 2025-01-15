import 'dart:convert';
import 'package:http/http.dart' as http;

class TMDBApi {
  final String apiKey = 'YOUR_API_KEY';
  final String baseUrl = 'https://api.themoviedb.org/3';

  // Function to fetch movie data
  Future<Map<String, dynamic>> fetchMovieData() async {
    final Map<String, dynamic> movieData = {
      'popularMovies': [],
      'topRatedMovies': [],
      'upcomingMovies': []
    };

    try {
      // Fetch popular movies
      final popularResponse = await http.get(Uri.parse('$baseUrl/movie/popular?api_key=$apiKey'));
      if (popularResponse.statusCode == 200) {
        final popularData = json.decode(popularResponse.body);
        movieData['popularMovies'] = (popularData['results'] as List)
            .map((movie) => {
                  'backdrop_path': 'https://image.tmdb.org/t/p/w500${movie['backdrop_path']}',
                  'title': movie['title'],
                  'id': movie['id'],
                })
            .toList();
      }

      // Fetch top-rated movies
      final topRatedResponse = await http.get(Uri.parse('$baseUrl/movie/top_rated?api_key=$apiKey'));
      if (topRatedResponse.statusCode == 200) {
        final topRatedData = json.decode(topRatedResponse.body);
        movieData['topRatedMovies'] = (topRatedData['results'] as List)
            .map((movie) => {
                  'poster_path': 'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                  'title': movie['title'],
                  'id': movie['id'],
                })
            .toList();
      }

      // Fetch upcoming movies
      final upcomingResponse = await http.get(Uri.parse('$baseUrl/movie/upcoming?api_key=$apiKey'));
      if (upcomingResponse.statusCode == 200) {
        final upcomingData = json.decode(upcomingResponse.body);
        movieData['upcomingMovies'] = (upcomingData['results'] as List)
            .map((movie) => {
                  'poster_path': 'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                  'title': movie['title'],
                  'id': movie['id'],
                })
            .toList();
      }
    } catch (e) {
      print('Error fetching movie data: $e');
    }

    return movieData;
  }

  // Function to search for movies
  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    List<Map<String, dynamic>> searchResults = [];

    try {
      final response = await http.get(Uri.parse('$baseUrl/search/movie?api_key=$apiKey&query=$query'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        searchResults = (data['results'] as List)
            .map((movie) => {
                  'poster_path': 'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                  'title': movie['title'],
                  'id': movie['id'],
                })
            .toList();
      } else {
        print('Failed to load search results');
      }
    } catch (e) {
      print('Error searching movies: $e');
    }

    return searchResults;
  }

  // Fetch movies by genre
  Future<List<Map<String, dynamic>>> fetchMoviesByGenre(String genre) async {
    final List<Map<String, dynamic>> movieData = [];
    try {
      String genreId = _getGenreId(genre);
      final response = await http.get(Uri.parse('$baseUrl/discover/movie?api_key=$apiKey&with_genres=$genreId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        movieData.addAll((data['results'] as List)
            .map((movie) => {
                  'poster_path': 'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                  'title': movie['title'],
                  'id': movie['id'],
                })
            .toList());
      }
    } catch (e) {
      print('Error fetching movies by genre: $e');
    }
    return movieData;
  }

  // Helper method to map genre names to TMDB genre IDs
  String _getGenreId(String genre) {
    switch (genre) {
      case 'Action':
        return '28';
      case 'Adventure':
        return '12';
      case 'Animation':
        return '16';
      case 'Comedy':
        return '35';
      case 'Crime':
        return '80';
      case 'Documentary':
        return '99';
      case 'Drama':
        return '18';
      case 'Family':
        return '10751';
      case 'Fantasy':
        return '14';
      case 'History':
        return '36';
      case 'Horror':
        return '27';
      case 'Music':
        return '10402';
      case 'Mystery':
        return '9648';
      case 'Romance':
        return '10749';
      case 'Science Fiction':
        return '878';
      case 'TV Movie':
        return '10770';
      case 'Thriller':
        return '53';
      case 'War':
        return '10752';
      case 'Western':
        return '37';
      default:
        return ''; // For 'All' category, fetch all movies
    }
  }

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

  // Function to fetch user's favorite movies and their details
  Future<List<Map<String, dynamic>>> fetchUserFavorites(List<int> tmdbMovieIds) async {
    List<Map<String, dynamic>> moviesDetails = [];

    for (int tmdbMovieId in tmdbMovieIds) {
      final movieDetails = await fetchMovieDetailsById(tmdbMovieId);
      if (movieDetails.isNotEmpty) {
        moviesDetails.add(movieDetails);
      }
    }

    return moviesDetails;
  }
}
