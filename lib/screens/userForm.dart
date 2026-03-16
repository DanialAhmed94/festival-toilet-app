// import 'package:crapadvisor/screens/mainScreen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:lottie/lottie.dart';
// import '../apis/postUserData.dart';
// import '../services/getuseraddres.dart';
//
// class UserForm extends StatefulWidget {
//   const UserForm({super.key});
//
//   @override
//   State<UserForm> createState() => _UserFormState();
// }
//
// class _UserFormState extends State<UserForm> with TickerProviderStateMixin {
//   bool _isPosting = false;
//
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   final TextEditingController _emailControler = TextEditingController();
//   final TextEditingController _nameControler = TextEditingController();
//   final TextEditingController _lastNameControler = TextEditingController();
//   final TextEditingController _dobControler = TextEditingController();
//   TextEditingController _locationControler = TextEditingController();
//   String _address = "";
//   late FocusNode _emailFocusNode;
//   late FocusNode _nameFocusNode;
//   late FocusNode _lastNameFocusNode;
//   late FocusNode _dobFocusNode;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _getUserAddress();
//     // Initialize FocusNodes
//     _emailFocusNode = FocusNode();
//     _nameFocusNode = FocusNode();
//     _lastNameFocusNode = FocusNode();
//     _dobFocusNode = FocusNode();
//   }
//
//   @override
//   void dispose() {
//     if (_emailControler != null) {
//       _emailControler.dispose();
//     }
//     if (_nameControler != null) {
//       _nameControler.dispose();
//     }
//     if (_lastNameControler != null) {
//       _lastNameControler.dispose();
//     }
//     if (_dobControler != null) {
//       _dobControler.dispose();
//     }
//     if (_locationControler != null) {
//       _locationControler.dispose();
//     }
//     _emailFocusNode.dispose();
//     _nameFocusNode.dispose();
//     _lastNameFocusNode.dispose();
//     _dobFocusNode.dispose();
//     super.dispose(); // Dispose of the animation controller
//   }
//
//   Future<void> _getUserAddress() async {
//     final tempAddress = await getUserAddress();
//     setState(() {
//       _address = tempAddress;
//       _locationControler.text = _address;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double paddingTop = MediaQuery.of(context).size.height * 0.1;
//     double screenHeight = MediaQuery.of(context).size.height;
//     double appBarHeight = screenHeight * 0.001;
//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: Image.asset(
//               'assets/images/userFormbackground.png',
//               // Replace with your image path
//               fit: BoxFit.cover,
//               height: MediaQuery.of(context).size.height *
//                   0.5, // Half of the screen height
//             ),
//           ),
//           Positioned(
//             top: MediaQuery.of(context).size.height * 0.1,
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.only(right: 10, top: 20),
//                         child: TextButton(
//                             onPressed: () {
//                               Navigator.pushAndRemoveUntil(
//                                   context,
//                                   MaterialPageRoute(
//                                       builder: (context) => MainScreen()),
//                                   (route) => false);
//                               // Navigator.push(context,  MaterialPageRoute(builder: (context)=>MainScreen()));
//                             },
//                             child: Text(
//                               "SKIP",
//                               style: TextStyle(
//                                 color: Colors.redAccent,
//                                 fontSize: 14,
//                               ),
//                             )),
//                       )
//                     ],
//                   ),
//                   Image.asset(
//                     'assets/images/festivalResourceLogo.png',
//                     height: 150,
//                     width: 150,
//                   ),
//                   Padding(
//                     padding: EdgeInsets.only(
//                         top: MediaQuery.of(context).size.height * 0.05),
//                     child: Text(
//                       "Early Access",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontFamily: "Ubuntu-Bold",
//                           fontWeight: FontWeight.w700,
//                           fontSize: 24),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 15,left: 15,top: 15),
//                     child: Text(
//                       "Unlock exclusive early access to our FestivalResource app! Be the first to experience all the exciting features we have to offer. Simply provide your email or basic data below to get started.",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                           fontFamily: "Ubuntu-Regular",
//                           fontSize: 13),
//                     ),
//                   ),
//
//                   Padding(
//                     padding: const EdgeInsets.only(
//                         top: 40, left: 10, right: 10, bottom: 10),
//                     child: Form(
//                       key: _formKey,
//                       child: Column(
//                         children: [
//                           Row(
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsets.only(right: 15),
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                       gradient: LinearGradient(
//                                         colors: [
//                                           Color(0xFF45A3D9),  // Color at 0% (hex code: #45A3D9)
//                                           Color(0xFF45D9D0),  // Color at 100% (hex code: #45D9D0)
//                                         ],
//                                         begin: Alignment.topLeft,  // You can adjust the start and end points
//                                         end: Alignment.bottomRight,
//                                         stops: [0.0, 1.0],  // Corresponds to the 0% and 100% stops
//                                       ),                                      borderRadius: BorderRadius.circular(5)),
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(6.0),
//                                     child: SvgPicture.asset(
//                                         "assets/svgs/email.svg"),
//                                   ),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: TextFormField(
//                                   // controller: _textFieldController,
//                                   keyboardType: TextInputType.emailAddress,
//                                   controller: _emailControler,
//                                   textInputAction: TextInputAction.next,
//                                   onFieldSubmitted: (_) {
//                                     FocusScope.of(context)
//                                         .requestFocus(_nameFocusNode);
//                                   },
//                                   validator: (value) {
//                                     if (value == null || value.isEmpty) {
//                                       return 'Please enter your email address';
//                                     }
//                                     // You can add additional validation logic here if needed
//                                     else if (!RegExp(
//                                             r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                                         .hasMatch(value)) {
//                                       return 'Please enter a valid email address';
//                                     }
//                                     return null;
//                                   },
//                                   decoration: InputDecoration(
//                                     labelText: "Email Address",
//                                     // Add your desired label text here
//                                     border: OutlineInputBorder(
//                                         borderSide: BorderSide(width: 1.0)),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.only(top: 10),
//                             child: Row(
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(right: 15),
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           colors: [
//                                             Color(0xFF45A3D9),  // Color at 0% (hex code: #45A3D9)
//                                             Color(0xFF45D9D0),  // Color at 100% (hex code: #45D9D0)
//                                           ],
//                                           begin: Alignment.topLeft,  // You can adjust the start and end points
//                                           end: Alignment.bottomRight,
//                                           stops: [0.0, 1.0],  // Corresponds to the 0% and 100% stops
//                                         ),                                        borderRadius: BorderRadius.circular(5)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(6.0),
//                                       child: SvgPicture.asset(
//                                           "assets/svgs/name.svg"),
//                                     ),
//                                   ),
//                                 ),
//                                 Expanded(
//                                   child: TextFormField(
//                                     keyboardType: TextInputType.name,
//                                     controller: _nameControler,
//                                     focusNode: _nameFocusNode,
//                                     textInputAction: TextInputAction.next,
//                                     onFieldSubmitted: (_) {
//                                       FocusScope.of(context)
//                                           .requestFocus(_lastNameFocusNode);
//                                     },
//                                     validator: (value) {
//                                       if (value == null || value.isEmpty) {
//                                         return 'Please enter your name';
//                                       }
//                                       // You can add additional validation logic here if needed
//                                       else if (!RegExp(r'^[a-zA-Z]+ *$')
//                                           .hasMatch(value)) {
//                                         return 'Name should contain only alphabetic characters';
//                                       }
//                                       return null;
//                                     },
//                                     decoration: InputDecoration(
//                                       labelText: "Name",
//                                       // Add your desired label text here
//                                       border: OutlineInputBorder(
//                                           borderSide: BorderSide(width: 1.0)),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.only(top: 10),
//                             child: Row(
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(right: 15),
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           colors: [
//                                             Color(0xFF45A3D9),  // Color at 0% (hex code: #45A3D9)
//                                             Color(0xFF45D9D0),  // Color at 100% (hex code: #45D9D0)
//                                           ],
//                                           begin: Alignment.topLeft,  // You can adjust the start and end points
//                                           end: Alignment.bottomRight,
//                                           stops: [0.0, 1.0],  // Corresponds to the 0% and 100% stops
//                                         ),                                        borderRadius: BorderRadius.circular(5)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(6.0),
//                                       child: SvgPicture.asset(
//                                           "assets/svgs/name.svg"),
//                                     ),
//                                   ),
//                                 ),
//                                 Expanded(
//                                   child: TextFormField(
//                                     keyboardType: TextInputType.name,
//                                     controller: _lastNameControler,
//                                     focusNode: _lastNameFocusNode,
//                                     textInputAction: TextInputAction.next,
//                                     // onFieldSubmitted: (_) {
//                                     //   FocusScope.of(context).requestFocus(
//                                     //       _dobFocusNode);
//                                     // },
//                                     validator: (value) {
//                                       if (value == null || value.isEmpty) {
//                                         return 'Please enter your last name';
//                                       }
//                                       // You can add additional validation logic here if needed
//                                       else if (!RegExp(r'^[a-zA-Z]+ *$')
//                                           .hasMatch(value)) {
//                                         return 'Name should contain only alphabetic characters with optional spaces at the end';
//                                       }
//                                       return null;
//                                     },
//                                     decoration: InputDecoration(
//                                       labelText: "Last name",
//                                       // Add your desired label text here
//                                       border: OutlineInputBorder(
//                                           borderSide: BorderSide(width: 1.0)),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.only(top: 10),
//                             child: Row(
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(right: 15),
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           colors: [
//                                             Color(0xFF45A3D9),  // Color at 0% (hex code: #45A3D9)
//                                             Color(0xFF45D9D0),  // Color at 100% (hex code: #45D9D0)
//                                           ],
//                                           begin: Alignment.topLeft,  // You can adjust the start and end points
//                                           end: Alignment.bottomRight,
//                                           stops: [0.0, 1.0],  // Corresponds to the 0% and 100% stops
//                                         ),                                        borderRadius: BorderRadius.circular(5)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.only(
//                                           top: 6,
//                                           bottom: 6,
//                                           right: 10,
//                                           left: 8),
//                                       child: SvgPicture.asset(
//                                           "assets/svgs/location.svg"),
//                                     ),
//                                   ),
//                                 ),
//                                 Expanded(
//                                   child: TextFormField(
//                                     readOnly: true,
//                                     controller: _locationControler,
//                                     decoration: InputDecoration(
//                                       labelText: "Location",
//                                       // Add your desired label text here
//                                       border: OutlineInputBorder(
//                                           borderSide: BorderSide(width: 1.0)),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.only(top: 10),
//                             child: Row(
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(right: 15),
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           colors: [
//                                             Color(0xFF45A3D9),  // Color at 0% (hex code: #45A3D9)
//                                             Color(0xFF45D9D0),  // Color at 100% (hex code: #45D9D0)
//                                           ],
//                                           begin: Alignment.topLeft,  // You can adjust the start and end points
//                                           end: Alignment.bottomRight,
//                                           stops: [0.0, 1.0],  // Corresponds to the 0% and 100% stops
//                                         ),
//                                         borderRadius: BorderRadius.circular(5)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(6.0),
//                                       child: Icon(
//                                         Icons.date_range_rounded,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 Expanded(
//                                   child: GestureDetector(
//                                     onTap: () async {
//                                       final DateTime? pickedDate =
//                                           await showDatePicker(
//                                         context: context,
//                                         initialDate: DateTime.now(),
//                                         firstDate: DateTime(1900),
//                                         lastDate: DateTime.now(),
//                                       );
//                                       if (pickedDate != null) {
//                                         setState(() {
//                                           _dobControler.text = pickedDate
//                                               .toString()
//                                               .substring(0, 10);
//                                         });
//                                       }
//                                     },
//                                     child: AbsorbPointer(
//                                       child: TextFormField(
//                                         controller: _dobControler,
//                                         //  focusNode: _dobFocusNode,
//                                         validator: (value) {
//                                           if (value == null || value.isEmpty) {
//                                             return " Please enter date of birth";
//                                           }
//                                         },
//                                         decoration: InputDecoration(
//                                           labelText: "Date of birth",
//                                           // Add your desired label text here
//                                           border: OutlineInputBorder(
//                                               borderSide:
//                                                   BorderSide(width: 1.0)),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(20.0),
//                             child: Container(
//                               width: MediaQuery.of(context).size.width * 0.6,
//                               child: Material(
//                                 borderRadius: BorderRadius.circular(8), // Optional: for rounded corners
//                                 color: Colors.transparent, // Set to transparent to avoid background color
//                                 child: InkWell(
//                                   borderRadius: BorderRadius.circular(8), // Match the border radius
//                                   onTap: _isPosting ? null : () {
//                                     _showSuccessDialog(
//                                       context,
//                                       _formKey,
//                                       _emailControler.text,
//                                       _nameControler.text,
//                                       _lastNameControler.text,
//                                       _dobControler.text,
//                                       _locationControler.text,
//                                     );
//                                   },
//                                   child: Ink(
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(
//                                         colors: [
//                                           Color(0xFF45A3D9),  // Color at 0% (hex code: #45A3D9)
//                                           Color(0xFF45D9D0),  // Color at 100% (hex code: #45D9D0)
//                                         ],
//                                         begin: Alignment.topLeft,  // You can adjust the start and end points
//                                         end: Alignment.bottomRight,
//                                         stops: [0.0, 1.0],  // Corresponds to the 0% and 100% stops
//                                       ),
//                                       borderRadius: BorderRadius.circular(8), // Match the button's corners
//                                     ),
//                                     child: Container(
//                                       padding: EdgeInsets.symmetric(vertical: 16), // Adjust padding as needed
//                                       alignment: Alignment.center,
//                                       child: Text(
//                                         "Submit",
//                                         style: TextStyle(
//                                           fontFamily: "Ubuntu",
//                                           fontSize: 19,
//                                           color: Colors.white,
//                                         ),
//                                         textAlign: TextAlign.center,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//
//                             // child: Container(
//                             //   width: MediaQuery.of(context).size.width * 0.6,
//                             //   child: ElevatedButton(
//                             //       onPressed: _isPosting
//                             //           ? null
//                             //           : () {
//                             //               _showSuccessDialog(
//                             //                   context,
//                             //                   _formKey,
//                             //                   _emailControler.text,
//                             //                   _nameControler.text,
//                             //                   _lastNameControler.text,
//                             //                   _dobControler.text,
//                             //                   _locationControler.text);
//                             //             },
//                             //       style: ElevatedButton.styleFrom(
//                             //         backgroundColor: Color(0xFF0590FF),
//                             //       ),
//                             //       child: Text(
//                             //         "Submit",
//                             //         style: TextStyle(
//                             //             fontFamily: "Ubuntu",
//                             //             fontSize: 19,
//                             //             color: Colors.white),
//                             //         textAlign: TextAlign.center,
//                             //       )),
//                             // ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           ),
//           if (_isPosting)
//             Container(
//               color: Colors.black.withOpacity(0.5),
//               child: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   void _showSuccessDialog(
//       BuildContext context,
//       GlobalKey<FormState> formKey,
//       String email,
//       String name,
//       String lastName,
//       String dob,
//       String location) async {
//     setState(() {
//       _isPosting = true;
//     });
//     if (_emailControler.text.isEmpty ||
//         _nameControler.text.isEmpty ||
//         _lastNameControler.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Please fill out all the required fields.'),
//         action: SnackBarAction(
//             label: "OK",
//             onPressed: () {
//               ScaffoldMessenger.of(context).hideCurrentSnackBar();
//             }),
//       ));
//       setState(() {
//         _isPosting = false;
//       });
//     }
//     if (formKey.currentState!.validate()) {
//       // Form is valid, perform API call to submit form data
//       submitForm(context, email, name, lastName, dob, location);
//     }
//     await Future.delayed(Duration(seconds: 2));
//
//     setState(() {
//       _isPosting = false;
//     });
//   }
// }
