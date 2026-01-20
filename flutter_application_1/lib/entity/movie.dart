class Movie {
  final int? id;
  final String title;
  final int? yearPublished;

  Movie({this.id, required this.title, this.yearPublished});

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'year_published': yearPublished};
  }
}
