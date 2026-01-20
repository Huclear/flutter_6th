class Genre {
  final int? id;
  final String name;

  Genre({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Genre.fromMap(Map<String, dynamic> map) {
    return Genre(id: map['id'] as int?, name: map["name"] as String);
  }

  Genre copyWith({String? newName}) {
    return Genre(name: newName ?? name);
  }
}
