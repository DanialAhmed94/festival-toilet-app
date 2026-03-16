import 'package:crapadvisor/resource_module/model/festivalsModel.dart';

import 'eventModel.dart';

class Performances {
  final int status;
  final List<Performance> data;
  final String message;

  Performances({
    required this.status,
    required this.data,
    required this.message,
  });

  factory Performances.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List;
    List<Performance> performances =
    dataList.map((item) => Performance.fromJson(item)).toList();

    return Performances(
      status: json['status'],
      data: performances,
      message: json['message'],
    );
  }
}

class Performance {
  final int id;
  final int festivalId;
  final int userId;
  final String? bandName;
  final String? artistName;
  final String? performanceTitle;
  final String? technicalRequirementLighting;
  final String? technicalRequirementSound;
  final String? technicalRequirementStageSetup;
  final String? technicalRequirementSpecialNotes;
  final String? transitionDetail;
  final String? participantName;
  final String? specialGuests;
  final String? startTime;
  final String? endTime;
  final String? startDate;
  final String? endDate;
  final String? image; // Nullable
  final DateTime createdAt;
  final DateTime updatedAt;
  final FestivalResource? festival;
  final EventData? event;

  Performance({
    required this.id,
    required this.festivalId,
    required this.userId,
    required this.bandName,
    required this.artistName,
    required this.performanceTitle,
    required this.technicalRequirementLighting,
    required this.technicalRequirementSound,
    required this.technicalRequirementStageSetup,
    required this.technicalRequirementSpecialNotes,
    required this.transitionDetail,
    required this.participantName,
    required this.specialGuests,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    required this.endDate,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.festival,
    required this.event,
  });
  factory Performance.fromJson(Map<String, dynamic> json) {
    return Performance(
      id: json['id'],
      festivalId: json['festival_id'],
      userId: json['user_id'],
      bandName: json['band_name'],
      artistName: json['artist_name'],
      performanceTitle: json['performance_title'],
      technicalRequirementLighting: json['technical_rquirement_lightening'],
      technicalRequirementSound: json['technical_rquirement_sound'],
      technicalRequirementStageSetup: json['technical_rquirement_stage_setup'],
      technicalRequirementSpecialNotes: json['technical_rquirement_special_notes'],
      transitionDetail: json['transition_detail'],
      participantName: json['participant_name'],
      specialGuests: json['special_guests'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      image: json['image'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      festival: json['festival'] != null
          ? FestivalResource.fromJson(json['festival'])
          : null, // Parse festival using Festival model

      event: json['event'] != null
          ? EventData.fromJson(json['event'])
          : null,

    );
  }


}
