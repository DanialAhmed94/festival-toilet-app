class FacilityTypes {
  late String message;
  late List<Facility> facilityList;

  FacilityTypes({ required this.message,required this.facilityList});

  FacilityTypes.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      facilityList = <Facility>[];
      json['data'].forEach((v) {
        facilityList!.add(new Facility.fromJson(v));
      });
    }
  }

}

class Facility {
  late int id;
  late final String name;
  late final String image;
  late final String createdAt;
  late final String updatedAt;

  Facility({required this.id, required  this.name,required this.image,required this.createdAt,required this.updatedAt});

  Facility.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['image'] = this.image;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
