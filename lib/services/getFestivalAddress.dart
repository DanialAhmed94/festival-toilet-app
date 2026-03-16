import 'package:geocoding/geocoding.dart';

Future<String> getFestivalAddress(double lat, double lng) async {
  try {
    // Validate input latitude and longitude
    if (lat == null || lng == null) {
      return "Invalid coordinates";
    }

    // Log the coordinates
    print('Fetching address for: $lat, $lng');

    // Fetch placemarks from coordinates
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isEmpty) {
      return 'No address found for the coordinates';
    }

    // Extract address components
    Placemark placemark = placemarks.first;
    String street = placemark.street ?? '';
    String locality = placemark.locality ?? '';
    String administrativeArea = placemark.administrativeArea ?? '';
    String country = placemark.country ?? '';

    // Construct the address
    List<String> addressParts = [];
    if (street.isNotEmpty) addressParts.add(street);
    if (locality.isNotEmpty) addressParts.add(locality);
    if (administrativeArea.isNotEmpty) addressParts.add(administrativeArea);
    if (country.isNotEmpty) addressParts.add(country);

    String address = addressParts.join(', ');
    return address.isNotEmpty ? address : "Address details are not available";
  } catch (e) {
    print('Error getting user location or converting to an address: $e');
    return "Something went wrong";
  }
}
