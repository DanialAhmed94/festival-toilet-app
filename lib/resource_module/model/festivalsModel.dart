class FestivalResponse {
  final String message;
  final List<FestivalResource> data;

  FestivalResponse({
    required this.message,
    required this.data,
  });

  factory FestivalResponse.fromJson(Map<String, dynamic> json) {
    return FestivalResponse(
      message: json['message'],
      data: List<FestivalResource>.from(
        json['data'].map((item) => FestivalResource.fromJson(item)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class FestivalResource {
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

  FestivalResource({
    required this.id,
    required this.description,
    this.descriptionOrganizer,
    this.nameOrganizer,
    required this.image,
    required this.latitude,
    required this.longitude,
    required this.startingDate,
    required this.endingDate,
    this.time,
    this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FestivalResource.fromJson(Map<String, dynamic> json) {
    return FestivalResource(
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'description_organizer': descriptionOrganizer,
      'name_organizer': nameOrganizer,
      'image': image,
      'latitude': latitude,
      'longitude': longitude,
      'starting_date': startingDate,
      'ending_date': endingDate,
      'time': time,
      'price': price,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
