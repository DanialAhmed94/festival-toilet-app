class Festivals {
  Festivals({
    required this.message,
    required this.currentPage,
    required this.lastPage,
    required this.data,
  });

  late final String message;
  late final int currentPage;
  late final int lastPage;
  late final List<Festival> data;

  Festivals.fromJson(Map<String, dynamic> json) {
    message = json['message']?.toString() ?? '';
    int page = 1;
    int last = 1;
    List<Festival> list = [];

    final rawData = json['data'];
    if (rawData != null && rawData is Map) {
      final dataObj = Map<String, dynamic>.from(rawData as Map);
      page = (dataObj['current_page'] is int)
          ? dataObj['current_page'] as int
          : (int.tryParse(dataObj['current_page']?.toString() ?? '1') ?? 1);
      last = (dataObj['last_page'] is int)
          ? dataObj['last_page'] as int
          : (int.tryParse(dataObj['last_page']?.toString() ?? '1') ?? page);

      final rawList = dataObj['data'];
      if (rawList is List) {
        final items = <Festival>[];
        for (final e in rawList) {
          if (e is Map) {
            try {
              items.add(Festival.fromJson(Map<String, dynamic>.from(e)));
            } catch (_) {}
          }
        }
        list = items;
      }
    }

    currentPage = page;
    lastPage = last;
    data = list;
  }
}

class Festival {
  Festival({
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
    this.innerImage,
    required this.createdAt,
    required this.updatedAt,
  });

  late final int id;
  late final String description;
  late final String? descriptionOrganizer;
  late final String? nameOrganizer;
  late final String image;
  late final String latitude;
  late final String longitude;
  late final String startingDate;
  late final String endingDate;
  late final String? time;
  late final String? price;
  late final String? innerImage;
  late final String createdAt;
  late final String updatedAt;

  Festival.fromJson(Map<String, dynamic> json) {
    id = (json['id'] is int) ? json['id'] as int : (int.tryParse(json['id']?.toString() ?? '0') ?? 0);
    description = json['description']?.toString() ?? '';
    descriptionOrganizer = json['description_organizer']?.toString();
    nameOrganizer = json['name_organizer']?.toString();
    image = json['image']?.toString() ?? '';
    latitude = json['latitude']?.toString() ?? '';
    longitude = json['longitude']?.toString() ?? '';
    startingDate = json['starting_date']?.toString() ?? '';
    endingDate = json['ending_date']?.toString() ?? '';
    time = json['time']?.toString();
    price = json['price']?.toString();
    innerImage = json['inner_image']?.toString();
    createdAt = json['created_at']?.toString() ?? '';
    updatedAt = json['updated_at']?.toString() ?? '';
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['id'] = id;
    _data['description'] = description;
    _data['description_organizer'] = descriptionOrganizer;
    _data['name_organizer'] = nameOrganizer;
    _data['image'] = image;
    _data['latitude'] = latitude;
    _data['longitude'] = longitude;
    _data['starting_date'] = startingDate;
    _data['ending_date'] = endingDate;
    _data['time'] = time;
    _data['price'] = price;
    _data['inner_image'] = innerImage;
    _data['created_at'] = createdAt;
    _data['updated_at'] = updatedAt;
    return _data;
  }
}

//
// class Festivals {
//   Festivals({
//     required this.message,
//     required this.data,
//   });
//   late final String message;
//   late final List<Festival> data;
//
//   Festivals.fromJson(Map<String, dynamic> json){
//     message = json['message'];
//     data = List.from(json['data']).map((e)=>Festival.fromJson(e)).toList();
//   }
//
// }
//
// class Festival {
//   Festival({
//     required this.id,
//     required this.description,
//     required this.image,
//     required this.latitude,
//     required this.longitude,
//     required this.startingDate,
//     required this.endingDate,
//     required this.time,
//     required this.price,
//     required this.createdAt,
//     required this.updatedAt,
//   });
//   late final int id;
//   late final String description;
//   late final String image;
//   late final String latitude;
//   late final String longitude;
//   late final String startingDate;
//   late final String endingDate;
//   late final String time;
//   late final String price;
//   late final String createdAt;
//   late final String updatedAt;
//
//   Festival.fromJson(Map<String, dynamic> json){
//     id = json['id'];
//     description = json['description'];
//     image = json['image'];
//     latitude = json['latitude'];
//     longitude = json['longitude'];
//     startingDate = json['starting_date'];
//     endingDate = json['ending_date'];
//     time = json['time'];
//     price = json['price'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final _data = <String, dynamic>{};
//     _data['id'] = id;
//     _data['description'] = description;
//     _data['image'] = image;
//     _data['latitude'] = latitude;
//     _data['longitude'] = longitude;
//     _data['starting_date'] = startingDate;
//     _data['ending_date'] = endingDate;
//     _data['time'] = time;
//     _data['price'] = price;
//     _data['created_at'] = createdAt;
//     _data['updated_at'] = updatedAt;
//     return _data;
//   }
// }