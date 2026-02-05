import 'package:flutter/material.dart';
import 'package:flutter_application_1/entity/attachment.dart';
import 'package:just_audio/just_audio.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import '../database/database_helper.dart';
import '../models/movie_model.dart';

class MovieInfoScreen extends StatefulWidget {
  final int movieId;

  const MovieInfoScreen({super.key, required this.movieId});

  @override
  State<MovieInfoScreen> createState() => MovieInfoScreenState();
}

class MovieInfoScreenState extends State<MovieInfoScreen> {
  final __formKey = GlobalKey<FormState>();
  MovieModel? __movieModel;
  List<Attachment> __initialAttachments = [];
  bool __isLoading = false;
  final DatabaseHelper __dbHelper = DatabaseHelper.instance;

  final AudioPlayer __audioPlayer = AudioPlayer();
  bool __isPlaying = false;

  VideoPlayerController? __videoController;
  int? __attachmentPlayed;
  double __sliderValueAudio = 0.0;
  double __durationValue = 0.0;

  double __sliderValueVideo = 0.0;

  @override
  void initState() {
    super.initState();
    __loadMovie();
    __audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          __durationValue = duration?.inMilliseconds.toDouble() ?? 0.0;
        });
      }
    });
    __audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          __sliderValueAudio = position.inMilliseconds.toDouble();
        });
      }
    });
  }

  @override
  void dispose() {
    __videoController?.dispose();
    __audioPlayer.dispose();
    super.dispose();
  }

  Future<void> __loadMovie() async {
    setState(() {
      __isLoading = true;
    });

    __movieModel = await __dbHelper.getMovieModel(widget.movieId);
    __initialAttachments = await __dbHelper.getAttachments(
      widget.movieId,
      null,
    );

    setState(() {
      __isLoading = false;
    });
  }

  void __togglePlayBack(
    int attachmentPlayed,
    int attachmentType,
    String link,
  ) async {
    if (__attachmentPlayed != attachmentPlayed) {
      __videoController?.removeListener(
        __updateSliderPositionWithVideoController,
      );
      __videoController?.dispose();
      __videoController = null;
      if (__audioPlayer.playing) {
        __audioPlayer.stop();
        __audioPlayer.seek(Duration.zero);
      }

      if (attachmentType == 2) {
        await __audioPlayer.setUrl(link);
        __audioPlayer.play();
        setState(() {
          __attachmentPlayed = attachmentPlayed;
          __isPlaying = true;
        });
      } else if (attachmentType == 3) {
        __videoController = VideoPlayerController.networkUrl(Uri.parse(link))
          ..initialize().then((_) {
            setState(() {
              __attachmentPlayed = attachmentPlayed;
              __videoController?.addListener(
                __updateSliderPositionWithVideoController,
              );
            });
          });
      }
    } else {
      if (attachmentType == 2) {
        if (__isPlaying) {
          __audioPlayer.stop();
        } else {
          __audioPlayer.play();
        }

        setState(() {
          __isPlaying = !__isPlaying;
        });
      } else if (attachmentType == 3) {
        setState(() {
          if (__videoController != null) {
            __videoController!.value.isPlaying
                ? __videoController!.pause()
                : __videoController!.play();
          }
        });
      }
    }
  }

  void __updateSliderPositionWithVideoController() {
    setState(() {
      __sliderValueVideo =
          __videoController?.value.position.inMilliseconds.toDouble() ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Info')),
      body: __isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: __formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(__movieModel?.title ?? "Title not found"),
                    const SizedBox(height: 16),
                    // Год
                    Text(
                      __movieModel?.yearPublished?.toString() ??
                          "Year not found",
                    ),
                    const SizedBox(height: 16),

                    Text(__movieModel?.genres.join(", ") ?? "Genres not found"),

                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: __initialAttachments.length,
                        itemBuilder: (context, index) {
                          final attachment = __initialAttachments[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.movie),
                                  ),
                                  title: Text(
                                    attachment.attachmentType == 1
                                        ? "Image "
                                        : (attachment.attachmentType == 2
                                                  ? "Audio "
                                                  : "Video ") +
                                              (attachment.id?.toString() ??
                                                  "pending"),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [Text(attachment.link)],
                                  ),
                                ),
                                if (attachment.attachmentType == 1)
                                  SizedBox(
                                    height: 64,
                                    width: 64,
                                    child: PhotoView(
                                      customSize: Size(64, 64),
                                      imageProvider: NetworkImage(
                                        attachment.link,
                                      ),
                                      minScale:
                                          PhotoViewComputedScale.contained *
                                          0.8,
                                      maxScale:
                                          PhotoViewComputedScale.covered * 2,
                                      enableRotation: true,
                                      heroAttributes: PhotoViewHeroAttributes(
                                        tag: "attachment${attachment.id!}",
                                      ),
                                    ),
                                  )
                                else if (attachment.attachmentType == 2)
                                  Row(
                                    children: [
                                      if (attachment.id == __attachmentPlayed)
                                        Slider(
                                          min: 0.0,
                                          max: __durationValue,
                                          value: __sliderValueAudio,
                                          onChanged: (newValue) {
                                            setState(() {
                                              __sliderValueAudio = newValue;
                                            });
                                            __audioPlayer.seek(
                                              Duration(
                                                milliseconds: __sliderValueAudio
                                                    .round(),
                                              ),
                                            );
                                          },
                                        ),
                                      ElevatedButton(
                                        onPressed: () {
                                          __togglePlayBack(
                                            attachment.id!,
                                            attachment.attachmentType,
                                            attachment.link,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                        child: Icon(Icons.play_arrow),
                                      ),
                                    ],
                                  )
                                else if (attachment.attachmentType == 3)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (attachment.id == __attachmentPlayed)
                                        (__videoController
                                                    ?.value
                                                    .isInitialized ??
                                                false)
                                            ? AspectRatio(
                                                aspectRatio: __videoController!
                                                    .value
                                                    .aspectRatio,
                                                child: VideoPlayer(
                                                  __videoController!,
                                                ),
                                              )
                                            : Container(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          if (attachment.id ==
                                              __attachmentPlayed)
                                            Slider(
                                              min: 0.0,
                                              max:
                                                  __videoController
                                                      ?.value
                                                      .duration
                                                      .inMilliseconds
                                                      .toDouble() ??
                                                  0.0,
                                              value: __sliderValueVideo,
                                              onChanged: (newValue) {
                                                __videoController?.seekTo(
                                                  Duration(
                                                    milliseconds: newValue
                                                        .toInt(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ElevatedButton(
                                            onPressed: () {
                                              __togglePlayBack(
                                                attachment.id!,
                                                attachment.attachmentType,
                                                attachment.link,
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                            ),
                                            child: Icon(Icons.play_arrow),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
