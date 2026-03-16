class ActivityResponse {
  final int status;
  final List<ActivityData> data;
  final String message;

  ActivityResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  factory ActivityResponse.fromJson(Map<String, dynamic> json) {
    return ActivityResponse(
      status: json['status'],
      data: List<ActivityData>.from(
        json['data'].map((x) => ActivityData.fromJson(x)),
      ),
      message: json['message'],
    );
  }
}

class ActivityData {
  final int id;
  final int userId;
  final int festivalId;
  final String activityTitle;
  final String image;
  final String description;
  final String? date;
  final String latitude;
  final String longitude;
  final String startTime;
  final String endTime;
  final String startDate;
  final String endDate;
  final String createdAt;
  final String updatedAt;
  final FestivalActivity festival;

  ActivityData({
    required this.id,
    required this.userId,
    required this.festivalId,
    required this.activityTitle,
    required this.image,
    required this.description,
    this.date,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.festival,
  });

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      id: json['id'],
      userId: json['user_id'],
      festivalId: json['festival_id'],
      activityTitle: json['activity_title'],
      image: json['image'],
      description: json['description'],
      date: json['date'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      startTime: json['start_time'],
      startDate:  json['start_date'],
      endDate:  json['end_date'],
      endTime: json['end_time'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      festival: FestivalActivity.fromJson(json['festival']),
    );
  }
}

class FestivalActivity {
  final int id;
  final String description;
  final String descriptionOrganizer;
  final String nameOrganizer;
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

  FestivalActivity({
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

  factory FestivalActivity.fromJson(Map<String, dynamic> json) {
    return FestivalActivity(
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
