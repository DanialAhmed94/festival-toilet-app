import 'package:crapadvisor/resource_module/model/festivalsModel.dart';


class EventResponse {
  final int status;
  final String message;
  final List<EventData> data;

  EventResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    return EventResponse(
      status: json['status'],
      message: json['message'],
      data: List<EventData>.from(json['data'].map((item) => EventData.fromJson(item))),
    );
  }
}

class EventData {
  final int id;
  final int festivalId;
  final int userId;
  final String? eventTitle;
  final String? eventDescription;
  final String? grandTotal; // Nullable String
  final String? taxPercentage; // Nullable String
  final String? pricePerPerson; // Nullable String
  final String? crowdCapacity; // Nullable String
  final String? startTime;
  final String? startDate; // Nullable String
  final String? endTime; // Nullable String
  final String? image;
  final String? createdAt;
  final String? updatedAt;
  final FestivalResource? festival;
  EventData({
    required this.id,
    required this.festivalId,
    required this.userId,
    required this.eventTitle,
    required this.eventDescription,
    this.grandTotal,
    this.taxPercentage,
    this.pricePerPerson,
    this.crowdCapacity,
    required this.startTime,
    this.startDate,
    this.endTime,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.festival,
  });

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      id: json['id'],
      festivalId: json['festival_id'],
      userId: json['user_id'],
      eventTitle: json['event_title'],
      eventDescription: json['event_description'],
      grandTotal: json['grand_total'],
      taxPercentage: json['tax_percentage'],
      pricePerPerson: json['price_per_person'],
      crowdCapacity: json['crowd_capacity'],
      startTime: json['start_time'],
      startDate: json['start_date'],
      endTime: json['end_time'],
      image: json['image'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      festival: json['festival'] != null
          ? FestivalResource.fromJson(json['festival'])
          : null,
    );
  }
}
