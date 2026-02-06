import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/entity/attachment.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import '../entity/movie.dart';
import '../database/database_helper.dart';
import '../models/movie_model.dart';
import 'package:path/path.dart' as p;

class ConfigureMovieScreen extends StatefulWidget {
  final int? movieId;

  const ConfigureMovieScreen({super.key, this.movieId});

  @override
  State<ConfigureMovieScreen> createState() => ConfigureMovieScreenState();
}

class ConfigureMovieScreenState extends State<ConfigureMovieScreen> {
  final __formKey = GlobalKey<FormState>();
  final __titleController = TextEditingController();
  final __yearController = TextEditingController();
  final __genreController = TextEditingController();
  final __linkController = TextEditingController();
  String? __filePath;
  String? __currentAddress;
  int __selectedType = 1;
  final DatabaseHelper __dbHelper = DatabaseHelper.instance;
  bool __isLoading = false;
  List<Attachment> __initialAttachments = [];
  List<Attachment> __insertedAttachments = [];
  List<int> __deletedAttachmentsIds = [];

  final __location = Location();

  @override
  void initState() {
    super.initState();

    if (widget.movieId != null) {
      __loadMovie();
    }
  }

  @override
  void dispose() {
    __titleController.dispose();
    __yearController.dispose();
    __genreController.dispose();
    __linkController.dispose();
    super.dispose();
  }

  Future<void> __loadMovie() async {
    setState(() {
      __isLoading = true;
    });

    if (widget.movieId != null) {
      MovieModel? movieModel = await __dbHelper.getMovieModel(widget.movieId!);
      var attachments = await __dbHelper.getAttachments(widget.movieId!, null);

      setState(() {
        __titleController.text = movieModel?.title ?? '';
        __yearController.text = movieModel?.yearPublished?.toString() ?? '2025';
        __genreController.text = movieModel?.genres.join(", ") ?? '';
        __isLoading = false;
        __initialAttachments = attachments;
      });
    }
  }

  Future<void> __saveMovie() async {
    if (!__formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      __isLoading = true;
    });

    try {
      //obtaining parameters
      final title = __titleController.text.trim();
      final year = __yearController.text.trim().isEmpty
          ? null
          : int.tryParse(__yearController.text.trim());
      final genres = __genreController.text.trim().isEmpty
          ? []
          : __genreController.text
                .trim()
                .split(",")
                .map((element) => element.trim())
                .toList();
      final movie = Movie(
        id: widget.movieId,
        title: title,
        yearPublished: year,
      );

      //Inserting/editing movie
      int movieID;
      if (widget.movieId == null) {
        movieID = await __dbHelper.insertMovie(movie);
      } else {
        await __dbHelper.updateMovie(movie);
        movieID = widget.movieId!;
      }

      //Appending genres
      for (var genre in genres) {
        await __dbHelper.appendGenreToMovie(movieID, genre);
      }

      //Appending attachments
      for (var attachmentToDelete in __deletedAttachmentsIds) {
        await __dbHelper.deleteAttachment(attachmentToDelete);
      }

      for (var attachmentToInsert in __insertedAttachments) {
        attachmentToInsert.movieId = movieID;
        await __dbHelper.insertAttachment(attachmentToInsert);
      }

      //other stuff
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.movieId == null ? 'Movie added' : 'Movie edited',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          __isLoading = false;
        });
      }
    }
  }

  Future<void> __addAttachment() async {
    final linkText = __linkController.text.trim();
    if ((linkText.isEmpty && __filePath == null) ||
        ![1, 2, 3].contains(__selectedType)) {
      return;
    }

    if (__filePath != null) {
      String sourceName = p.basename(__filePath!);
      Directory assetsDir = await getApplicationDocumentsDirectory();
      File sourceFile = File(__filePath!);
      try {
        File newFile = await sourceFile.copy("${assetsDir.path}\\$sourceName");
        setState(() {
          __filePath = newFile.path;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            __isLoading = false;
          });
        }
      }
    }

    final attachment = Attachment(
      attachmentType: __selectedType,
      link: __filePath == null ? linkText : null,
      path: __filePath,
      movieId: widget.movieId ?? -1,
      addressAdded: __currentAddress
    );
    setState(() {
      __insertedAttachments.add(attachment);
      __initialAttachments.add(attachment);
      __filePath = null;
    });
  }

  Future<void> __pickFile(int attachmentType) async {
    FilePickerResult? res = await FilePicker.platform.pickFiles(
      type: attachmentType == 1
          ? FileType.image
          : (attachmentType == 2 ? FileType.audio : FileType.video),
      allowMultiple: false,
    );

    if (res != null) {
      setState(() {
        __filePath = res.files.first.path;
      });
    }
  }

  Future<void> __updateLocation() async {
    if ((await __location.serviceEnabled())) {
      var curLoc = await __location.getLocation();
      __currentAddress = "lat: ${curLoc.latitude}; lon: ${curLoc.longitude}";
    } else {
      PermissionStatus status = await __location.requestPermission();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ошибка: Разрешение на доступ к геолокации не выдано',
              ),
            ),
          );
        }
      } else {
        var curLoc = await __location.getLocation();
        __currentAddress = "lat: ${curLoc.latitude}; lon: ${curLoc.longitude}";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.movieId == null ? 'Add' : 'Edit')),
      body: __isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: __formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: __titleController,
                      decoration: const InputDecoration(
                        labelText: 'Movie name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.movie),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter title of the movie';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Год
                    TextFormField(
                      controller: __yearController,
                      decoration: const InputDecoration(
                        labelText: 'Date published',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final year = int.tryParse(value.trim());
                          if (year == null) {
                            return 'Enter correct data';
                          }
                          if (year < 0 || year > DateTime.now().year + 1) {
                            return 'Data cannnot be less than 0 or greater than current year';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: __genreController,
                      decoration: const InputDecoration(
                        labelText: 'Genres',
                        hintText: 'Enter genres seprated with \', \'',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.theater_comedy_rounded),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          flex: 3,
                          child: DropdownButton(
                            hint: Text("Select attachment type"),
                            items: [
                              DropdownMenuItem(value: 1, child: Text("Image")),
                              DropdownMenuItem(value: 2, child: Text("Audio")),
                              DropdownMenuItem(value: 3, child: Text("Video")),
                            ],
                            onChanged: (int? selectedType) {
                              setState(() {
                                __selectedType = selectedType ?? 0;
                              });
                            },
                          ),
                        ),
                        Flexible(
                          flex: 6,
                          child: __filePath == null
                              ? TextFormField(
                                  controller: __linkController,
                                  decoration: const InputDecoration(
                                    labelText: 'Link',
                                    hintText: 'Enter resource link \', \'',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.theater_comedy_rounded,
                                    ),
                                  ),
                                )
                              : Text(__filePath!),
                        ),

                        Flexible(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: __addAttachment,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: () {
                              if (__filePath == null) {
                                __pickFile(__selectedType);
                              } else {
                                setState(() {
                                  __filePath = null;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              __filePath == null ? "Add file" : "Cancel file",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: () {
                              __updateLocation();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              "Update location",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (__initialAttachments.isNotEmpty)
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
                              child: ListTile(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(attachment.link ?? attachment.path!),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          __initialAttachments.remove(
                                            attachment,
                                          );
                                          if (attachment.id == null) {
                                            __insertedAttachments.remove(
                                              attachment,
                                            );
                                          } else {
                                            __deletedAttachmentsIds.add(
                                              attachment.id!,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: __saveMovie,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
