import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> getCustomMarker() async {
  String svgData = await rootBundle.loadString('assets/svgs/ic_pick.svg');
  int width = 100;
  int height = 100;
  final pictureInfo = await vg.loadPicture(SvgStringLoader(svgData), null);
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);

  canvas.scale(
      width / pictureInfo.size.width, height / pictureInfo.size.height);
  canvas.drawPicture(pictureInfo.picture);
  final ui.Picture scaledPicture = recorder.endRecording();
  final image = await scaledPicture.toImage(width, height);
  final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List byteList = byteData!.buffer.asUint8List();

  return BitmapDescriptor.fromBytes(byteList);
}

Future<BitmapDescriptor> getCustomfetchedMarkerIcon() async {
  String svgData = await rootBundle.loadString('assets/svgs/fetchedMarkerIcon.svg');
  int width = 100;
  int height = 100;
  final pictureInfo = await vg.loadPicture(SvgStringLoader(svgData), null);
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);

  canvas.scale(
      width / pictureInfo.size.width, height / pictureInfo.size.height);
  canvas.drawPicture(pictureInfo.picture);
  final ui.Picture scaledPicture = recorder.endRecording();
  final image = await scaledPicture.toImage(width, height);
  final ByteData? byteData =
  await image.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List byteList = byteData!.buffer.asUint8List();

  return BitmapDescriptor.fromBytes(byteList);
}