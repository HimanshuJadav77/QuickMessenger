import 'package:flutter/material.dart';

class SendMedia extends StatelessWidget {
  const SendMedia({
    super.key,
    this.messageState,
    this.time,
    this.fileImage,
    this.iconData,
    this.filename,
    this.fileType,
  });

  // ignore: prefer_typing_uninitialized_variables
  final fileType;

  // ignore: prefer_typing_uninitialized_variables
  final messageState;

  // ignore: prefer_typing_uninitialized_variables
  final filename;

  // ignore: prefer_typing_uninitialized_variables
  final time;

  // ignore: prefer_typing_uninitialized_variables
  final fileImage;

  // ignore: prefer_typing_uninitialized_variables
  final iconData;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 100,
          maxHeight: MediaQuery.of(context).size.width - 100,
        ),
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.blue.shade700),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          color: Colors.blue.shade400,
          child: Stack(
            children: [
              fileImage != null && fileType == "Image"
                  ? Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(child: CircularProgressIndicator());
                          },
                          fileImage,
                          height: Image.file(fileImage).height,
                          width: Image.file(fileImage).width,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20)),
                      height: 70,
                      width: 230,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: Icon(
                            iconData,
                            size: 30,
                            color: Colors.blue,
                          ),
                          title: Text(
                            filename,
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                    ),
              Positioned(
                  bottom: 2,
                  right: 35,
                  child: Text(
                    time,
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  )),
              Positioned(
                bottom: 7,
                right: 25,
                child: SizedBox(
                  height: 7,
                  width: 7,
                  child: CircleAvatar(
                    backgroundColor:
                        messageState == "send" ? Colors.yellow : Colors.black54,
                  ),
                ),
              ),
              Positioned(
                bottom: 7,
                right: 15,
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
      ),
    );
  }
}
