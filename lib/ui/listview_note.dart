import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:rdbfirebase/model/note.dart';
import 'package:rdbfirebase/ui/note_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ListViewNote extends StatefulWidget {
  @override
  _ListViewNoteState createState() => new _ListViewNoteState();
}



class _ListViewNoteState extends State<ListViewNote> {

  List<Note> items;
  StreamSubscription<Event> _onNoteAddedSubscription;
  StreamSubscription<Event> _onNoteChangedSubscription;
  StreamSubscription<Event> _onNoteRemovedSubscription;

  @override
  void initState() {
    super.initState();

    items = new List();

    final FirebaseDatabase database = FirebaseDatabase.instance; 
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);  
    final notesReference = database.reference().child('notes');
    notesReference.keepSynced(true);

    _onNoteAddedSubscription = notesReference.onChildAdded.listen(_onNoteAdded);
    _onNoteChangedSubscription = notesReference.onChildChanged.listen(_onNoteUpdated);
    _onNoteRemovedSubscription = notesReference.onChildRemoved.listen(_onNoteRemoved);

  }

  @override
  void dispose() {
    _onNoteAddedSubscription.cancel();
    _onNoteChangedSubscription.cancel();
    _onNoteRemovedSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase database test',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Firebase offline test (pass / fail ?)'),
          centerTitle: true,
          backgroundColor: Colors.blue,
        ),

        body: Center(
          child: (items.length<1) ? loadingIndicator() : listViewBuilder()
        ),

        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () => _createNewNote(context),
        ),
      ),
    );
  }

  void _onNoteAdded(Event event) {
    setState(() {
      items.add(new Note.fromSnapshot(event.snapshot));
    });
  }

  void _onNoteUpdated(Event event) {
    var oldNoteValue = items.singleWhere((note) => note.id == event.snapshot.key);
    setState(() {
      items[items.indexOf(oldNoteValue)] = new Note.fromSnapshot(event.snapshot);
    });
  }


  void _onNoteRemoved(Event event){
    var oldNoteValue = items.singleWhere((note) => note.id == event.snapshot.key);
    setState(() {
      items.removeAt(items.indexOf(oldNoteValue));
    });
  }

  void _deleteNote(BuildContext context, Note note, int position) async {
    await notesReference.child(note.id).remove();
  }

  void _navigateToNote(BuildContext context, Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteScreen(note)),
    );
  }

  void _createNewNote(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteScreen(Note(null, '', ''))),
    );
  }


  //WIDGETS
  Widget loadingIndicator(){
    return  SpinKitWave(
      color: Colors.blue,
      size: 50.0,
      );
  }

  Widget listViewBuilder(){
    return ListView.builder(
            reverse: false,
              itemCount: items.length,
              padding: const EdgeInsets.all(15.0),
              itemBuilder: (context, position) {
                return Column(
                  children: <Widget>[
                    Divider(height: 5.0),
                    ListTile(
                      title: Text(
                        '${items[position].title}',
                        style: TextStyle(
                          fontSize: 22.0,
                          color: Colors.deepOrangeAccent,
                        ),
                      ),
                      subtitle: Text(
                        '${items[position].description}',
                        style: new TextStyle(
                          fontSize: 18.0,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      leading: Column(
                        children: <Widget>[
                          Padding(padding: EdgeInsets.all(10.0)),
                          CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            radius: 15.0,
                            child: Text(
                              '${position + 1}',
                              style: TextStyle(
                                fontSize: 22.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _deleteNote(context, items[position], position)),
                        ],
                      ),
                      onTap: () => _navigateToNote(context, items[position]),
                    ),
                  ],
                );
              });
  }



}
