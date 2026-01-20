import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/movie_model.dart';
import '../database/database_helper.dart';
import 'configure_movie_screen.dart';

class MoviesListScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const MoviesListScreen({super.key, this.onThemeChanged});

  @override
  State<MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends State<MoviesListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<MovieModel> _movies = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    final movies = await _dbHelper.getAllMovies();
    setState(() {
      _movies = movies;
    });
  }

  void _navigateToAddEditScreen(int? movieID) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfigureMovieScreen(movieId: movieID),
      ),
    );

    if (result == true) {
      _loadMovies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My favourite movies'),
      ),
      body: _movies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Нет фильмов в списке',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _movies.length,
              itemBuilder: (context, index) {
                final movie = _movies[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.movie),
                    ),
                    title: Text(
                      movie.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (movie.yearPublished != null)
                          Text('Year published: ${movie.yearPublished}'),
                        if (movie.genres.isNotEmpty)
                          Text('Genres: ${movie.genres.join(', ')}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _navigateToAddEditScreen(movie.id),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToAddEditScreen(movie.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}