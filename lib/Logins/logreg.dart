import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:QuickMessenger/Logins/register.dart';
import 'package:QuickMessenger/Logins/showdialogs.dart';
import 'package:QuickMessenger/Ui/elvb.dart';
import 'package:QuickMessenger/networkcheck.dart';
import 'login.dart';

class LogReg extends StatefulWidget {
  const LogReg({super.key});

  @override
  State<LogReg> createState() => _LogRegState();
}

class _LogRegState extends State<LogReg> {


  @override
  void initState() {
    super.initState();
    requestPermissions();

    NetworkCheck().initializeInternetStatus(context);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    NetworkCheck().cancelSubscription();
  }

  requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
    if (await Permission.camera.isDenied || await Permission.storage.isDenied) {
      await Permission.camera.isGranted;
      await Permission.storage.isGranted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
            gradient: LinearGradient(tileMode: TileMode.decal, colors: [Colors.blueAccent, Colors.blueGrey]),
            color: Colors.blue),
        child: ListView(
          children: [
            const SizedBox(
              height: 100,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      "assets/images/logo.png",
                      height: 50,
                      width: 50,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text(
                    "QuickMessenger",
                    style: TextStyle(fontSize: 25, color: Colors.white, fontFamily: "karsyu"),
                  ),
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                textAlign: TextAlign.center,
                "QuickMessenger for Communicate with your friend and send messages to friends.",
                style: TextStyle(fontSize: 17, color: Colors.white),
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            SizedBox(
              height: 500,
              child: Stack(
                children: [
                  Positioned(
                    top: 340,
                    left: 0,
                    right: 0,
                    bottom: 90,
                    child: Builder(builder: (context) {
                      return Elvb(
                        textsize: 17.0,
                        backgroundcolor: Colors.blue.shade700,
                        foregroundcolor: Colors.white,
                        onpressed: () {
                          logregcontainer(const Register(), context);
                        },
                        name: "Register",
                      );
                    }),
                  ),
                  Positioned(
                    top: 410,
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: Builder(builder: (context) {
                      return Elvb(
                        textsize: 17.0,
                        onpressed: () {
                          logregcontainer(const Login(), context);
                        },
                        name: "Login",
                        foregroundcolor: Colors.blue,
                        backgroundcolor: Colors.white,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
