class MovieModel {
  final int? id;
  final String title;
  final int? yearPublished;
  final List<String> genres;

  MovieModel({this.id, required this.title, this.yearPublished, required this.genres});
}
