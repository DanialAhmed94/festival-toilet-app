import 'dart:convert';
import 'package:crapadvisor/models/feedbackModel.dart';
import 'package:crapadvisor/screens/reviewsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_svg/svg.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:intl/intl.dart';
import '../annim/transiton.dart';
import '../apis/postFeedback.dart';
import 'package:path_provider/path_provider.dart';

class FeedbackScreen extends StatefulWidget {
  final String faciliyName;
  final double toiletLat;
  final double toiletLng;
  final String festivalId;
  final String toiletId;
 final double festivalLatitude;
 final double festivalLongitude;
final String what3words;
  FeedbackScreen(
      {required this.festivalId,
        required this.festivalLatitude,
        required this.festivalLongitude,
      required this.toiletId,
      required this.faciliyName,
      required this.toiletLat,
      required this.toiletLng,
      required this.what3words,
     });

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPosting = false;
  final ImagePicker _picker = ImagePicker();
  Map<String, int> scoresWithoutWater = {};
  Map<String, int> scoresWithWater = {};
  int totalScore = 0;
  Map<String, XFile?> images = {};
  Map<String, String> iconPaths = {
    'Cleanliness': 'assets/images/feedback_images/cleanliness icon.png.png',
    'Odour': 'assets/images/feedback_images/Odour icon.png.png',
    'AAA Disabled Access':
        'assets/images/feedback_images/AAA Disabled Access icon.png.png',
    'Green Credentials':
        'assets/images/feedback_images/Green Credentials  (Environmental Friendliness) icon.png.png',
    'Bog Roll Standard':
        'assets/images/feedback_images/Bog Roll Standard  icon.png.png',
    'Clean Flush Fluid':
        'assets/images/feedback_images/Clean Flush Fluid icon.png.png',
    'Locking System': 'assets/images/feedback_images/Locking System icon.png.png',
    'Hand Wash Facility': 'assets/images/feedback_images/Group 120.png.png',
    'Soap Availability': 'assets/images/feedback_images/Group 121.png.png',
    'Hand Sanitiser Availability':
        'assets/images/feedback_images/Hand Sanitiser Availability icon.png.png',
    'Water Availability':
        'assets/images/feedback_images/Water Availability icon.png.png',
  };
  late TextEditingController _evaluationDateControlor;
  late TextEditingController _facilityNameControlor;
  late TextEditingController _facilityLocationControlor;
  late TextEditingController _userNameContolor;

  @override
  void initState() {
    super.initState();
    _evaluationDateControlor = TextEditingController(
        text: "${DateFormat('yyyy-MM-dd').format(DateTime.now())}");
    _facilityNameControlor =
        TextEditingController(text: "${widget.faciliyName}");
    _facilityLocationControlor =
        TextEditingController(text: "${widget.what3words}");
    _userNameContolor = TextEditingController();
    initializeScores();
  }

  @override
  dispose() {
    super.dispose();
    _facilityLocationControlor.dispose();
    _facilityNameControlor.dispose();
    _evaluationDateControlor.dispose();
    _userNameContolor.dispose();
  }

  void initializeScores() {
    List<String> categoriesWithoutWater = [
      'Cleanliness',
      'Odour',
      'AAA Disabled Access',
      'Green Credentials',
      'Bog Roll Standard',
      'Clean Flush Fluid',
      'Locking System',
      'Hand Wash Facility',
      'Soap Availability',
      'Hand Sanitiser Availability',
      'Water Availability',
    ];
    List<String> categoriesWithWater = [
      'Water Pressure',
      'Water Temperature',
      'Changing Space',
      'Hanging Facilities',
      'Ease of Access'
    ];

    scoresWithoutWater = Map.fromIterable(
      categoriesWithoutWater,
      key: (category) => category,
      value: (category) => 0,
    );
    scoresWithWater = Map.fromIterable(
      categoriesWithWater,
      key: (category) => category,
      value: (category) => 0,
    );
  }

