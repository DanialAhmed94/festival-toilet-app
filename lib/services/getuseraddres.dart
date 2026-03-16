import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

Future<String> getUserAddress() async {
  // 1) Check current location permission status
  PermissionStatus status = await Permission.location.status;

  if (status.isDenied) {
    // 2) If permission is denied but not permanently, request it
    status = await Permission.location.request();
  }

  if (status.isPermanentlyDenied) {
    // 3) If permission is permanently denied, return a message (or guide user to settings)
    return 'Location permission is permanently denied. Please enable it from settings.';
  }

  if (!status.isGranted) {
    // 4) If permission is still not granted (denied again), return
    return 'Location permission was denied.';
  }

  try {
    // 5) At this point, we know permission is granted
    final Position locationData = await getUserLocation();

    // 6) Safety check: ensure we actually got coordinates
    if (locationData == null ||
        locationData.latitude == null ||
        locationData.longitude == null) {
      return 'Location data is not available';
    }

    print(
        'Fetching address for: ${locationData.latitude}, ${locationData.longitude}');

    // 7) Reverse-geocode into address components
    List<Placemark> placemarks = await placemarkFromCoordinates(
      locationData.latitude!,
      locationData.longitude!,
    );

    if (placemarks.isEmpty) {
      return 'No address found for these coordinates';
    }

    final Placemark place = placemarks.reversed.last;
    final String street = place.street ?? '';
    final String locality = place.locality ?? '';
    final String administrativeArea = place.administrativeArea ?? '';
    final String country = place.country ?? '';

    final String address = '$street, $locality, $administrativeArea, $country';
    return address;
  } catch (e) {
    print('Error getting user location or converting to an address: $e');
    return 'Something went wrong';
  }
}

// Example implementation of getUserLocation (you may already have this)
Future<Position> getUserLocation() async {
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}
