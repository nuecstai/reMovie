import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieDetailsScreen extends StatefulWidget {
  final int movieId;

  const MovieDetailsScreen({super.key, required this.movieId});

  @override
  _MovieDetailsScreenState createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  late Map<String, dynamic> movieDetails = {};
  late List<Map<String, dynamic>> similarMovies = [];
  late List<Map<String, dynamic>> reviews = [];
  String loggedInUsername = '';
  bool isFavorite = false;
  bool isInWatchlist = false;

  final TextEditingController _reviewController = TextEditingController();
  double _rating = 3.0;

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
    fetchMovieReviews();
    _getUsernameFromToken();
  }

  // Fetch movie details and similar movies from TMDB API
  Future<void> fetchMovieDetails() async {
    const String apiKey = 'YOUR_API_KEY';
    const String baseUrl = 'https://api.themoviedb.org/3';

    // Movie Details
    final movieResponse = await http.get(Uri.parse('$baseUrl/movie/${widget.movieId}?api_key=$apiKey'));
    if (movieResponse.statusCode == 200) {
      final movieData = json.decode(movieResponse.body);
      setState(() {
        movieDetails = {
          'poster_path': 'https://image.tmdb.org/t/p/w500${movieData['poster_path']}',
          'title': movieData['title'],
          'overview': movieData['overview'],
          'genres': movieData['genres'],
          'release_date': movieData['release_date'],
          'vote_average': movieData['vote_average'],
          'runtime': movieData['runtime'],
          'production_companies': movieData['production_companies'],
        };
      });
    }

    // Similar Movies
    final similarResponse = await http.get(Uri.parse('$baseUrl/movie/${widget.movieId}/similar?api_key=$apiKey'));
    if (similarResponse.statusCode == 200) {
      final similarData = json.decode(similarResponse.body);
      setState(() {
        similarMovies = (similarData['results'] as List)
            .map((movie) => {
                  'id': movie['id'], // Add movie ID here
                  'poster_path': 'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                  'title': movie['title']
                })
            .toList();
      });
    }
  }

  // Function to fetch reviews
  Future<void> fetchMovieReviews() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/review/${widget.movieId}/reviews'));
      
      if (response.statusCode == 200) {
        final reviewData = json.decode(response.body);
        if (reviewData != null) {
          setState(() {
            reviews = List<Map<String, dynamic>>.from(reviewData.map((review) {
              return {
                'id': review['id'],
                'content': review['content'],
                'rating': review['rating'],
                'username': review['user'] != null ? review['user']['username'] : 'Unknown', // Prevents null error
              };
            }).toList());
          });
        }
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (error) {
    }
  }

  // Post a review
  Future<void> submitReview() async {
    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to log in to submit a review.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/review/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'TmdbMovieId': widget.movieId,
          'Content': _reviewController.text,
          'Rating': _rating.toInt(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
        _reviewController.clear();
        fetchMovieReviews();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: ${errorData['message']}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }

  // Method to delete a review
  void deleteReview(int reviewId) async {
    final token = await _getToken();
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:5000/api/review/$reviewId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          reviews.removeWhere((review) => review['id'] == reviewId);
          fetchMovieReviews();
        });
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorData['message'])));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting review: $error')));
    }
  }

  // Method to call the API to edit the review
  void editReview(int reviewId, String content, double rating) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('http://10.0.2.2:5000/api/review/$reviewId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode({
        'content': content,
        'rating': rating.toInt(),
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review updated successfully!')));
      setState(() {
        fetchMovieReviews();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update review')));
    }
  }

  // Retrieve the JWT token from SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Function to get the username from the JWT token
  Future<void> _getUsernameFromToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token'); // Retrieve the token

    if (token != null && token.isNotEmpty) {
      // Decode the token and extract the username
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // Print the decoded token for debugging purposes
      print("Decoded Token: $decodedToken");

      // Extract the username from the decoded token (change the key if necessary)
      setState(() {
        loggedInUsername = decodedToken['sub'] ?? "User"; // Ensure the key matches the token structure
      });
    } else {
      print("No token found or token is empty");
    }
  }


  // Add to Favorites
  Future<void> addFavouriteMovie() async {
    final token = await _getToken();

    if (token == null) {
      // If no token, prompt the user to log in
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You need to log in to add a favorite movie.')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/user/add-favourite'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Include the token in the Authorization header
        },
        body: json.encode({
          'movieId': widget.movieId, // Send the TMDB movie ID
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Movie added to favorites')));
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add favorite: ${errorData['message']}')));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $error')));
    }
  }

  // Method to open the Edit Review Dialog
  void _openEditReviewDialog(int reviewId, String currentContent, int currentRating) {
    final TextEditingController editContentController = TextEditingController(text: currentContent);
    double editRating = currentRating.toDouble(); // Ensure the rating starts as a double

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Review'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editContentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Edit your review...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white10,
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          editRating > index ? Icons.star : Icons.star_border, // Filled or empty star
                          color: Colors.yellow,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            editRating = index + 1; // Set the rating to the clicked star's position
                          });
                        },
                      );
                    }),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Submit the updated review
                editReview(reviewId, editContentController.text, editRating);
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }


  Future<void> addMovieToWatchlist() async {
    final token = await _getToken();

    if (token == null) {
      // If no token, prompt the user to log in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to log in to add a movie to your watchlist.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/user/add-watchlist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Include the token in the Authorization header
        },
        body: json.encode({
          'movieId': widget.movieId, // Send the TMDB movie ID
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Movie added to watchlist')),
        );
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to watchlist: ${errorData['message']}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Details', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white, // Set back button color to white
        ),
      ),
      body: movieDetails.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                Stack(
                  children: [
                    Image.network(movieDetails['poster_path']!),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context); // Go back to the previous screen
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  movieDetails['title']!,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  movieDetails['overview']!,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Genres: ${movieDetails['genres'].map((genre) => genre['name']).join(', ')}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    Text(
                      'Release Date: ${movieDetails['release_date']}',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Rating: ${movieDetails['vote_average']}',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      'Duration: ${movieDetails['runtime']} min',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        addFavouriteMovie();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Add to Favorites', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        addMovieToWatchlist();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Add to Watchlist', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'You Might Like',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                if (similarMovies.isNotEmpty)
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: similarMovies.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovieDetailsScreen(movieId: similarMovies[index]['id']),
                              ),
                            );
                          },
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: const BoxDecoration(color: Colors.black),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.network(
                                  similarMovies[index]['poster_path']!,
                                  fit: BoxFit.cover,
                                  height: 180,
                                  width: 120,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  similarMovies[index]['title']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                // Reviews Section
                const Text(
                  'User Reviews',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                if (reviews.isEmpty)
                  const Text(
                    'No reviews yet.',
                    style: TextStyle(color: Colors.white),
                  )
                else
                  Expanded(
                    child: SizedBox(
                      height: 300, // Adjust this height to control the visible number of reviews
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          // Get the rating from the review
                          int rating = reviews[index]['rating'];

                          // Build the rating string with 5 stars
                          String stars = '';
                          for (int i = 0; i < 5; i++) {
                            if (i < rating) {
                              stars += '\u2605'; // Filled star (★)
                            } else {
                              stars += '\u2606'; // Empty star (☆)
                            }
                          }

                          // Check if the current logged-in user is the author of the review
                          bool isUserReview = reviews[index]['username'] == loggedInUsername;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${reviews[index]['username']} - $stars',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                // Conditionally show the delete and edit buttons
                                if (isUserReview || loggedInUsername == 'admin')
                                  Row(
                                    children: [
                                      // Edit Button (Pencil Icon)
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.grey),
                                        onPressed: () {
                                          // Open the edit review dialog
                                          _openEditReviewDialog(reviews[index]['id'], reviews[index]['content'], reviews[index]['rating']);
                                        },
                                      ),
                                      // Delete Button (Trash Icon)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          // Call the function to delete the review (backend API)
                                          deleteReview(reviews[index]['id']);
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            subtitle: Text(reviews[index]['content'] ?? 'No content available'),
                          );
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Add Review Form
                const Text(
                  'Add Your Review',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Write your review...',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                // Star Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        _rating > index ? Icons.star : Icons.star_border, // Filled or empty star
                        color: Colors.yellow,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1; // Set rating to the clicked star index + 1
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: submitReview,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Submit Review', style: TextStyle(color: Colors.white)),
                ),

              ],
            ),
    );
  }
}