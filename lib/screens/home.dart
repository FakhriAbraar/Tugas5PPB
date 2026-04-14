import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final titleTextController = TextEditingController();
  final contentTextController = TextEditingController();
  int selectedColor = Colors.white.value;
  final FirestoreService firestoreService = FirestoreService();
  final List<Color> labelColors = [
    Colors.white,
    Colors.red[100]!,
    Colors.blue[100]!,
    Colors.green[100]!,
    Colors.yellow[100]!,
    Colors.orange[100]!,
  ];

  void openNoteBox({String? docId, String? existingTitle, String? existingNote, int? existingColor}) async {
    if (docId != null) {
      titleTextController.text = existingTitle ?? '';
      contentTextController.text = existingNote ?? '';
      selectedColor = existingColor ?? Colors.white.value;
    } else {
      titleTextController.clear();
      contentTextController.clear();
      selectedColor = Colors.white.value;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(docId == null ? "Create new Note" : "Edit Note"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(labelText: "Title"),
                        controller: titleTextController,
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: "Content"),
                        controller: contentTextController,
                      ),
                      const SizedBox(height: 20),
                      const Text("Pilih Warna:"),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: labelColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() => selectedColor = color.value);
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color.value ? Colors.black : Colors.grey,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  MaterialButton(
                    onPressed: () {

                      String currentDate = "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}";

                      if (docId == null) {
                        firestoreService.addNote(
                          titleTextController.text,
                          contentTextController.text,
                          currentDate,
                          selectedColor,
                        );
                      } else {
                        firestoreService.updateNote(
                          docId,
                          titleTextController.text,
                          contentTextController.text,
                          currentDate,
                          selectedColor,
                        );
                      }
                      Navigator.pop(context);
                    },
                    child: Text(docId == null ? "Create" : "Update"),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void logout(context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openNoteBox(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getNotes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List notesList = snapshot.data!.docs;

            if (notesList.isEmpty) {
              return const Center(child: Text("Belum ada catatan."));
            }

            // MENGUBAH LISTVIEW MENJADI GRIDVIEW
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 kolom
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9, // Mengatur proporsi kotak
              ),
              itemCount: notesList.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = notesList[index];
                String docId = document.id;

                Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                String noteTitle = data['title'] ?? '';
                String noteContent = data['content'] ?? '';
                String noteDate = data['date'] ?? '';
                int noteColor = data['color'] ?? Colors.white.value;

                return Card(
                  color: Color(noteColor), // Menampilkan warna label
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          noteTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          noteDate,
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            noteContent,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => openNoteBox(
                                  docId: docId,
                                  existingNote: noteContent,
                                  existingTitle: noteTitle,
                                  existingColor: noteColor
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => firestoreService.deleteNote(docId),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}