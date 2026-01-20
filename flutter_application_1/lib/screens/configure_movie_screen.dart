import 'package:flutter/material.dart';
import '../entity/movie.dart';
import '../database/database_helper.dart';
import '../models/movie_model.dart';

class ConfigureMovieScreen extends StatefulWidget {
  final int? movieId;

  const ConfigureMovieScreen({super.key, this.movieId});

  @override
  State<ConfigureMovieScreen> createState() => _ConfigureMovieScreenState();
}

class _ConfigureMovieScreenState extends State<ConfigureMovieScreen> {
  final __formKey = GlobalKey<FormState>();
  final __titleController = TextEditingController();
  final __yearController = TextEditingController();
  final __genreController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool __isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.movieId != null) {
      __loadMovie();
    }
  }

  @override
  void dispose() {
    __titleController.dispose();
    __yearController.dispose();
    __genreController.dispose();
    super.dispose();
  }

  Future<void> __loadMovie() async {
    setState(() {
      __isLoading = true;
    });

    if (widget.movieId != null) {
      MovieModel? movieModel = await _dbHelper.getMovieModel(widget.movieId!);

      setState(() {
        __titleController.text = movieModel?.title ?? '';
        __yearController.text = movieModel?.yearPublished?.toString() ?? '2025';
        __genreController.text = movieModel?.genres.join(", ") ?? '';
        __isLoading = false;
      });
    }
  }

  Future<void> _saveMovie() async {
    if (!__formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      __isLoading = true;
    });

    try {
      //obtaining parameters
      final title = __titleController.text.trim();
      final year = __yearController.text.trim().isEmpty
          ? null
          : int.tryParse(__yearController.text.trim());
      final genres = __genreController.text.trim().isEmpty
          ? []
          : __genreController.text
                .trim()
                .split(",")
                .map((element) => element.trim())
                .toList();
      final movie = Movie(
        id: widget.movieId,
        title: title,
        yearPublished: year,
      );

      //Inserting/editing movie
      int movieID;
      if (widget.movieId == null) {
        movieID = await _dbHelper.insertMovie(movie);
      } else {
        await _dbHelper.updateMovie(movie);
        movieID = widget.movieId!;
      }

      //Appending genres
      for (var genre in genres) {
        await _dbHelper.appendGenreToMovie(movieID, genre);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.movieId == null ? 'Movie added' : 'Movie edited',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          __isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.movieId == null ? 'Add' : 'Edit')),
      body: __isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: __formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: __titleController,
                      decoration: const InputDecoration(
                        labelText: 'Movie name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.movie),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter title of the movie';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Год
                    TextFormField(
                      controller: __yearController,
                      decoration: const InputDecoration(
                        labelText: 'Date published',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final year = int.tryParse(value.trim());
                          if (year == null) {
                            return 'Enter correct data';
                          }
                          if (year < 0 || year > DateTime.now().year + 1) {
                            return 'Data cannnot be less than 0 or greater than current year';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: __genreController,
                      decoration: const InputDecoration(
                        labelText: 'Genres',
                        hintText: 'Enter genres seprated with \', \'',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.theater_comedy_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveMovie,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
