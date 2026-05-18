import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final noteController = TextEditingController();

  Future addNote() async {
    if (noteController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('notes').add({
      'note': noteController.text,
      'time': DateTime.now(),
    });

    noteController.clear();
  }

  Future updateNote(String docId, String oldNote) async {
    final editController = TextEditingController(text: oldNote);

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Note'),

          content: TextField(controller: editController),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('notes')
                    .doc(docId)
                    .update({'note': editController.text});

                Navigator.pop(context);
              },

              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Notes')),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Enter note',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: addNote, child: const Text('Add Note')),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('notes')
                    .orderBy('time', descending: true)
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,

                    itemBuilder: (context, index) {
                      final note = docs[index]['note'];

                      return Card(
                        child: ListTile(
                          title: Text(note),

                          leading: IconButton(
                            icon: const Icon(Icons.edit),

                            onPressed: () {
                              updateNote(docs[index].id, note);
                            },
                          ),

                          trailing: IconButton(
                            icon: const Icon(Icons.delete),

                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('notes')
                                  .doc(docs[index].id)
                                  .delete();
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
