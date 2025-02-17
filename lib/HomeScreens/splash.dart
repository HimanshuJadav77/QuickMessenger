import 'dart:async';

import 'package:flutter/material.dart';
import 'package:QuickMessenger/Logins/logreg.dart';

import 'home.dart';

class Splash extends StatefulWidget {
  const Splash({super.key, this.snapshot});

  // ignore: prefer_typing_uninitialized_variables
  final snapshot;

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    checkUser();
  }

  void checkUser() {
    Timer(
      const Duration(seconds: 3),
      () {
        if (widget.snapshot.hasData) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LogReg(),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: Image.asset(
              "assets/images/logo.png",
            ),
          ),
          const Text(
            "QuickMessenger",
            style: TextStyle(color: Colors.black, fontFamily: "karsyu", fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }
}
