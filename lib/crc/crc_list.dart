import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_crc_gf/crc/crc_entries.dart';
import 'package:smart_crc_gf/crc/crc_stack.dart';
import 'package:smart_crc_gf/crc/crc_study_mode.dart';
import 'crc_existing_entry.dart';

class CRCList extends StatefulWidget {
  final int index;
  final String stackName;
  const CRCList(this.index, this.stackName, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CRCListState();
}

class CRCListState extends State<CRCList> {

  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white,), onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CRCStack()),
            );
          },),
          title: Text('${widget.stackName} Stack',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20.0)),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(icon: IconButton(icon: const Icon(Icons.auto_awesome_motion,color: Colors.blue,), onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CRCStudy(widget.stackName)),
              );
            },), label: 'Study Mode'),
            BottomNavigationBarItem(icon: IconButton(icon: const Icon(Icons.import_export, color: Colors.blue,), onPressed: () async {
              final result = await FilePicker.platform.pickFiles();

              if (result != null) {
                var existingCardSnapshot = await FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName).collection('${widget.stackName}_docs')
                    .get();

                List crcCardList = existingCardSnapshot.docs;
                var seenCrc =  [];
                for(var crc in crcCardList){
                  seenCrc.add(crc['class_name'] ?? '');
                }

                File f = File(result.files.single.path);
                final data = await json.decode(f.readAsStringSync());

                if(!seenCrc.contains(data['className'])){
                  FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName).collection('${widget.stackName}_docs').add({
                    "class_name": data['className'],
                    "description": data['description'],
                    "responsibilities": data['responsibilities'],
                    "collaborators" : data['collaborators'][0] as Map,
                    "notes" : data['notes'],
                  });
                  var importedCollaborators = data['collaborators'][0] as Map;

                  var addCRC = [];
                  importedCollaborators.forEach((key, value) {
                    for(var collaborator in value){
                      if(!seenCrc.contains(collaborator)){
                        addCRC.add(collaborator);
                      }
                    }
                  });


                  for(var add in addCRC){
                    FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName)
                        .collection('${widget.stackName}_docs').add(
                        {
                          "class_name": add,
                          "description": '',
                          "responsibilities": [],
                          "collaborators": {'-1': ['lol']},
                          "notes": '',

                        })
                        .then((value) {});
                  }
                }
                else{
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                    content: Text('CRC Card Already Exists'),
                  ));
                }



                Navigator.of(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CRCList(widget.index, widget.stackName)));


              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                  content: Text('No File Selected'),
                ));

              }
            },), label: 'Import Card'),
            BottomNavigationBarItem(icon: IconButton(icon: const  Icon(Icons.add, color: Colors.blue,), onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CRCEntryNew(widget.index, widget.stackName)),
              );
            },), label: 'Add Card'),
          ],
        ),
        body: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName).collection('${widget.stackName}_docs')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text('Loading...');
              if(snapshot.data.docs.length == 0){
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const <Widget> [
                    Text('Press the Add Card Button to add a card to your stack!', style: TextStyle(fontSize: 20), textAlign: TextAlign.center,),
                    SizedBox(height: 10,),
                    Text('Press the Back Button to view your other stacks!', style: TextStyle(fontSize: 20, color: Colors.red), textAlign: TextAlign.center,),
                    SizedBox(height: 10,),
                    Text('Press the Study Mode Button to study the cards in your stack!', style: TextStyle(fontSize: 20), textAlign: TextAlign.center,),
                  ],
                );
              }
              return ListView.builder(
                itemCount: snapshot.data.docs.length,
                itemBuilder: (BuildContext context, int index) {
                  DocumentSnapshot crc = snapshot.data.docs[index];
                  var uid = crc.id;
                  return Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Slidable(
                        actionPane: const SlidableScrollActionPane(),
                        actionExtentRatio: .25,
                        secondaryActions: [
                          IconSlideAction(
                              caption: "Delete",
                              color: Colors.red,
                              icon: Icons.delete,
                              onTap: () =>
                                  _deleteCRC(context, crc, snapshot, index)
                          )
                        ],
                        child: Card(
                            elevation: 8,
                            child: IntrinsicHeight(
                              child: InkWell(
                                child: _buildFrontCard(crc, context),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CRCEntryExisting(
                                                index: index, uid: uid, stackIndex: widget.index, stackName: widget.stackName,),)
                                  );
                                },
                                onLongPress: (){
                                  _showStackSecondaryMenu(index);
                                },
                              ),
                            )
                        ),
                      )
                  );
                },
              );
            }
        )
    );
  }

  _showStackSecondaryMenu(index) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: BottomSheet(
              onClosing: () {},
              builder: (context) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      onTap: () async {
                        var snap = await FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName).collection('${widget.stackName}_docs').get();

                        List cardList = snap.docs;
                        var card = cardList[index];
                        var cardString = '{\n "className" : "${card['class_name']}",\n "responsibilities" : ${card['responsibilities']}, \n "collaborators" : [${card['collaborators']}],\n "note" : "${card['notes']}", \n "description" : "${card['description']}" \n }';

                        _write(cardString, card['class_name']);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 5),
                          content: Text('Exported File!'),
                        ));
                      },
                      leading: const Icon(Icons.import_export),
                      title: const Text('Export'),
                    ),
                  ],
                );
              },
            ),
          );
        }
    );
  }

  _deleteCRC(BuildContext context, DocumentSnapshot crc,
      snapshot, index) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext alertContext) {
          return AlertDialog(
              title: const Text("Delete CRC"),
              content: Text(
                  "Are you sure you want to delete ${crc['class_name']}?"),
              actions: [
                TextButton(child: const Text("Cancel"),
                  onPressed: () => {Navigator.of(alertContext).pop()},
                ),
                TextButton(child: const Text("Delete"),
                    onPressed: () async {
                      await FirebaseFirestore.instance.runTransaction((
                          Transaction myTransaction) async {
                        myTransaction.delete(
                            snapshot.data.docs[index].reference);
                      });

                      Navigator.of(context);
                      Navigator.of(alertContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                              content: Text("CRCnCard deleted")
                          )
                      );
                    }
                )
              ]
          );
        }
    );
  }

  Stack _buildFrontCard(DocumentSnapshot crc, context) {
    // if(crc['test'] == 'test'){
    //   return Stack();
    // }
    var crcName = crc['class_name'] ?? '';
    var crcResponsibilities = crc['responsibilities'] ?? [];
    var crcCollaborators = crc['collaborators'] ?? {'-1' : ['']};
    var reducedCollaborators = [];
    var seen = [];

    var collaborators = crcCollaborators as Map;
    collaborators.forEach((key, value) {
      if(key != '-1') {
        for (var val in value) {
          if (!seen.contains(val)) {
            var add = val ?? '';
            reducedCollaborators.add(add);
            seen.add(val);
          }
        }
      }

    });
    return Stack(
        children: <Widget>[
          IntrinsicHeight(
            child: IntrinsicWidth(
              child: Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 25),
                    alignment: Alignment.center,
                    child: Text(crcName, style: const TextStyle(fontSize: 20),),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(left: 20, bottom: 30),
                        // width: MediaQuery
                        //     .of(context)
                        //     .size
                        //     .width/3,
                        child: Column(
                          children: <Widget>[
                            const Text("Responsibilities:", style: TextStyle(
                                fontSize: 15)),
                            if(crcResponsibilities.length != 0)
                              for(var response in crcResponsibilities)
                                Text(response, style: const TextStyle(
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 100,),
                      Container(
                        margin: const EdgeInsets.only(right: 20, bottom: 30),
                        child: Column(
                          children: <Widget>[
                            const Text("Collaborators:", style: TextStyle(
                                fontSize: 15)),
                            for(var collaborator in reducedCollaborators)
                                Text(collaborator, style: const TextStyle(
                                    fontSize: 15)),

                          ],
                        ),
                      ),
                    ],
                  ),
                ],),
            ),
          ),

        ]
    );
  }

  _write(String text, cardName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/${cardName}_${widget.stackName}.json');
    await file.writeAsString(text);
  }


  @override
  void initState(){
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}