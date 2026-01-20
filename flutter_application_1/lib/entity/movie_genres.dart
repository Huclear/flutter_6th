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
}

