import 'package:flutter/material.dart';

class MovieSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        // Close the search delegate and return to the homepage
        close(context, ''); // Close without any query result
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      close(context, query); // Close the search after the current frame.
    });

    // Return an empty container since the search UI is closing.
    return Container();
  }


  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
