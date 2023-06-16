import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../model/video_model.dart';

class AddVideoScreen extends StatefulWidget {
  @override
  _AddVideoScreenState createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  File? _selectedVideo;
  String _videoDuration = '';

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _selectedVideo = File(result.files.single.path!);
        _videoDuration = '';
      });
    }
  }

  Future<void> _saveVideo() async {
    if (_selectedVideo != null) {
      final appDirectory = await getApplicationDocumentsDirectory();
      final videosFolder = Directory('${appDirectory.path}/videos');
      if (!await videosFolder.exists()) {
        await videosFolder.create(recursive: true);
      }

      final savedVideo = await _selectedVideo!
          .copy('${videosFolder.path}/${_selectedVideo!.path.split('/').last}');
      if (savedVideo != null) {
        final duration = await getVideoDuration(savedVideo);
        setState(() {
          _videoDuration = duration;
        });

        // Handle successful video save
        Video video = Video(
          title: savedVideo.path.split('/').last,
          size: getFileSize(savedVideo),
          duration: _videoDuration,
          thumbnail: await getVideoThumbnail(savedVideo),
          videoPath: savedVideo.path,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Video added success!"),
          backgroundColor: Color(0xffe8794b),
        ));
        Navigator.pop(
          context,
          video,
        ); // Pass the video object back to HomeScreen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Something went wrong!"),
          backgroundColor: Color(0xffe8794b),
        ));
      }
    } else {
      // No video selected
    }
  }

  String getFileSize(File file) {
    final fileSize = file.statSync().size;
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

  Future<String> getVideoDuration(File videoFile) async {
    final videoPlayerController = VideoPlayerController.file(videoFile);
    await videoPlayerController.initialize();

    final duration = videoPlayerController.value.duration;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final durationString = '$minutes:${seconds.toString().padLeft(2, '0')}';

    videoPlayerController.dispose();

    return durationString;
  }

  Future<String> getVideoThumbnail(File file) async {
    final thumbnailPath = '${file.path}_thumbnail.jpg';

    await VideoThumbnail.thumbnailFile(
      video: file.path,
      thumbnailPath: thumbnailPath,
      imageFormat: ImageFormat.JPEG,
      quality: 100,
      maxWidth: 100,
      maxHeight: 100,
      timeMs: 0,
    );

    return thumbnailPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Video',
          style: TextStyle(color: Color(0xff2554f4), fontSize: 20),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              color: Colors.white.withOpacity(0.1),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedVideo != null)
                      Text(
                        _selectedVideo!.path.split("/").last,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    //if (_videoDuration.isNotEmpty) Text(_videoDuration),
                  ],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.016),
            ElevatedButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith(
                      (states) => const Color(0xff2554f4)),
                  backgroundColor: MaterialStateProperty.resolveWith(
                      (states) => const Color(0xffe8794b))),
              onPressed: _pickVideo,
              child: const Text('Choose Video'),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.016),
            ElevatedButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith(
                      (states) => const Color(0xff2554f4)),
                  backgroundColor: MaterialStateProperty.resolveWith(
                      (states) => const Color(0xffe8794b))),
              onPressed: _saveVideo,
              child: const Text('Save Video'),
            ),
          ],
        ),
      ),
    );
  }
}
