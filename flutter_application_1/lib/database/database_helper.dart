import 'package:flutter_application_1/entity/attachment.dart';
import 'package:flutter_application_1/entity/genre.dart';
import 'package:flutter_application_1/models/movie_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../entity/movie.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('movies.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE movies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        year_published INTEGER CHECK(year_published IS NOT NULL OR year_published > 0)
      );

      CREATE TABLE genres(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );

      CREATE TABLE movie_genres(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movieID INTEGER NOT NULL REFERENCES movies(id),
        genreID INTEGER NOT NULL REFERENCES genres(id)
      );

      CREATE TABLE movie_attachments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movieID INTEGER NOT NULL REFERENCES movies(id),
        attachmentType INTEGER NOT NULL CHECK(attachmentType > 0 AND attachmentType <= 3),
        link TEXT NOT NULL,
        UNIQUE(movieID, link)
      );
    ''');
  }

  Future<int> insertMovie(Movie movie) async {
    final db = await database;
    return await db.insert('movies', movie.toMap());
  }

  Future<List<MovieModel>> getAllMovies() async {
    final db = await database;

    final result = await db.rawQuery('''
  SELECT m.*, json_group_array(g.name) as "genres"
  FROM movies AS m
  INNER JOIN movie_genres AS mg ON m.id = mg.movieID
  INNER JOIN genres AS g ON g.id = mg.genreID
  GROUP BY m.id;
''');
    return result
        .map(
          (map) => MovieModel(
            id: map['id'] as int,
            title: map['title'] as String,
            yearPublished: map['year_published'] as int?,
            genres: (map['genres'] as String).split(','),
          ),
        )
        .toList();
  }

  Future<MovieModel?> getMovieModel(int id) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
SELECT m.*, json_group_array(g.name) as "genres"
  FROM movies AS m
  INNER JOIN movie_genres AS mg ON m.id = mg.movieID
  INNER JOIN genres AS g ON g.id = mg.genreID
  WHERE m.id = ?
  GROUP BY m.id;
''',
      [id],
    );

    if (result.isNotEmpty) {
      return MovieModel(
        id: result.first['id'] as int,
        title: result.first["title"] as String,
        genres: (result.first["genres"] as String)
            .replaceAll(RegExp(r'[\[\]\"]'), '')
            .split(","),
      );
    }
    return null;
  }

  Future<int> updateMovie(Movie movie) async {
    final db = await database;
    return await db.update(
      'movies',
      movie.toMap(),
      where: 'id = ?',
      whereArgs: [movie.id],
    );
  }

  Future<int> ensureGenreExists(String genreName) async {
    final db = await database;
    final existedOne = await db.query(
      'genres',
      where: 'name = ?',
      whereArgs: [genreName],
    );
    if (existedOne.isNotEmpty) {
      return existedOne.first['id'] as int;
    } else {
      return await db.insert('genres', {'name': genreName});
    }
  }

  Future<List<Genre>> getAllGenres() async {
    final db = await database;
    final result = await db.query('genres');
    return result.map((map) => Genre.fromMap(map)).toList();
  }

  Future<int> appendGenreToMovie(int movieID, String genreName) async {
    final db = await database;
    final genreID = await ensureGenreExists(genreName);

    final genreAttached = await db.query(
      'movie_genres',
      where: 'movieID = ? AND genreID = ?',
      whereArgs: [movieID, genreID],
    );

    if (genreAttached.isNotEmpty) return genreAttached.first['id'] as int;

    return await db.insert('movie_genres', {
      'genreID': genreID,
      'movieID': movieID,
    });
  }

  Future<void> deleteMovie(int movieId) async {
    final db = await database;
    await db.rawDelete(
      '''DELETE FROM movie_genres WHERE movieID = ?''',
      [movieId],
    );

    await db.rawDelete('''DELETE FROM movies WHERE id = ?''', [movieId]);
  }

  Future<void> setMovieFilters(int movieID, List<String> genreNames) async {
    final db = await database;
    await db.rawDelete(
      '''
DELETE FROM movie_genres WHERE movieID = ?
''',
      [movieID],
    );

    for (var genreName in genreNames) {
      final genreID = await ensureGenreExists(genreName);

      final genreAttached = await db.query(
        'movie_genres',
        where: 'movieID = ? AND genreID = ?',
        whereArgs: [movieID, genreID],
      );
      if (genreAttached.isNotEmpty) continue;

      await db.insert('movie_genres', {'genreID': genreID, 'movieID': movieID});
    }
  }

  Future<List<Attachment>> getAttachments(
    int? movieID,
    int? attachmentType,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
  SELECT * FROM movie_attachments AS ma WHERE
  (? IS NULL OR ma.movieID = ?) AND
  (? IS NULL OR ma.attachmentType = ?);
''',
      [movieID, movieID, attachmentType, attachmentType],
    );

    return result
        .map(
          (element) => Attachment(
            id: element["id"] as int,
            attachmentType: element["attachmentType"] as int,
            link: element["link"] as String,
            movieId: element["movieID"] as int,
          ),
        )
        .toList();
  }

  Future<void> deleteAttachment(int id) async {
    final db = await database;
    await db.rawDelete("DELETE FROM movie_attachments WHERE id = ?", [id]);
  }

  Future<int> insertAttachment(Attachment attachment) async {
    final db = await database;
    return await db.insert("movie_attachments", {
      'id':attachment.id,
      'movieID':attachment.movieId,
      'attachmentType':attachment.attachmentType,
      'link':attachment.link,
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
