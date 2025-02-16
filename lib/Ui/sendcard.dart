import 'package:flutter/material.dart';

class Sendcard extends StatelessWidget {
  const Sendcard({
    super.key,
    this.message,
    this.time,
    this.messageState,
  });

  // ignore: prefer_typing_uninitialized_variables
  final messageState;

  // ignore: prefer_typing_uninitialized_variables
  final message;

  // ignore: prefer_typing_uninitialized_variables
  final time;

  // List<Color> messageState = [Colors.red, Colors.yellow, Colors.greenAccent];

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.topRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 50,
          ),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.black26),
                borderRadius: BorderRadius.only(
                    topRight: Radius.zero,
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30))),
            color: Colors.blue,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 15, right: 90, top: 5, bottom: 5),
                  child: Text(
                    message,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                Positioned(
                    bottom: 1,
                    right: 30,
                    child: Text(
                      time,
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    )),

                Positioned(
                  bottom: 5,
                  right: 20,
                  child: SizedBox(
                    height: 7,
                    width: 7,
                    child: CircleAvatar(
                      backgroundColor: messageState == "send"
                          ? Colors.yellow
                          : Colors.black54,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 10,
                  child: SizedBox(
                    height: 7,
                    width: 7,
                    child: CircleAvatar(
                      backgroundColor: messageState == "seen"
                          ? Colors.greenAccent
                          : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
