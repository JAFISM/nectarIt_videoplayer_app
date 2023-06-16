import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nectarit_videoplayer_app/screen/playerScreen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../model/video_model.dart';
import 'add_video_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Video> videoCollections = [];

  @override
  void initState() {
    super.initState();
    loadVideosFromLocalStorage();
  }

  Future<void> loadVideosFromLocalStorage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final videos = await Future.wait(result.files.map((file) async {
        final videoPath = file.path!;
        final thumbnailPath = await getVideoThumbnail(videoPath);
        final duration = await getVideoDuration(videoPath);
        return Video(
            title: file.name,
            size: getFileSize(file.size),
            duration: duration,
            thumbnail: thumbnailPath,
            videoPath: videoPath);
      }));

      setState(() {
        videoCollections = videos;
      });
    }
  }

  String getFileSize(int fileSize) {
    final KB = fileSize / 1024;
    final MB = KB / 1024;
    final GB = MB / 1024;
    if (GB >= 1) {
      return '${GB.toStringAsFixed(2)} GB';
    } else if (MB >= 1) {
      return '${MB.toStringAsFixed(2)} MB';
    } else {
      return '${KB.toStringAsFixed(2)} KB';
    }
  }

  Future<String> getVideoDuration(String videoPath) async {
    final videoPlayerController = VideoPlayerController.file(File(videoPath));
    await videoPlayerController.initialize();

    final duration = videoPlayerController.value.duration;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final durationString = '$minutes:${seconds.toString().padLeft(2, '0')}';

    videoPlayerController.dispose();

    return durationString;
  }

  Future<String> getVideoThumbnail(String videoPath) async {
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 200,
      maxWidth: 200,
      quality: 75,
    );
    return thumbnailPath ?? 'assets/thumbnails/fallback_thumbnail.jpg';
  }

  void addVideo(Video video) {
    setState(() {
      videoCollections.add(video);
    });
  }

  Future<void> navigateToAddVideoScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddVideoScreen()),
    );

    if (result != null && result is Video) {
      addVideo(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xff2554f4),
          child: Icon(
            CupertinoIcons.play_rectangle_fill,
            size: 25,
            color: Color(0xffe8794b),
          ),
        ),
        title: const Text.rich(
          TextSpan(
              text: "Nec",
              style: TextStyle(color: Color(0xff2554f4), fontSize: 25),
              children: [
                TextSpan(
                  text: "Tar",
                  style: TextStyle(color: Color(0xffe8794b), fontSize: 25),
                )
              ]),
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        margin: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.015),
        child: ListView.builder(
          itemCount: videoCollections.length,
          itemBuilder: (context, index) {
            final video = videoCollections[index];
            return Container(
              margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.02,
                  vertical: MediaQuery.of(context).size.height * 0.015),
              child: ListTile(
                tileColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                leading: Container(
                    height: 150,
                    width: 56,
                    color: Colors.red,
                    child: Image.file(
                      File(video.thumbnail),
                      fit: BoxFit.fill,
                    )),
                title: Text(video.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Size: ${video.size}'),
                    Text('Duration: ${video.duration}'),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                            videoPath: video.videoPath,
                          )));
                },
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xffe8794b),
        onPressed: navigateToAddVideoScreen,
        child: const Icon(
          Icons.playlist_add,
          color: Color(0xff2554f4),
          size: 35,
        ),
      ),
    );
  }
}
