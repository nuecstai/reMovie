import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class CarouselWidget extends StatelessWidget {
  final List<Map<String, dynamic>> movies;
  final Function(int) onMovieTap;

  const CarouselWidget({super.key, required this.movies, required this.onMovieTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Popular Movies',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        if (movies.isNotEmpty)
          CarouselSlider(
            options: CarouselOptions(
              height: 200,
              autoPlay: true,
              viewportFraction: 0.8,
              enlargeCenterPage: true, 
            ),
            items: movies.map((movie) {
              return Builder(
                builder: (BuildContext context) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: GestureDetector(
                      onTap: () => onMovieTap(movie['id']),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(movie['backdrop_path']!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            child: Text(
                              movie['title']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                backgroundColor: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}
