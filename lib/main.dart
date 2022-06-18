import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/services/auth.dart';
import 'package:messenger_clone/views/home.dart';
import 'package:messenger_clone/views/signin.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Future<FirebaseApp> _initialization = Firebase.initializeApp();
    return FutureBuilder(
        // Initialize FlutterFire:
        future: _initialization,
        builder: (context, appSnapshot) {
          return MaterialApp(
            title: 'Flutter Demo',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: appSnapshot.connectionState != ConnectionState.done
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : FutureBuilder(
                    future: AuthMethods().getCurrentUser(),
                    builder: (context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasData) {
                        return SplashScrren(1);
                      } else {
                        return SplashScrren(2);
                      }
                    },
                  ),
          );
        });
  }
}

class SplashScrren extends StatefulWidget {
  final int? val;
  SplashScrren(this.val);
  @override
  _SplashScrrenState createState() => _SplashScrrenState();
}

class _SplashScrrenState extends State<SplashScrren> {
  @override
  void initState() {
    super.initState();
    Timer(
        Duration(
          milliseconds: 800,
        ), () {
      Navigator.pop(context);
      if (widget.val == 1) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => Home()));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => SignIn()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Container(
            child: new Image(
                image: new AssetImage('assets/images/WhatsApp_Logo_4.png')),
          ),
        ],
      ),
    );
  }
}
