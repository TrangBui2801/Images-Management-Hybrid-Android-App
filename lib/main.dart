// ignore_for_file: prefer_const_constructors, prefer_const_declarations

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_management_app/Entity/image.dart';
import 'package:image_management_app/Helper/sql_helper.dart';
import 'package:image_management_app/navigation/routes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

final String noImgAvailable = 'lib/Assets/Images/error.png';
final String noDataFound = 'lib/Assets/Images/error.png';

void main() {
  runApp(MaterialApp(
    theme: ThemeData(fontFamily: 'Cosmic Sans MS'),
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  final String? imgURL;
  final String? imgLocation;
  const Home({Key? key, this.imgURL, this.imgLocation}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Cosmic Sans MS'),
      home: ViewImages(),
      initialRoute: RouteNames.home,
      routes: routes,
      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (_) => const Home()),
    );
  }
}

class ViewImages extends StatefulWidget {
  final String? imgURL;
  final String? imgLocation;

  const ViewImages({Key? key, this.imgURL, this.imgLocation}) : super(key: key);

  @override
  State<ViewImages> createState() => _ViewImagesState();
}

class _ViewImagesState extends State<ViewImages> {
  TextEditingController newImageURLController = TextEditingController();
  TextEditingController newImageLocationController = TextEditingController();
  String newImageName = "";
  // validate url 
  final _formKey = GlobalKey<FormState>();

  // khởi tạo đối tượng để thao tác với camera
  ImagePicker picker = ImagePicker();
  // đối tượng để thao tác với ảnh chụp
  File? image;

  Position? location;

  // index ảnh trong mảng
  int imgIndex = 0;

  // khai báo mảng được lưu trong sqlite
  List<ImageEntity> imgList = [];

  Future<void> loadData() async {
    // lấy ds ảnh từ sqlite thông qua getImages()
    final dt = await SQLHelper.getImages();

    // kiểm tra các tham số đc truyền về màn thông qua route
    setState(() {
      if (widget.imgLocation == null) {
        newImageLocationController.text = "Unknown";
      } else {
        newImageLocationController.text = widget.imgLocation!;
      }
      if (widget.imgURL != null) {
        newImageURLController.text = widget.imgURL!;
      }
      imgList = dt;
    });
  }

  void generateFileName() {
    // lấy thời gian hiện tại
    DateTime currentDateTime = DateTime.now();
    // format tên ảnh
    String fileName =
        "${currentDateTime.year}-${currentDateTime.month}-${currentDateTime.day}_${currentDateTime.hour}:${currentDateTime.minute}";
    // cập nhật data
    setState(() {
      newImageName = fileName;
    });
  }

  void loadLocation() async {
    // get permission và lấy location của ảnh
    Position dt = await determineLocation();
    setState(() {    
      location = dt;
    });
  }

