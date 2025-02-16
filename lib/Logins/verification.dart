// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:QuickMessenger/Logins/logreg.dart';
import 'package:QuickMessenger/Ui/elvb.dart';

import '../HomeScreens/home.dart';

class Verification extends StatefulWidget {
  const Verification({super.key});

  @override
  State<Verification> createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  final _auth = FirebaseAuth.instance;
  bool resend = false;
  Timer? timer;
  bool isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

  @override
  void initState() {
    super.initState();
    sendEmailVerification();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) => checkUserVerified());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  sendEmailVerification() {
    Timer(
      const Duration(seconds: 1),
      () {
        _auth.currentUser?.sendEmailVerification();
      },
    );
  }

  checkUserVerified() async {
    await _auth.currentUser?.reload();
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });
    if (isEmailVerified) {
      timer!.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
          // The page to navigate to
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(2.0, 1.0);
            const end = Offset.zero;
            var tween = Tween(begin: begin, end: end);
            final offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        ),
        (Route<dynamic> route) => false, // This removes all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              if (!isEmailVerified) {
                _auth.signOut();
                _auth.currentUser!.delete();
              }
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios)),
        title: const Text(
          "Verification",
          style: TextStyle(fontSize: 25, color: Colors.blue),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
              "A Verification Link Send To Your Gmail Verify It.",
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              !resend
                  ? Elvb(
                      textsize: 17.0,
                      heigth: 50.0,
                      width: 150.0,
                      onpressed: () {
                        _auth.currentUser!.sendEmailVerification();
                        setState(() {
                          resend = true;
                        });
                        Timer(
                          const Duration(seconds: 5),
                          () {
                            setState(() {
                              resend = false;
                            });
                          },
                        );
                      },
                      name: "Resend",
                      foregroundcolor: Colors.white,
                      backgroundcolor: Colors.blue)
                  : const Center(
                      child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 5,
                      ),
                    )),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  fixedSize: const Size(150, 50),
                ),
                onPressed: () {
                  _auth.signOut();
                  _auth.currentUser!.delete();
                  Navigator.pushReplacement(
                      context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => LogReg(),
                      // The page to navigate to
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(2.0, 1.0);
                        const end = Offset.zero;
                        var tween = Tween(begin: begin, end: end);
                        final offsetAnimation = animation.drive(tween);
                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.blue, fontSize: 17),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
