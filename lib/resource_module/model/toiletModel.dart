// toilet_response.dart

class ToiletResponse {
  final int status;
  final List<ToiletData> data;
  final String message;

  ToiletResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  factory ToiletResponse.fromJson(Map<String, dynamic> json) {
    return ToiletResponse(
      status: json['status'],
      data: List<ToiletData>.from(
        json['data'].map((x) => ToiletData.fromJson(x)),
      ),
      message: json['message'],
    );
  }
}

class ToiletData {
  final int id;
  final int? userId;
  final int festivalId;
  final int? toiletTypeId;
  final String? latitude;
  final String? longitude;
  final String? what3Words;
  final String? image;
  final String? createdAt;
  final String? updatedAt;
  final FestivalToilet festival;
  final ToiletType toiletType;

  ToiletData({
    required this.id,
    required this.userId,
    required this.festivalId,
    required this.toiletTypeId,
    required this.latitude,
    required this.longitude,
    this.what3Words,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.festival,
    required this.toiletType,
  });

  factory ToiletData.fromJson(Map<String, dynamic> json) {
    return ToiletData(
      id: json['id'],
      userId: json['user_id'],
      festivalId: json['festival_id'],
      toiletTypeId: json['toilet_type_id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      what3Words: json['what_3_words'],
      image: json['image'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      festival: FestivalToilet.fromJson(json['festival']),
      toiletType: ToiletType.fromJson(json['toilet_types']),
    );
  }
}

class FestivalToilet {
  final int id;
  final String description;
  final String? descriptionOrganizer;
  final String? nameOrganizer;
  final String image;
  final String latitude;
  final String longitude;
  final String startingDate;
  final String endingDate;
  final String? time;
  final String? price;
  final String createdAt;
  final String updatedAt;
  final int userId;

  FestivalToilet({
    required this.id,
    required this.description,
    required this.descriptionOrganizer,
    required this.nameOrganizer,
    required this.image,
    required this.latitude,
    required this.longitude,
    required this.startingDate,
    required this.endingDate,
    this.time,
    this.price,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  factory FestivalToilet.fromJson(Map<String, dynamic> json) {
    return FestivalToilet(
      id: json['id'],
      description: json['description'],
      descriptionOrganizer: json['description_organizer'],
      nameOrganizer: json['name_organizer'],
      image: json['image'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      startingDate: json['starting_date'],
      endingDate: json['ending_date'],
      time: json['time'],
      price: json['price'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      userId: json['user_id'],
    );
  }
}

class ToiletType {
  final int id;
  final String name;
  final String image;
  final String createdAt;
  final String updatedAt;

  ToiletType({
    required this.id,
    required this.name,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ToiletType.fromJson(Map<String, dynamic> json) {
    return ToiletType(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
