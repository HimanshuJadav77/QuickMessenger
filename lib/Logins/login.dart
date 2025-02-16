import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:QuickMessenger/HomeScreens/home.dart';
import 'package:QuickMessenger/Logins/forgotpass.dart';
import 'package:QuickMessenger/Logins/register.dart';
import 'package:QuickMessenger/Logins/showdialogs.dart';
import 'package:QuickMessenger/networkcheck.dart';
import '../Ui/elvb.dart';
import '../Ui/snackbar.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool pass = false;
  bool cpass = false;
  bool loggedin = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    NetworkCheck().initializeInternetStatus(context);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    NetworkCheck().cancelSubscription();
  }

  login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (FirebaseAuth.instance.currentUser!.emailVerified) {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
            // The page to navigate to
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.1, 0.0);
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
        setState(() {
          loggedin = false;
        });
      } else {
        FirebaseAuth.instance.currentUser!.sendEmailVerification();
        FirebaseAuth.instance.signOut();
        // ignore: use_build_context_synchronously
        showCustomDialog("Login", "Your email is not verified We send email on your mail please verify it.", context);
        setState(() {
          loggedin = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        loggedin = false;
      });
      // ignore: use_build_context_synchronously
      showSnackBar(context, "$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Login",
                style: TextStyle(fontSize: 35, fontFamily: "karsyu", fontWeight: FontWeight.w400, color: Colors.black),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Divider(
              color: Colors.black,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            height: 300,
            width: 300,
            child: Image.asset("assets/images/login.png"),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: emailController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                  label: const Text("Enter Email"),
                  prefixIcon: const Icon(Icons.mail_outline),
                  focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue), borderRadius: BorderRadius.circular(30)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: passController,
              obscureText: !pass,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                  label: const Text("Enter Password"),
                  suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          pass = !pass;
                        });
                      },
                      icon: Icon(pass ? Icons.visibility_outlined : Icons.visibility_off_outlined)),
                  prefixIcon: const Icon(Icons.password_outlined),
                  focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue), borderRadius: BorderRadius.circular(30)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => Forgotpass(),
                  // The page to navigate to
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(3.0, 1.0);
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
            child: Padding(
              padding: const EdgeInsets.only(left: 275.0),
              child: Text(
                "Forgot Password?",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
          loggedin
              ? const Center(
                  child: SizedBox(
                    height: 25,
                    width: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  ),
                )
              : Elvb(
                  textsize: 17.0,
                  heigth: 50.0,
                  onpressed: () {
                    if (emailController.text != "" && passController.text != "") {
                      login(emailController.text, passController.text);
                      setState(() {
                        loggedin = true;
                      });
                    } else {
                      showSnackBar(context, "Please Fill All TextBoxes.");
                    }
                  },
                  name: "Login",
                  foregroundcolor: Colors.white,
                  backgroundcolor: Colors.blue),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "I have no any Account?",
                style: TextStyle(fontSize: 17),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    logregcontainer(const Register(), context);
                  },
                  child: const Text("Register", style: TextStyle(fontSize: 18, color: Colors.blue)))
            ],
          )
        ],
      ),
    );
  }
}
