import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:messenger_clone/helperfunctions/sharedpref_helper.dart';
import 'package:messenger_clone/services/database.dart';
import 'package:messenger_clone/views/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn =
      GoogleSignIn(); //var to get the current user

  getCurrentUser() async {
    return await auth.currentUser;
  }

  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

    final GoogleSignInAccount? googleSignInAccount =
        await _googleSignIn.signIn();

    final GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount?.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication?.idToken,
        accessToken: googleSignInAuthentication?.accessToken);

    UserCredential result =
        await _firebaseAuth.signInWithCredential(credential);

    User? userDetails = result.user;
    var s = userDetails?.email;
    var x = s?.indexOf("@");
    var subs = s?.substring(x!);
    Map<String, dynamic> userInfoMap = {
      "email": userDetails?.email,
      "username": userDetails?.email?.replaceAll("$subs", ""),
      "name": userDetails?.displayName,
      "imageUrl": userDetails?.photoURL
    };

    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userDetails?.uid)
        .get();
    if (snapshot.exists) {
      QuerySnapshot querySnapshot = await DatabaseMethods()
          .getUserInfo(userDetails?.email?.replaceAll("$subs", ""));
      String? name = "${querySnapshot.docs[0]["name"]}";
      String? profilePicUrl = "${querySnapshot.docs[0]["imageUrl"]}";
      Map<String, dynamic> userInfoMap = {
        "email": userDetails?.email,
        "username": userDetails?.email?.replaceAll("$subs", ""),
        "name": name,
        "imageUrl": profilePicUrl,
      };
      SharedPreferenceHelper().saveUserEmail(userDetails?.email);
      SharedPreferenceHelper().saveUserId(userDetails?.uid);
      SharedPreferenceHelper()
          .saveUserName(userDetails?.email?.replaceAll("$subs", ""));
      SharedPreferenceHelper().saveDisplayName(name);
      SharedPreferenceHelper().saveUserProfileUrl(profilePicUrl);
      DatabaseMethods()
          .addUserInfoToDB(userDetails?.uid, userInfoMap)
          .then((value) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Home()));
      });
    } else {
      SharedPreferenceHelper().saveUserEmail(userDetails?.email);
      SharedPreferenceHelper().saveUserId(userDetails?.uid);
      SharedPreferenceHelper()
          .saveUserName(userDetails?.email?.replaceAll("$subs", ""));
      SharedPreferenceHelper().saveDisplayName(userDetails?.displayName);
      SharedPreferenceHelper().saveUserProfileUrl(userDetails?.photoURL);
      DatabaseMethods()
          .addUserInfoToDB(userDetails?.uid, userInfoMap)
          .then((value) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Home()));
      });
    }
  }

  Future signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    await auth.signOut();
    await _googleSignIn.signOut();
  }
}
