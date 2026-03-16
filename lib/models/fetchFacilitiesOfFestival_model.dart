class Toilet {
  String id;
  String festivalId;
  String toiletTypeId;
  String latitude;
  String longitude;
  String what3Words;
  String createdAt;
  String updatedAt;

  Toilet({
    required this.id,
    required this.festivalId,
    required this.toiletTypeId,
    required this.latitude,
    required this.longitude,
    required this.what3Words,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Toilet.fromJson(Map<String, dynamic> json) {
    return Toilet(
      id: json['id'].toString(),
      festivalId: json['festival_id'].toString(),
      toiletTypeId: json['toilet_type_id'].toString(),
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
      what3Words: json['what_3_words'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}
