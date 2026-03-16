import 'dart:convert';

class FeedbackResponse {
  String message;
  FeedbackData data;

  FeedbackResponse({
    required this.message,
    required this.data,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      message: json['message'],
      data: FeedbackData.fromJson(json['data']),
    );
  }
}

class FeedbackData {
  int currentPage;
  List<FeedbackItem> feedbackItems;
  String firstPageUrl;
  int from;
  int lastPage;
  String lastPageUrl;
  List<PageLink> links;
  String? nextPageUrl;
  String path;
  int perPage;
  String? prevPageUrl;
  int to;
  int total;

  FeedbackData({
    required this.currentPage,
    required this.feedbackItems,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory FeedbackData.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<FeedbackItem> feedbackList =
    list.map((i) => FeedbackItem.fromJson(i)).toList();

    var linksList = json['links'] as List;
    List<PageLink> pageLinks =
    linksList.map((i) => PageLink.fromJson(i)).toList();

    return FeedbackData(
      currentPage: json['current_page'],
      feedbackItems: feedbackList,
      firstPageUrl: json['first_page_url'],
      from: json['from'],
      lastPage: json['last_page'],
      lastPageUrl: json['last_page_url'],
      links: pageLinks,
      nextPageUrl: json['next_page_url'],
      path: json['path'],
      perPage: json['per_page'],
      prevPageUrl: json['prev_page_url'],
      to: json['to'],
      total: json['total'],
    );
  }
}

class FeedbackItem {
  int id;
  int festivalId;
  int toiletId;
  String? what3words;
  String? toiletType_name;
  String username;
  String date;
  String cleanlinessScore;
  String? cleanlinessImage;
  String odourScore;
  String? odourImage;
  String aaaDisabledAccessScore;
  String? aaaDisabledAccessImage;
  String greenCredentialsScore;
  String? greenCredentialsImage;
  String bogRollStandardScore;
  String? bogRollStandardImage;
  String? cleanFlushFluidScore;
  String? cleanFlushFluidImage;
  String? lockingSystemScore;
  String? lockingSystemImage;
  String? handWashFacilityScore;
  String? handWashFacilityImage;
  String? soapAvailabilityScore;
  String? soapAvailabilityImage;
  String? handSanitizerAvailabilityScore;
  String? handSanitizerAvailabilityImage;
  String? waterAvailabilityScore;
  String? waterAvailabilityImage;
  String? waterPressureScore;
  String? waterPressureImage;
  String? waterTemperatureScore;
  String? waterTemperatureImage;
  String? changingSpaceScore;
  String? changingSpaceImage;
  String? hangingFacilityScore;
  String? hangingFacilityImage;
  String? easeOfAccessScore;
  String? easeOfAccessImage;
  String? totalScore;
  String createdAt;
  String updatedAt;