  @override
  // khởi tạo data cho màn
  void initState() {
    loadLocation();
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          backgroundColor: Colors.blue.shade500,
          elevation: 0.0,
          toolbarHeight: 65,
          centerTitle: true,
          title: Text("IMAGE MANAGEMENT"),
          actions: [
            IconButton(
                onPressed: () {
                  takePicture();
                },
                icon: Icon(Icons.camera_alt))
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (imgList.isEmpty) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  // ignore: prefer_const_literals_to_create_immutables
                  children: [
                    Container(
                      height: 300,
                      child: Padding(
                        padding: EdgeInsets.only(top: 150),
                        child: Text("No image found"),
                      ),
                    )
                  ],
                )
              ] else if (imgList[imgIndex].imgLocation == "Unknown") ...[
                Image.network(
                  imgList[imgIndex].imgURL,
                  height: 300,
                  fit: BoxFit.contain,
                  frameBuilder: (_, image, loadingBuilder, __) {
                    if (loadingBuilder == null) {
                      return const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return image;
                  },
                  loadingBuilder: (BuildContext context, Widget image,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return image;
                    return SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Image.asset(
                    noImgAvailable,
                    height: 300,
                    fit: BoxFit.fitHeight,
                  ),
                )
              ] else ...[
                Image.file(
                  File(imgList[imgIndex].imgURL),
                  height: 300,
                  fit: BoxFit.fitHeight,
                ),
              ],
              if (imgList.isNotEmpty) ...[
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)),
                  color: Colors.grey.shade300,
                  elevation: 1.0,
                  child: ListTile(
                    title: Text(imgList[imgIndex].imgName),
                    subtitle: Text(imgList[imgIndex].imgLocation),
                  ),
                )
              ] else ...[
                Container()
              ],
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: MaterialButton(
                          color: Colors.blue.shade500,
                          onPressed: () {
                            if (imgList.isNotEmpty) {
                              setState(() {
                                if (imgIndex > 0) {
                                  imgIndex--;
                                }
                              });
                            } else {
                              null;
                            }
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)),
                          padding: EdgeInsets.zero,
                          child: Ink(
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(80.0)),
                            ),
                            child: Container(
                              constraints: const BoxConstraints(
                                  minWidth: 120,
                                  minHeight:
                                      40.0), // min sizes for Material buttons
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                      child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  )),
                                  Text(
                                    "Previous",
                                    style: TextStyle(color: Colors.white),
                                  )
                                ],
                              ),
                            ),
                          )),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: MaterialButton(
                          color: Colors.blue.shade500,
                          onPressed: () {
                            if (imgList.isNotEmpty) {
                              setState(() {
                                if (imgIndex < imgList.length - 1) {
                                  imgIndex++;
                                }
                              });
                            } else {
                              null;
                            }
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)),
                          padding: EdgeInsets.zero,
                          child: Ink(
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(80.0)),
                            ),
                            child: Container(
                              constraints: const BoxConstraints(
                                  minWidth: 120,
                                  minHeight:
                                      40.0), // min sizes for Material buttons
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Next",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Container(
                                      child: Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  )),
                                ],
                              ),
                            ),
                          )),
                    )
                  ],
                ),
              ),
              Container(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: Form(
                    key: _formKey,
                    child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            TextFormField(
                              keyboardType: TextInputType.none,
                              minLines: 1,
                              maxLines: null,
                              controller: newImageURLController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30)),
                                ),
                                labelText: "Image URL",
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'URL of image cannot be blank';
                                } else {
                                  String urlFormat =
                                      r"^(https?|ftp|file):\/\/[-a-zA-Z0-9+&@#\/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#\/%=~_|]";
                                  var urlRegex = RegExp(urlFormat);
                                  if (!urlRegex.hasMatch(value) &&
                                      newImageLocationController.text ==
                                          "Unknown") {
                                    return 'URL of image is not supported';
                                  }
                                }
                                return null;
                              },
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 20.0, horizontal: 80.0),
                              child: MaterialButton(
                                  color: Colors.blue.shade500,
                                  onPressed: () {
                                    addImage();
                                  },
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30.0)),
                                  padding: EdgeInsets.zero,
                                  child: Ink(
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(80.0)),
                                    ),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                          minWidth: 120,
                                          minHeight:
                                              40.0), // min sizes for Material buttons
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.save,
                                                color: Colors.white,
                                              )),
                                          Text('Save',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  )),
                            )
                          ],
                        )),
                  ),
                ),
              )
            ],
          ),
        ));
  }

  // xử lý data và insert vào db
  Future<void> addImage() async {
    if (_formKey.currentState!.validate()) {
      // khởi tạo đối tượng rỗng
      ImageEntity imageEntity = ImageEntity.emptyImage();
      // get url thông qua Texteditingcontroller,
      imageEntity.imgURL = newImageURLController.text;
      if (newImageName == "") {
        generateFileName();
      }
      // khởi tạo fileName cho ảnh
      imageEntity.imgName = newImageName;
      // get location thông qua Texteditingcontroller
      imageEntity.imgLocation = newImageLocationController.text;
      // insert ảnh vào db
      int result = await SQLHelper.addImage(imageEntity); 
      if (!mounted) return;
      // kiểm tra result
      if (result > 0) {
        // thông báo và set lại values
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Add image success")));
        setState(() {
          imgList.add(imageEntity);
          imgIndex = imgList.length - 1;
          newImageURLController.text = "";
          newImageLocationController.text = "Unknown";
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Add image fail")));
      }
    }
  }

  // chụp ảnh bằng camera vật lý
  Future<void> takePicture() async {
    // khởi tạo đối tượng XFile để sử dụng camera
    XFile? takenImage = await picker.pickImage(source: ImageSource.camera);
    if (takenImage == null) return;
    // lấy đường dẫn thư mục để lưu ảnh
    Directory directory = await getApplicationDocumentsDirectory();
    generateFileName();
    // khởi tạo ảnh ở đường dẫn đc lấy ở trên
    File newImage = File('${directory.path}/$newImageName');
    // ghi ảnh vào trong đường dẫn 
    await newImage.writeAsBytes(File(takenImage.path).readAsBytesSync());
    setState(() {
      image = newImage;
      if (image != null && location != null) {
        newImageURLController.text = image!.path;
        newImageLocationController.text = location!.toString();
      }
    });
    generateFileName();
  }
}

Future<Position> determineLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}
