
// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:QuickMessenger/Ui/snackbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class Receivemedia extends StatefulWidget {
  const Receivemedia({
    super.key,
    this.time,
    this.iconData,
    this.filename,
    this.fileType,
    this.fileurl,
    this.senderId,
    required this.file,
  });

  // ignore: prefer_typing_uninitialized_variables
  final File file;

  // ignore: prefer_typing_uninitialized_variables
  final senderId;

  // ignore: prefer_typing_uninitialized_variables
  final fileType;

  // ignore: prefer_typing_uninitialized_variables
  final filename;

  // ignore: prefer_typing_uninitialized_variables
  final time;

  // ignore: prefer_typing_uninitialized_variables
  final iconData;

  // ignore: prefer_typing_uninitialized_variables
  final fileurl;

  @override
  State<Receivemedia> createState() => _ReceivemediaState();
}

class _ReceivemediaState extends State<Receivemedia> {
  bool isDownloading = false;
  bool isDownloaded = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    checkFileExist();
  }

  download(savePath) {
    setState(() {
      isDownloading = true;
    });
    try {
      Dio dio = Dio();
      dio.download(
        widget.fileurl,
        savePath,
        onReceiveProgress: (received, total) async {
          final progress = (received / total) * 100;

          setState(() {
            _progress = progress;
          });

          if (progress == 100.0) {
            setState(() {
              isDownloaded = true;
              isDownloading = false;
            });
          }
        },
      );
    } catch (e) {
      showSnackBar(context, "$e");
    }
  }

  checkFileExist() async {
    String filepath = '/storage/emulated/0/Download/QuickMessenger/Files/${widget.filename}';
    bool exist = false;

    exist = await File(filepath).exists();
    if (exist == true) {
      setState(() {
        isDownloaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inkwell = GlobalKey();
    Directory filepath = Directory('/storage/emulated/0/Download/QuickMessenger/Files/${widget.filename}');

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 100,
            maxHeight: MediaQuery.of(context).size.width - 100,
          ),
          child: InkWell(
            key: inkwell,
            onTap: () {
              if (isDownloaded) {
                final renderbox = inkwell.currentContext?.findRenderObject() as RenderBox;
                final position = renderbox.localToGlobal(Offset.zero);
                showMenu(
                  color: Colors.white,
                  elevation: 10,
                  shadowColor: Colors.black54,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  context: context,
                  position:
                      RelativeRect.fromLTRB(position.dx + 200, position.dy + 30, position.dx + 400, position.dy + 100),
                  items: [
                    PopupMenuItem<String>(
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 20,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          const Text('Open'),
                        ],
                      ),
                      onTap: () async {
                        Directory filepath =
                            Directory('/storage/emulated/0/Download/QuickMessenger/Files/${widget.filename}');

                        if (widget.fileType == "Compressed File") {
                          showSnackBar(context, "Go to Downloads In App folder for Compressed Files.");
                        }

                        if (!await File(filepath.path).exists()) {
                          showSnackBar(context, "File is not found or deleted.");
                        } else if (await File(filepath.path).exists()) {
                          await OpenFile.open(
                            filepath.path,
                          );
                        }
                      },
                    ),
                  ],
                );
              }
            },
            child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black26),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    widget.fileType == "Image" && widget.file.existsSync() && !isDownloading
                        ? Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(child: CircularProgressIndicator());
                                },
                                File(filepath.path),
                                height: Image.file(File(filepath.path)).height,
                                width: Image.file(File(filepath.path)).width,
                              ),
                            ),
                          )
                        : widget.fileType == "Image" && !widget.file.existsSync() ||
                                widget.fileType != "Image" && widget.file.existsSync() ||
                                !widget.file.existsSync()
                            ? Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 8.0,
                                    ),
                                    child: Container(
                                      decoration:
                                          BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(20)),
                                      height: 70,
                                      width: 230,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ListTile(
                                          leading: Icon(
                                            widget.iconData,
                                            size: 30,
                                            color: Colors.black,
                                          ),
                                          title: Text(
                                            widget.filename,
                                            style: TextStyle(color: Colors.black),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                      bottom: 2,
                                      right: 15,
                                      child: Text(
                                        widget.time,
                                        style: TextStyle(fontSize: 12, color: Colors.black),
                                      )),
                                  _progress != 0.0 && _progress != 100.0 && isDownloading
                                      ? Positioned(
                                          right: 25,
                                          bottom: 25,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                value: _progress / 100,
                                              ),
                                              Text("${_progress.toStringAsFixed(0)}%")
                                            ],
                                          ),
                                        )
                                      : Positioned(
                                          top: 10,
                                          right: 15,
                                          child: IconButton.outlined(
                                              onPressed: () {
                                                if (!File(filepath.path).existsSync()) {
                                                  download(filepath.path);
                                                }
                                              },
                                              icon: Icon(isDownloaded ? Icons.download_done_outlined : Icons.download)),
                                        ),
                                ],
                              )
                            : Center(),
                  ],
                )),
          )),
    );
  }
}
