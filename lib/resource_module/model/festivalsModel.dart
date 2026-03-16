class FestivalResponse {
  final String message;
  final int currentPage;
  final int lastPage;
  final List<FestivalResource> data;

  FestivalResponse({
    required this.message,
    required this.currentPage,
    required this.lastPage,
    required this.data,
  });

  factory FestivalResponse.fromJson(Map<String, dynamic> json) {
    final message = json['message']?.toString() ?? '';
    final rawData = json['data'];
    int currentPage = 1;
    int lastPage = 1;
    List<FestivalResource> items = [];

    // API shape: data is object { current_page, last_page?, data: [ ... ] }
    if (rawData != null && rawData is Map) {
      final dataObj = Map<String, dynamic>.from(rawData as Map);
      currentPage = (dataObj['current_page'] is int)
          ? dataObj['current_page'] as int
          : (int.tryParse(dataObj['current_page']?.toString() ?? '1') ?? 1);
      lastPage = (dataObj['last_page'] is int)
          ? dataObj['last_page'] as int
          : (int.tryParse(dataObj['last_page']?.toString() ?? '1') ?? currentPage);
      final rawList = dataObj['data'];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map) {
            try {
              items.add(FestivalResource.fromJson(Map<String, dynamic>.from(item)));
            } catch (_) {}
          }
        }
      }
    }

    return FestivalResponse(
      message: message,
      currentPage: currentPage,
      lastPage: lastPage,
      data: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': {
        'current_page': currentPage,
        'last_page': lastPage,
        'data': data.map((item) => item.toJson()).toList(),
      },
    };
  }
}

class FestivalResource {
  final int id;
  final String description;
  final String? descriptionOrganizer;
  final String? nameOrganizer;
  final String image;
  final String? innerImage;
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
    this.innerImage,
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
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? '',
      descriptionOrganizer: json['description_organizer']?.toString(),
      nameOrganizer: json['name_organizer']?.toString(),
      image: json['image']?.toString() ?? '',
      innerImage: json['inner_image']?.toString(),
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      startingDate: json['starting_date']?.toString() ?? '',
      endingDate: json['ending_date']?.toString() ?? '',
      time: json['time']?.toString(),
      price: json['price']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'description_organizer': descriptionOrganizer,
      'name_organizer': nameOrganizer,
      'image': image,
      'inner_image': innerImage,
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
