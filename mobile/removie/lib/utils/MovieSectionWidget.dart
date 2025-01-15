import 'package:flutter/material.dart';

class MovieSectionWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> movies;
  final Function(int) onMovieTap;

  const MovieSectionWidget({super.key, required this.title, required this.movies, required this.onMovieTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        if (movies.isNotEmpty)
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => onMovieTap(movies[index]['id']),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          movies[index]['poster_path']!,
                          fit: BoxFit.cover,
                          height: 180,
                          width: 120,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movies[index]['title']!,
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
      ],
    );
  }
}
