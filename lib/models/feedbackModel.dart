
class ToiletReview {
  final String toiletId;
  final String festivalId;
  final String? what3words;
  final String? toiletType_name;
  final String date;
  final String username;
  final String cleanlinessScore;
  final String? cleanlinessImage;
  final String odourScore;
  final String? odourImage;
  final String aaaDisabledAccessScore;
  final String? aaaDisabledAccessImage;
  final String greenCredentialsScore;
  final String? greenCredentialsImage;
  final String bogRollStandardScore;
  final String? bogRollStandardImage;
  final String cleanFlushFluidScore;
  final String? cleanFlushFluidImage;
  final String lockingSystemScore;
  final String? lockingSystemImage;
  final String handWashFacilityScore;
  final String? handWashFacilityImage;
  final String soapAvailabilityScore;
  final String? soapAvailabilityImage;
  final String handSanitizerAvailabilityScore;
  final String? handSanitizerAvailabilityImage;
  final String waterAvailabilityScore;
  final String? waterAvailabilityImage;
  final String waterPressureScore;
  final String waterTemperatureScore;
  final String changingSpaceScore;
  final String hangingFacilityScore;
  final String easeOfAccessScore;
  final String totalScore;

  ToiletReview({
    required this.toiletId,
    required this.festivalId,
    required this.what3words,
    required this.toiletType_name,
    required this.date,
    required this.username,
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
    required this.soapAvailabilityScore,
    required this.soapAvailabilityImage,
    required this.handSanitizerAvailabilityScore,
    required this.handSanitizerAvailabilityImage,
    required this.waterAvailabilityScore,
    required this.waterAvailabilityImage,
    required this.waterPressureScore,
    required this.waterTemperatureScore,
    required this.changingSpaceScore,
    required this.hangingFacilityScore,
    required this.easeOfAccessScore,
    required this.totalScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'toilet_id': toiletId,
      'festival_id': festivalId,
      'date': date,
      "what3words": what3words,
      "toiletType_name": toiletType_name,
      'username': username,
      'cleanliness_score': cleanlinessScore,
      'cleanliness_image': cleanlinessImage,
      'odour_score': odourScore,
      'odour_image': odourImage,
      'aaa_disabled_access_score': aaaDisabledAccessScore,
      'aaa_disabled_access_image': aaaDisabledAccessImage,
      'green_credentials_score': greenCredentialsScore,
      'green_credentials_image': greenCredentialsImage,
      'bog_roll_standard_score': bogRollStandardScore,
      'bog_roll_standard_image': bogRollStandardImage,
      'clean_flush_fluid_score': cleanFlushFluidScore,
      'clean_flush_fluid_image': cleanFlushFluidImage,
      'locking_system_score': lockingSystemScore,
      'locking_system_image': lockingSystemImage,
      'hand_wash_facility_score': handWashFacilityScore,
      'hand_wash_facility_image': handWashFacilityImage,
      'soap_availablity_score': soapAvailabilityScore,
      'soap_availablity_image': soapAvailabilityImage,
      'hand_sanitizer_availability_score': handSanitizerAvailabilityScore,
      'hand_sanitizer_availability_image': handSanitizerAvailabilityImage,
      'water_availability_score': waterAvailabilityScore,
      'water_availability_image': waterAvailabilityImage,
      'water_pressure_score': waterPressureScore,
      'water_temperature_score': waterTemperatureScore,
      'changing_space_score': changingSpaceScore,
      'hanging_facility_score': hangingFacilityScore,
      'ease_of_access_score': easeOfAccessScore,
      'total_score': totalScore,
    };
  }
}


