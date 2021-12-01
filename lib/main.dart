import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neural Art',
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.light,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _contentAdded = false;
  bool _styleAdded = false;
  File _contentImageFile = File("assets/images/null.png");
  File _styleImageFile = File("assets/images/null.png");
  int _responseOK = 0;
  ImageProvider _finalImage = AssetImage('assets/images/blob.jpg');
  final picker = ImagePicker();

  Future _contentFromCamera() async {
    final contentImg =
        await picker.getImage(source: ImageSource.camera, imageQuality: 50);
    setState(() {
      if (contentImg != null) {
        _contentImageFile = File(contentImg.path);
        _contentAdded = true;
      }
    });
  }

  Future _contentFromGallery() async {
    final contentImg =
        await picker.getImage(source: ImageSource.gallery, imageQuality: 50);
    setState(() {
      if (contentImg != null) {
        _contentImageFile = File(contentImg.path);
        _contentAdded = true;
      }
    });
  }

  Future _styleFromCamera() async {
    final styleImg =
        await picker.getImage(source: ImageSource.camera, imageQuality: 50);
    setState(() {
      if (styleImg != null) {
        _styleImageFile = File(styleImg.path);
        _styleAdded = true;
      }
    });
  }

  Future _styleFromGallery() async {
    final styleImg =
        await picker.getImage(source: ImageSource.gallery, imageQuality: 50);
    setState(() {
      if (styleImg != null) {
        _styleImageFile = File(styleImg.path);
        _styleAdded = true;
      }
    });
  }

  void _clearState() {
    setState(() {
      _styleImageFile = File("assets/images/null.png");
      _contentImageFile = File("assets/images/null.png");
      _finalImage = AssetImage('assets/images/blob.jpg');
      _responseOK = 0;
    });
  }

  void _showContentPicker() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
              child: Container(
                  child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('From gallery'),
                  onTap: () {
                    _contentFromGallery();
                    Navigator.of(context).pop();
                  }),
              ListTile(
                  leading: Icon(Icons.photo_camera),
                  title: Text("From camera"),
                  onTap: () {
                    _contentFromCamera();
                    Navigator.of(context).pop();
                  })
            ],
          )));
        });
  }

  void _showStylePicker() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
              child: Container(
                  child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('From gallery'),
                  onTap: () {
                    _styleFromGallery();
                    Navigator.of(context).pop();
                  }),
              ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text("From camera"),
                  onTap: () {
                    _styleFromCamera();
                    Navigator.of(context).pop();
                  })
            ],
          )));
        });
  }

  _uploadFiles() async {
    http.MultipartRequest request = http.MultipartRequest(
        'POST', Uri.parse("http://67c7-122-173-30-84.ngrok.io/upload"));
    Map<String, String> headers = {"Content-type": "multipart/form-data"};
    request.files.add(
      await http.MultipartFile.fromPath(
        'content',
        _contentImageFile.path,
        contentType: http_parser.MediaType('image', 'jpeg'),
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'style',
        _styleImageFile.path,
        contentType: http_parser.MediaType('image', 'jpeg'),
      ),
    );
    request.headers.addAll(headers);
    http.StreamedResponse res = await request.send();
    var response = await http.Response.fromStream(res);
    print(response.statusCode);
    setState(() {
      _responseOK = response.statusCode;
      _finalImage = Image.memory(response.bodyBytes).image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Add the images for the content and the style and hit combine",
              style: Theme.of(context).textTheme.bodyText2,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 30.0),
            ),
            _responseOK != 200
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                        Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                              image: _contentImageFile.path ==
                                      "assets/images/null.png"
                                  ? AssetImage(_contentImageFile.path)
                                  : FileImage(_contentImageFile)
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            )),
                            child: Text(
                              " ",
                              style: Theme.of(context).textTheme.headline5,
                            )),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(0.0, 0.0, 20.0, 0.0),
                        ),
                        Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                              image: _styleImageFile.path ==
                                      "assets/images/null.png"
                                  ? AssetImage(_styleImageFile.path)
                                  : FileImage(_styleImageFile) as ImageProvider,
                              fit: BoxFit.cover,
                            )),
                            child: Text(
                              " ",
                              style: Theme.of(context).textTheme.headline5,
                            )),
                      ])
                : Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                      image: _finalImage,
                      fit: BoxFit.cover,
                    )),
                  ),
            const Padding(
              padding: EdgeInsets.fromLTRB(0.0, 50.0, 0.0, 50.0),
            ),
            Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/blob.jpg"),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50.0),
                      topRight: Radius.circular(50.0),
                      bottomLeft: Radius.zero,
                      bottomRight: Radius.zero),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0.0, 60.0, 0.0, 0.0),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          _showContentPicker();
                        },
                        child: const Text("Add content image"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.grey[200],
                          onPrimary: Colors.black,
                        )),
                    ElevatedButton(
                        onPressed: () {
                          _showStylePicker();
                        },
                        child: const Text("Add style image"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.grey[200],
                          onPrimary: Colors.black,
                        )),
                    ElevatedButton(
                        onPressed: () {
                          _clearState();
                        },
                        child: const Text("Clear Images"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.grey[200],
                          onPrimary: Colors.black,
                        )),
                    ElevatedButton(
                        onPressed: _contentImageFile.path ==
                                    "assets/images/null.png" ||
                                _styleImageFile.path == "assets/images/null.png"
                            ? null
                            : _uploadFiles,
                        child: const Text("Combine"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.grey[200],
                          onPrimary: Colors.black,
                        )),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0.0, 40.0, 0.0, 0.0),
                    ),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
