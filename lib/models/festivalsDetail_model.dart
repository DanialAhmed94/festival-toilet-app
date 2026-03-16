class Festivals {
  Festivals({
    required this.message,
    required this.data,
  });

  late final String message;
  late final List<Festival> data;

  Festivals.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    data = List.from(json['data']).map((e) => Festival.fromJson(e)).toList();
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
  late final String createdAt;
  late final String updatedAt;

  Festival.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    description = json['description'];
    descriptionOrganizer = json['description_organizer'];
    nameOrganizer = json['name_organizer'];
    image = json['image'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    startingDate = json['starting_date'];
    endingDate = json['ending_date'];
    time = json['time'];
    price = json['price'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
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