import 'package:flutter/material.dart';

class Elvb extends StatelessWidget {
  const Elvb(
      {super.key,
      required this.onpressed,
      required this.name,
      required this.foregroundcolor,
      required this.backgroundcolor,
      this.heigth,
      this.width,
      this.textsize});

  final VoidCallback onpressed;
  final String name;
  final Color foregroundcolor;
  final Color backgroundcolor;
  // ignore: prefer_typing_uninitialized_variables
  final heigth;
  // ignore: prefer_typing_uninitialized_variables
  final width;
  // ignore: prefer_typing_uninitialized_variables
  final textsize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: heigth == 0 ? 50 : heigth,
        width: width == 0 ? double.maxFinite : width,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundcolor,
              foregroundColor: foregroundcolor,
              elevation: 8,
              shadowColor: Colors.blueAccent,
            ),
            onPressed: onpressed,
            child: Text(
              name,
              style: TextStyle(fontSize: textsize),
            )),
      ),
    );
  }
}
