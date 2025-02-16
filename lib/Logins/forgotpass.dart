// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:QuickMessenger/Logins/showdialogs.dart';
import 'package:QuickMessenger/Ui/snackbar.dart';

import '../Ui/elvb.dart';

class Forgotpass extends StatefulWidget {
  const Forgotpass({super.key});

  @override
  State<Forgotpass> createState() => _ForgotpassState();
}

class _ForgotpassState extends State<Forgotpass> {
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios)),
        title: const Text(
          "Forgot Password",
          style: TextStyle(fontSize: 22, color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 10,
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
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Elvb(
                textsize: 17.0,
                heigth: 50.0,
                onpressed: () async {
                  if (emailController.text != "") {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text);
                      showCustomDialog("Forgot Password", "We have been sent email on your mail check it.", context);
                      emailController.text = "";
                    } on FirebaseException catch (e) {
                      showSnackBar(context, "$e");
                    }
                  }
                },
                name: "Send",
                foregroundcolor: Colors.white,
                backgroundcolor: Colors.blue),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                "    If you forgot your password  enter your email in textbox \nand receive reset password mail in your mail app and reset it."),
          ),
        ],
      ),
    );
  }
}
