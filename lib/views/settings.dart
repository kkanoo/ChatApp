import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:messenger_clone/services/database.dart';
import 'package:messenger_clone/views/home.dart';
import 'dart:io';
import '../helperfunctions/sharedpref_helper.dart';

class Settings1 extends StatefulWidget {
  @override
  _Settings1State createState() => _Settings1State();
}

class _Settings1State extends State<Settings1> {
  File? _pickedImage;
  String? myName, myProfilePic, myUserName, myEmail, myUserId, url;
  TextEditingController name = TextEditingController();
  bool submit = false;
  getMyInfoFromSharedPreference() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();
    myUserId = await SharedPreferenceHelper().getUserId();
    url = myProfilePic;
    setState(() {});
    name.text = myName!;
  }

  void _pickImageC() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 150,
    );
    final pickedImageFile = pickedImage != null ? File(pickedImage.path) : null;
    _pickedImage = pickedImageFile;

    final ref = FirebaseStorage.instance
        .ref()
        .child('user_image')
        .child(myUserId! + '.jpg');
    await ref.putFile(_pickedImage!);
    url = await ref.getDownloadURL();
    setState(() {});
  }

  void _pickImageG() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 150,
    );
    final pickedImageFile = pickedImage != null ? File(pickedImage.path) : null;
    _pickedImage = pickedImageFile;

    final ref = FirebaseStorage.instance
        .ref()
        .child('user_image')
        .child(myUserId! + '.jpg');
    await ref.putFile(_pickedImage!);
    url = await ref.getDownloadURL();
    setState(() {});
  }

  doThisOnLaunch() async {
    await getMyInfoFromSharedPreference();
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    'Name field cannot be empty, please enter a valid name of length greater than 4.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  trySubmit() async {
    Map<String, dynamic> userInfoMap = {
      "email": myEmail,
      "imageUrl": url,
      "name": name.text,
      "username": myUserName,
    };
    if (name.text == "" || name.text.length < 4) {
      _showMyDialog();
    } else {
      setState(() {
        submit = true;
      });
      SharedPreferenceHelper().saveDisplayName(name.text);
      SharedPreferenceHelper().saveUserProfileUrl(url);

      DatabaseMethods().updateUserDetails(myUserId!, userInfoMap).then((value) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Home()));
      });
    }
  }

  @override
  void initState() {
    doThisOnLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[900],
          title: Text("Settings"),
        ),
        body: submit == false
            ? Column(
                children: [
                  Container(
                      padding: EdgeInsets.only(top: 30),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            url != null ? NetworkImage(url!) : null,
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlatButton.icon(
                        textColor: Colors.green[600],
                        onPressed: _pickImageC,
                        icon: Icon(Icons.camera),
                        label: Text('Take Picture'),
                      ),
                      FlatButton.icon(
                        textColor: Colors.green[600],
                        onPressed: _pickImageG,
                        icon: Icon(Icons.image),
                        label: Text('From Gallary'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 18),
                        child: Text(
                          "Name",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                              fontWeight: FontWeight.w400),
                        ),
                      )
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Container(
                      padding: EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: name,
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Display Name",
                          hintStyle: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  RaisedButton(
                    onPressed: trySubmit,
                    elevation: 10,
                    color: Colors.purple,
                    child: Text(
                      "Submit",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              )
            : Center(child: CircularProgressIndicator()));
  }
}