  FeedbackItem({
    required this.id,
    required this.festivalId,
    required this.toiletId,
    required this.what3words,
    required this.toiletType_name,
    required this.username,
    required this.date,
    required this.cleanlinessScore,
    this.cleanlinessImage,
    required this.odourScore,
    this.odourImage,
    required this.aaaDisabledAccessScore,
    this.aaaDisabledAccessImage,
    required this.greenCredentialsScore,
    this.greenCredentialsImage,
    required this.bogRollStandardScore,
    this.bogRollStandardImage,
    this.cleanFlushFluidScore,
    this.cleanFlushFluidImage,
    this.lockingSystemScore,
    this.lockingSystemImage,
    this.handWashFacilityScore,
    this.handWashFacilityImage,
    this.soapAvailabilityScore,
    this.soapAvailabilityImage,
    this.handSanitizerAvailabilityScore,
    this.handSanitizerAvailabilityImage,
    this.waterAvailabilityScore,
    this.waterAvailabilityImage,
    this.waterPressureScore,
    this.waterPressureImage,
    this.waterTemperatureScore,
    this.waterTemperatureImage,
    this.changingSpaceScore,
    this.changingSpaceImage,
    this.hangingFacilityScore,
    this.hangingFacilityImage,
    this.easeOfAccessScore,
    this.easeOfAccessImage,
    this.totalScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'],
      festivalId: json['festival_id'],
      toiletId: json['toilet_id'],
      what3words: json['what3words'],
      toiletType_name: json['toiletType_name'],
      username: json['username'],
      date: json['date'],
      cleanlinessScore: json['cleanliness_score'],
      cleanlinessImage: json['cleanliness_image'],
      odourScore: json['odour_score'],
      odourImage: json['odour_image'],
      aaaDisabledAccessScore: json['aaa_disabled_access_score'],
      aaaDisabledAccessImage: json['aaa_disabled_access_image'],
      greenCredentialsScore: json['green_credentials_score'],
      greenCredentialsImage: json['green_credentials_image'],
      bogRollStandardScore: json['bog_roll_standard_score'],
      bogRollStandardImage: json['bog_roll_standard_image'],
      cleanFlushFluidScore: json['clean_flush_fluid_score'],
      cleanFlushFluidImage: json['clean_flush_fluid_image'],
      lockingSystemScore: json['locking_system_score'],
      lockingSystemImage: json['locking_system_image'],
      handWashFacilityScore: json['hand_wash_facility_score'],
      handWashFacilityImage: json['hand_wash_facility_image'],
      soapAvailabilityScore: json['soap_availablity_score'],
      soapAvailabilityImage: json['soap_availablity_image'],
      handSanitizerAvailabilityScore:
      json['hand_sanitizer_availability_score'],
      handSanitizerAvailabilityImage:
      json['hand_sanitizer_availability_image'],
      waterAvailabilityScore: json['water_availability_score'],
      waterAvailabilityImage: json['water_availability_image'],
      waterPressureScore: json['water_pressure_score'],
      waterPressureImage: json['water_pressure_image'],
      waterTemperatureScore: json['water_temperature_score'],
      waterTemperatureImage: json['water_temperature_image'],
      changingSpaceScore: json['changing_space_score'],
      changingSpaceImage: json['changing_space_image'],
      hangingFacilityScore: json['hanging_facility_score'],
      hangingFacilityImage: json['hanging_facility_image'],
      easeOfAccessScore: json['ease_of_access_score'],
      easeOfAccessImage: json['ease_of_access_image'],
      totalScore: json['total_score'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class PageLink {
  String? url;
  String label;
  bool active;

  PageLink({
    required this.url,
    required this.label,
    required this.active,
  });

  factory PageLink.fromJson(Map<String, dynamic> json) {
    return PageLink(
      url: json['url'],
      label: json['label'],
      active: json['active'],
    );
  }
}


class Feedbacks {
  String message;
  Data data;

  Feedbacks({
    required this.message,
    required this.data,
  });

  factory Feedbacks.fromJson(Map<String, dynamic> json) {
    return Feedbacks(
      message: json['message'],
      data: Data.fromJson(json['data']),
    );
  }

}

class Data {
  int currentPage;
  List<Feedback> data;
  String firstPageUrl;
  int from;
  int lastPage;
  String lastPageUrl;
  List<Link> links;
  dynamic nextPageUrl;
  String path;
  int perPage;
  String prevPageUrl;
  int to;
  int total;

  Data({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    required this.nextPageUrl,
    required this.path,
    required this.perPage,
    required this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      currentPage: json['current_page'],
      data: List<Feedback>.from(json['data'].map((x) => Feedback.fromJson(x))),
      firstPageUrl: json['first_page_url'],
      from: json['from'],
      lastPage: json['last_page'],
      lastPageUrl: json['last_page_url'],
      links: List<Link>.from(json['links'].map((x) => Link.fromJson(x))),
      nextPageUrl: json['next_page_url'],
      path: json['path'],
      perPage: json['per_page'],
      prevPageUrl: json['prev_page_url'],
      to: json['to'],
      total: json['total'],
    );
  }

}

class Feedback {
  int id;
  int festivalId;
  int toiletId;
  String username;
  DateTime date;
  String? cleanlinessScore;
  String? cleanlinessImage;
  String? odourScore;
  String? odourImage;
  String? aaaDisabledAccessScore;
  String? aaaDisabledAccessImage;
  String? greenCredentialsScore;
  String? greenCredentialsImage;
  String? bogRollStandardScore;
  String? bogRollStandardImage;
  String? cleanFlushFluidScore;
  String? cleanFlushFluidImage;
  String? lockingSystemScore;
  String? lockingSystemImage;
  String? handWashFacilityScore;
  String? handWashFacilityImage;
  String? soapAvailablityScore;
  String? soapAvailablityImage;
  String? handSanitizerAvailabilityScore;
  String? handSanitizerAvailabilityImage;
  String? waterAvailabilityScore;
  String? waterAvailabilityImage;
  String? waterPressureScore;
  String? waterPressureImage;
  String? waterTemperatureScore;
  String? waterTemperatureImage;
  String? changingSpaceScore;
  String? changingSpaceImage;
  String? hangingFacilityScore;
  String? hangingFacilityImage;
  String? easeOfAccessScore;
  String? easeOfAccessImage;
  String? totalScore;
  DateTime createdAt;
  DateTime updatedAt;

  Feedback({
    required this.id,
    required this.festivalId,
    required this.toiletId,
    required this.username,
    required this.date,
    required this.cleanlinessScore,
    required this.cleanlinessImage,
    required this.odourScore,
    required this.odourImage,
    required this.aaaDisabledAccessScore,
    required this.aaaDisabledAccessImage,
    required this.greenCredentialsScore,
    required this.greenCredentialsImage,
    required this.bogRollStandardScore,
    required this.bogRollStandardImage,
    required this.cleanFlushFluidScore,
    required this.cleanFlushFluidImage,
    required this.lockingSystemScore,
    required this.lockingSystemImage,
    required this.handWashFacilityScore,
    required this.handWashFacilityImage,
    required this.soapAvailablityScore,
    required this.soapAvailablityImage,
    required this.handSanitizerAvailabilityScore,
    required this.handSanitizerAvailabilityImage,
    required this.waterAvailabilityScore,
    required this.waterAvailabilityImage,
    required this.waterPressureScore,
    required this.waterPressureImage,
    required this.waterTemperatureScore,
    required this.waterTemperatureImage,
    required this.changingSpaceScore,
    required this.changingSpaceImage,
    required this.hangingFacilityScore,
    required this.hangingFacilityImage,
    required this.easeOfAccessScore,
    required this.easeOfAccessImage,
    required this.totalScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'],
      festivalId: json['festival_id'],
      toiletId: json['toilet_id'],
      username: json['username'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      cleanlinessScore: json['cleanliness_score'],
      cleanlinessImage: json['cleanliness_image'],
      odourScore: json['odour_score'],
      odourImage: json['odour_image'],
      aaaDisabledAccessScore: json['aaa_disabled_access_score'],
      aaaDisabledAccessImage: json['aaa_disabled_access_image'],
      greenCredentialsScore: json['green_credentials_score'],
      greenCredentialsImage: json['green_credentials_image'],
      bogRollStandardScore: json['bog_roll_standard_score'],
      bogRollStandardImage: json['bog_roll_standard_image'],
      cleanFlushFluidScore: json['clean_flush_fluid_score'],
      cleanFlushFluidImage: json['clean_flush_fluid_image'],
      lockingSystemScore: json['locking_system_score'],
      lockingSystemImage: json['locking_system_image'],
      handWashFacilityScore: json['hand_wash_facility_score'],
      handWashFacilityImage: json['hand_wash_facility_image'],
      soapAvailablityScore: json['soap_availablity_score'],
      soapAvailablityImage: json['soap_availablity_image'],
      handSanitizerAvailabilityScore: json['hand_sanitizer_availability_score'],
      handSanitizerAvailabilityImage: json['hand_sanitizer_availability_image'],
      waterAvailabilityScore: json['water_availability_score'],
      waterAvailabilityImage: json['water_availability_image'],
      waterPressureScore: json['water_pressure_score'],
      waterPressureImage: json['water_pressure_image'],
      waterTemperatureScore: json['water_temperature_score'],
      waterTemperatureImage: json['water_temperature_image'],
      changingSpaceScore: json['changing_space_score'],
      changingSpaceImage: json['changing_space_image'],
      hangingFacilityScore: json['hanging_facility_score'],
      hangingFacilityImage: json['hanging_facility_image'],
      easeOfAccessScore: json['ease_of_access_score'],
      easeOfAccessImage: json['ease_of_access_image'],
      totalScore: json['total_score'],

      createdAt: json['created_at'] !=null ?DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] !=null ? DateTime.parse(json['updated_at']) : DateTime.now(),

    );
  }

}

class Link {
  String url;
  String label;
  bool active;

  Link({
    required this.url,
    required this.label,
    required this.active,
  });

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      url: json['url'],
      label: json['label'],
      active: json['active'],
    );
  }

}