  //Function to pick an image
  Future<void> pickImage(String category) async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      File compressedImage = await compressImage(File(pickedImage.path));
      setState(() {
        images[category] = XFile(compressedImage.path);
      });
    }
  }

  Future<File> compressImage(File imageFile) async {
    // Generate a unique file name based on original file name and timestamp
    String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
    String directory = (await getApplicationDocumentsDirectory()).path;
    String compressedImagePath = '$directory/$fileName';

    // Compress the image with quality 75%
    List<int> compressedBytes = await FlutterImageCompress.compressWithList(
      imageFile.readAsBytesSync(),
      quality: 75,
    );

    // Write the compressed bytes to the new file
    File compressedImageFile = File(compressedImagePath);
    await compressedImageFile.writeAsBytes(compressedBytes);

    return compressedImageFile;
  }

  void handleSubmit(BuildContext context) async {
    setState(() {
      _isPosting = true;
    });
    if (_userNameContolor.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your name.'),
          action: SnackBarAction(
              label: "OK",
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }),
        ),
      );
      setState(() {
        _isPosting = false;
      });
    }
    if (_formKey.currentState!.validate()) {
      List<String> categoriesWithoutWater = [
        'Cleanliness',
        'Odour',
        'AAA Disabled Access',
        'Green Credentials',
        'Bog Roll Standard',
        'Clean Flush Fluid',
        'Locking System',
        'Hand Wash Facility',
        'Soap Availability',
        'Hand Sanitiser Availability',
        'Water Availability',
      ];

      // Prepare image data for review (conveting to base64 string)
      Map<String, String?> imageBase64 = {};

      for (String category in categoriesWithoutWater) {
        if (images[category] != null) {
          try {
            List<int> imageBytes = await images[category]!.readAsBytes();
            if (imageBytes.isNotEmpty) {
              String base64Image = base64Encode(imageBytes);
              imageBase64[category] = base64Image;
            } else {
              // Handle empty image bytes
              print('Empty image bytes for category: $category');
              // Optionally, you can set imageBase64[category] to null or handle it differently
            }
          } catch (e) {
            // Handle errors during image encoding
            print('Error encoding image for category $category: $e');
            // Optionally, you can set imageBase64[category] to null or handle it differently
          }
        }
      }

      int totalScoreWithoutWater = scoresWithoutWater.values
          .reduce((value, element) => value + element)
          .toInt();
      int totalScoreWithWater = scoresWithWater.values
          .reduce((value, element) => value + element)
          .toInt();
      totalScore = totalScoreWithWater + totalScoreWithoutWater;

      // Create a review object
      ToiletReview review = ToiletReview(
        toiletId: widget.toiletId,
        festivalId: widget.festivalId,
        what3words: widget.what3words.toString() ??" there is nothing",
        toiletType_name: widget.faciliyName.toString() ??" there is nothing",
        date: _evaluationDateControlor.text,
        username: _userNameContolor.text,
        cleanlinessScore: (scoresWithoutWater['Cleanliness']).toString(),
        cleanlinessImage: imageBase64['Cleanliness'],
        odourScore: (scoresWithoutWater['Odour']).toString(),
        odourImage: imageBase64['Odour'],
        aaaDisabledAccessScore:
            (scoresWithoutWater['AAA Disabled Access']).toString(),
        aaaDisabledAccessImage: imageBase64['AAA Disabled Access'],
        greenCredentialsScore:
            (scoresWithoutWater['Green Credentials']).toString(),
        greenCredentialsImage: imageBase64['Green Credentials'],
        bogRollStandardScore:
            (scoresWithoutWater['Bog Roll Standard']).toString(),
        bogRollStandardImage: imageBase64['Bog Roll Standard'],
        cleanFlushFluidScore:
            (scoresWithoutWater['Clean Flush Fluid']).toString(),
        cleanFlushFluidImage: imageBase64['Clean Flush Fluid'],
        lockingSystemScore: (scoresWithoutWater['Locking System']).toString(),
        lockingSystemImage: imageBase64['Locking System'],
        handWashFacilityScore:
            (scoresWithoutWater['Hand Wash Facility']).toString(),
        handWashFacilityImage: imageBase64['Hand Wash Facility'],
        soapAvailabilityScore:
            (scoresWithoutWater['Soap Availability']).toString(),
        soapAvailabilityImage: imageBase64['Soap Availability'],
        handSanitizerAvailabilityScore:
            (scoresWithoutWater['Hand Sanitiser Availability']).toString(),
        handSanitizerAvailabilityImage:
            imageBase64['Hand Sanitiser Availability'],
        waterAvailabilityScore:
            (scoresWithoutWater['Water Availability']).toString(),
        waterAvailabilityImage: imageBase64['Water Availability'],
        waterPressureScore: (scoresWithWater['Water Pressure']).toString(),
        waterTemperatureScore:
            (scoresWithWater['Water Temperature']).toString(),
        changingSpaceScore: (scoresWithWater['Changing Space']).toString(),
        hangingFacilityScore:
            (scoresWithWater['Hanging Facilities']).toString(),
        easeOfAccessScore: (scoresWithWater['Ease of Access']).toString(),
        totalScore: totalScore.toString(),
      );

      // Post the review
      print(review);
      postReview(review, context);
    }
    await Future.delayed(Duration(seconds: 20)); // Replace this with your actual posting logic

    setState(() {
      _isPosting = false;
    });
  }

  // Widget to render score slider
  Widget scoreSliderWithoutWater(String category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Text(
              "Score",
              style: TextStyle(fontFamily: "Ubuntu-Bold.ttf", fontSize: 18),
            ),
          ),
          SizedBox(height: 8), // Add some space between "Score" and the slider
          SfSlider(
            min: 0.0,
            max: 10.0,
            value: scoresWithoutWater[category] ?? 0.0,
            interval: 1,
            stepSize: 1,
            showLabels: true,
            enableTooltip: true,
            showDividers: true,
            activeColor: Color(0xFF445EFF),
            onChanged: (dynamic value) {
              setState(() {
                scoresWithoutWater[category] = value.toInt();
              });
            },
          ),
        ],
      ),
    );
  }

  //widget to render scoreslider withwater section
  Widget scoreSliderWithWater(String category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Text(
              "Score",
              style: TextStyle(fontFamily: "Ubuntu-Bold.ttf", fontSize: 18),
            ),
          ),
          SizedBox(height: 8), // Add some space between "Score" and the slider
          Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SfSlider(
                  min: 0.0,
                  max: 10.0,
                  value: scoresWithWater[category] ?? 0.0,
                  interval: 1,
                  stepSize: 1,
                  showLabels: true,
                  enableTooltip: true,
                  showDividers: true,
                  activeColor: Color(0xFF445EFF),
                  onChanged: (dynamic value) {
                    setState(() {
                      scoresWithWater[category] = value.toInt();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Function to build form fields
  List<Widget> buildFormFieldsWithoutWaterSection() {
    List<String> categoriesWithoutWater = [
      'Cleanliness',
      'Odour',
      'AAA Disabled Access',
      'Green Credentials',
      'Bog Roll Standard',
      'Clean Flush Fluid',
      'Locking System',
      'Hand Wash Facility',
      'Soap Availability',
      'Hand Sanitiser Availability',
      'Water Availability',

      // Add other categories here...
    ];

    List<Widget> fields = [];

    for (String category in categoriesWithoutWater) {
      fields.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color:Color(0xFFD1E1EE),

              child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontFamily: 'Ubuntu-Bold',
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8,bottom: 8),
                      child: Image.asset(iconPaths[category].toString(),height: 60,width: 60,),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: (MediaQuery.of(context).size.width) / 2,
                      //slider
                      child: scoreSliderWithoutWater(category),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.black, // Border color
                            width: 1, // Border width
                          ),
                        ),
                        child: images[category] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                // Match container's borderRadius
                                child: Image.file(
                                  File(images[category]!.path),
                                  fit: BoxFit
                                      .cover, // Ensures the image covers the clip area
                                ),
                              )
                            : Center(
                                child: Text(
                                  'No image captured',
                                  style:
                                      TextStyle(fontFamily: 'Poppins-Medium'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          pickImage(category);
                        },
                        icon: Icon(Icons.camera_alt_rounded)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return fields;
  }

  List<Widget> buildFormFieldsWithWaterSection() {
    List<String> categoriesWithWater = [
      'Water Pressure',
      'Water Temperature',
      'Changing Space',
      'Hanging Facilities',
      'Ease of Access'
    ];

    List<Widget> fields = [];

    for (String category in categoriesWithWater) {
      fields.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 11),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontFamily: 'Ubuntu-Bold',
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Spacer(),
                  ],
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: scoreSliderWithWater(category),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return fields;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            centerTitle: true,
            toolbarHeight: 75,
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: SvgPicture.asset(
                'assets/svgs/back-icon.svg',
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              "Feedback",
              style: TextStyle(
                fontFamily: "Poppins-Bold",
                fontSize: 24,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 20,
                              child: Image.asset(
                                  "assets/images/feedback_images/verticalLine.png"),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 15, top: 20),
                                  child: TextFormField(
                                    controller: _facilityLocationControlor,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: "Location of Facility",
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(width: 1.0),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(right: 15),
                                  child: TextFormField(
                                    controller: _evaluationDateControlor,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: "Date of evaluation",
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(width: 1.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 20,
                              child: Image.asset(
                                  "assets/images/feedback_images/verticalLine.png"),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 15, top: 10),
                                  child: TextFormField(
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return " Please enter name";
                                      }
                                    },
                                    controller: _userNameContolor,
                                    decoration: InputDecoration(
                                      labelText: "Name",
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(width: 1.0),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(right: 15),
                                  child: TextFormField(
                                    controller: _facilityNameControlor,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: "Type of facility",
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(width: 1.0),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(right: 8,bottom: 8,),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width*0.4,

                                     // Set your desired width here
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          FadePageRouteBuilder(
                                            widget: Reviews(
                                              festival_id:widget.festivalId,
                                              festivalLocation: LatLng(
                                                  widget.festivalLatitude,
                                                  widget.festivalLongitude),
                                            )
                                          ),
                                        );
                                        // Navigator.push(
                                        //     context,
                                        //     MaterialPageRoute(
                                        //         builder: (context) => Reviews(
                                        //           festival_id:widget.festivalId,
                                        //           festivalLocation: LatLng(
                                        //               widget.festivalLatitude,
                                        //               widget.festivalLongitude),
                                        //         )));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: Text(
                                        "See Reviews",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontFamily: "Poppins-Medium",
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ...buildFormFieldsWithoutWaterSection(),
                      Divider(),
                      Row(
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              "assets/images/waterportion/water-shower.png",
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/images/waterportion/background.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.2),
                            ...buildFormFieldsWithWaterSection(),
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Container(
                                width: double.infinity,
                                child: Material(
                                  borderRadius: BorderRadius.circular(8), // Optional: for rounded corners
                                  color: Colors.transparent, // Set to transparent to avoid background color
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8), // Match the border radius
                                    onTap: _isPosting ? null : () {
                                      handleSubmit(context);
                                    },
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF45A3D9),  // Color at 0% (hex code: #45A3D9)
                                            Color(0xFF45D9D0),  // Color at 100% (hex code: #45D9D0)
                                          ],
                                          begin: Alignment.topLeft,  // You can adjust the start and end points
                                          end: Alignment.bottomRight,
                                          stops: [0.0, 1.0],  // Corresponds to the 0% and 100% stops
                                        ),
                                        borderRadius: BorderRadius.circular(8), // Match the button's corners
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 16), // Adjust padding as needed
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Save",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: "Ubuntu-Bold.ttf",
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),


                            ),
                            SizedBox(height: 10,)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isPosting)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

}
