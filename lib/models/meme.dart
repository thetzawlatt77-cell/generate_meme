class Meme {
  final String id;
  final String name;
  final String url;
  final int width;
  final int height;

  const Meme({
    required this.id,
    required this.name,
    required this.url,
    required this.width,
    required this.height,
  });

  factory Meme.fromJson(Map<String, dynamic> json) {
    return Meme(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'width': width,
      'height': height,
    };
  }

  @override
  String toString() {
    return 'Meme(id: $id, name: $name, url: $url, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Meme &&
        other.id == id &&
        other.name == name &&
        other.url == url &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        url.hashCode ^
        width.hashCode ^
        height.hashCode;
  }
}
