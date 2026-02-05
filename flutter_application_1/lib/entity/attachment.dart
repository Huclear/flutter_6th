class Attachment {
  final int? id;
  int movieId;
  final int attachmentType;
  final String link;

  Attachment({
    this.id,
    required this.attachmentType,
    required this.link,
    required this.movieId,
  });
}
