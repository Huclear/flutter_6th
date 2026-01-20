class MovieGenres {
  final int? id;
  final int movieID;
  final int genreID;

  MovieGenres({
    this.id,
    required this.movieID,
    required this.genreID
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      "movieID": movieID,
      "genreID": genreID
    };
  }

  factory MovieGenres.fromMap(Map<String, dynamic> map) {
    return MovieGenres(
      id: map['id'] as int?,
      movieID: map['movieID'] as int,
      genreID: map['genreID'] as int,
    );
  }
}

