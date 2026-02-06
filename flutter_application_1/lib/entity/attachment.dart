class Attachment {
  final int? id;
  int movieId;
  final int attachmentType;
  String? link;
  String? path;
  String? addressAdded;

  Attachment({
    this.id,
    required this.attachmentType,
    required this.movieId,
    this.link,
    this.path,
    this.addressAdded,
  });
}
