import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/file_picker.dart';
import 'package:smart_crc_gf/crc/crc_list.dart';
import 'dart:convert';

import 'package:smart_crc_gf/main.dart';
import 'package:share_extend/share_extend.dart';



class CRCStack extends StatefulWidget {

  const CRCStack({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CRCStackState();
}

class CRCStackState extends State<CRCStack> {
  var index = 0;
  List<List<Widget>> cardList = [];
  List<Widget> stacks = [];
  TextEditingController stackTitleController = TextEditingController();
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("CRC Stacks",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0)),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(icon: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.blue,), onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SmartCRC())
              );
            },),
                label: 'Back'),
            BottomNavigationBarItem(icon: IconButton(icon: const Icon(Icons.import_export, color: Colors.blue,), onPressed: () async {
              final result = await FilePicker.platform.pickFiles();

              if (result != null) {

                var existingStackSnapshot = await FirebaseFirestore.instance.collection('crc_stack').get();

                List stackList = existingStackSnapshot.docs;

                var seenStack =  [];
                for(DocumentSnapshot stack in stackList){
                  seenStack.add(stack.id);
                }


                File f = File(result.files.single.path);

                final data = await json.decode(f.readAsStringSync());

                if(!seenStack.contains(data['name'])){
                  FirebaseFirestore.instance.collection('crc_stack').doc(data['name']).set({
                    "test": "test",
                  });

                  var seenCrc =  [];
                  var importedCollabDicts = [];
                  for(var card in data['cards']){
                    FirebaseFirestore.instance.collection('crc_stack').doc(data['name']).collection('${data['name']}_docs').add({
                      "class_name": card['className'],
                      "description": card['description'],
                      "responsibilities": card['responsibilities'],
                      "collaborators" : card['collaborators'][0] as Map,
                      "notes" : card['notes'],
                    });
                    seenCrc.add(card['className']);
                    importedCollabDicts.add(card['collaborators'][0] as Map);
                  }





                  var addCRC = [];
                  for(var importedCollaborators in importedCollabDicts){
                    importedCollaborators.forEach((key, value) {
                      for(var collaborator in value){
                        if(!seenCrc.contains(collaborator)){
                          addCRC.add(collaborator);
                        }
                      }
                    });
                  }

                  var seen = [];
                  for(var add in addCRC){
                    if(!seen.contains(add)){
                      FirebaseFirestore.instance.collection('crc_stack').doc(data['name'])
                          .collection('${data['name']}_docs').add(
                          {
                            "class_name": add,
                            "description": '',
                            "responsibilities": [],
                            "collaborators": {'-1': ['lol']},
                            "notes": '',

                          })
                          .then((value) {});
                      seen.add(add);
                    }
                  }
                }
                else{
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                    content: Text('Stack Already Exists'),
                  ));
                }



                Navigator.of(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CRCStack())
                );


              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                  content: Text('No File Selected'),
                ));

              }
            },), label: 'Import Stack'),
            BottomNavigationBarItem(icon: IconButton(icon: const  Icon(Icons.add, color: Colors.blue,), onPressed: () {
              _addStack();
              index++;
            },), label: 'Add Stack'),
          ],
        ),
        body: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('crc_stack')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('Loading...');
              }
              return ListView.builder(
                itemCount: stacks.length,
                itemBuilder: (BuildContext context, int cardIndex) {
                  DocumentSnapshot crcStack = snapshot.data.docs[cardIndex];
                  return Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width,
                      height: MediaQuery
                          .of(context)
                          .size
                          .height / 3,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: InkWell(
                        child: Column(
                          children: <Widget> [
                            Text('${crcStack.id} Stack', style: const TextStyle(fontSize: 20),),
                            const SizedBox(height: 20),
                            stacks[cardIndex],
                          ],
                        ) ,
                        onTap: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CRCList(index, crcStack.id))
                          );
                        },
                        onLongPress: (){
                          _showStackSecondaryMenu(context, crcStack, snapshot, cardIndex);
                        },
                      )
                  );
                },
              );
            }
        )
    );
  }

  _deleteStack(BuildContext context, snapshot, cardIndex, crcStack) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext alertContext) {
          return AlertDialog(
              title: const Text("Delete Stack"),
              content: const Text(
                  "Are you sure you want to delete this stack?"),
              actions: [
                TextButton(child: const Text("Cancel"),
                  onPressed: () => {Navigator.of(alertContext).pop()},
                ),
                TextButton(child: const Text("Delete"),
                    onPressed: () async {
                      var documentSnaps = await FirebaseFirestore.instance.collection('crc_stack').doc(crcStack.id).collection('${crcStack.id}_docs').get();
                      List docs = documentSnaps.docs;

                      for(DocumentSnapshot doc in docs){
                        await FirebaseFirestore.instance.runTransaction((
                            Transaction myTransaction) async {
                          myTransaction.delete(doc.reference);
                        });
                      }

                      await FirebaseFirestore.instance.runTransaction((
                          Transaction myTransaction) async {
                        myTransaction.delete(snapshot.data.docs[cardIndex].reference);
                      });


                      stacks.removeAt(cardIndex);
                      cardList.removeAt(cardIndex);
                      Navigator.of(context).pop();
                      Navigator.of(alertContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                              content: Text("CRC Stack deleted")
                          )
                      );
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CRCStack())
                      );
                    }
                )
              ]
          );
        }
    );
  }

  _addStack(){
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext alertContext) {
          return AlertDialog(
              title: const Text("Add Stack"),
              content: const Text(
                  "Please enter the name of your new CRC Card Stack"),
              actions: [
                TextFormField(
                  controller: stackTitleController,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget> [
                    TextButton(child: const Text("Cancel"),
                    onPressed: () => {Navigator.of(alertContext).pop()},
                   ),
                    TextButton(child: const Text("Add"),
                        onPressed: () async {
                          FirebaseFirestore.instance.collection('crc_stack').doc(stackTitleController.value.text).set({
                            "test": "test",
                          });
                          Navigator.of(context);
                          Navigator.of(alertContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                  content: Text("CRC Card Stack ${stackTitleController.value.text} created")
                              )
                          );
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CRCList(index, stackTitleController.value.text))
                          );
                        }
                    )],
                ),
              ]
          );
        }
    );
  }

  _buildStack() async {
    stacks.clear();
    cardList.clear();
    
    var stackSnapshot = await FirebaseFirestore.instance.collection('crc_stack').get();

    List stackList = stackSnapshot.docs;

    var i = 0;
    for(var stack in stackList) {
      stacks.add(null);
      var crcCollectionSnapshot = await FirebaseFirestore.instance.collection(
          'crc_stack').doc(stack.id).collection('${stack.id}_docs').get();

      List crcCardList = crcCollectionSnapshot.docs;

      if(crcCardList.isEmpty) {
        cardList.add(
            List<Card>.filled(1, Card(
                shadowColor: Colors.black,
                child: SizedBox(
                  width: 500,
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget> [Text('${stack.id} Stack', textAlign: TextAlign.center, style: const TextStyle(fontSize: 30)),],) ),
                )
            , growable: true));
      }
      else{
        cardList.add(List<Card>.filled(crcCardList.length, const Card(), growable: true));
      }

      var j = 0;
      for (var crc in crcCardList) {
        var crcName = crc['class_name'] ?? '';
        var crcResponsibilities = crc['responsibilities'] ?? '';
        var crcCollaborators = crc['collaborators'] ?? '';
        var reducedCollaborators = [];
        List<dynamic> seen = [];
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
        cardList[i][j] = Card(
            shadowColor: Colors.black,
            child: Stack(
                children: <Widget>[
                  SizedBox(
                    child: Column(
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(
                              top: 25),
                          alignment: Alignment.center,
                          child: Text(crcName,
                            style: const TextStyle(
                                fontSize: 20),),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment
                              .center,
                          children: <Widget>[
                            Container(
                              margin: const EdgeInsets.only(
                                  left: 20, bottom: 30),
                              child: Column(
                                children: <Widget>[
                                  const Text(
                                      "Responsibilities:",
                                      style: TextStyle(
                                          fontSize: 15)
                                  ),
                                  for(var response in crcResponsibilities)
                                    Text(response,
                                        style: const TextStyle(
                                            fontSize: 15)
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10,),
                            Container(
                              margin: const EdgeInsets.only(
                                  right: 20, bottom: 30),
                              child: Column(
                                children: <Widget>[
                                  const Text(
                                      "Collaborators:",
                                      style: TextStyle(
                                          fontSize: 15)
                                  ),
                                  for(var collaborator in reducedCollaborators)
                                    Text(collaborator,
                                        style: const TextStyle(
                                            fontSize: 15)
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]
            )
        );
        j++;
      }
      stacks[i] = CarouselSlider(
        options: CarouselOptions(
          // autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 1.7,
          // scrollDirection: Axis.vertical,
        ),
        items: cardList[i],
      );
      i++;
    }
    setState(() {
      stacks;
      cardList;
    });
  }

  _showStackSecondaryMenu(BuildContext context, crcStack, snapshot, cardIndex) {
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
                        var cards = [];
                        var snap = await FirebaseFirestore.instance.collection('crc_stack').doc(crcStack.id).collection('${crcStack.id}_docs').get();

                        List cardList = snap.docs;

                        for(var card in cardList){
                          var cardString = '{\n "className" : "${card['class_name']}",\n "responsibilities" : ${card['responsibilities']}, \n "collaborators" : [${card['collaborators']}],\n "note" : "${card['notes']}", \n "description" : "${card['description']}" \n }';
                          cards.add(cardString);
                        }
                        var jsonToWrite = '{\n''"name" : "${crcStack.id}",\n''"cards" : ${cards.toString()} \n }';
              
                        _write(jsonToWrite, crcStack.id);
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
                    ListTile(
                      onTap:() async {
                        var cards = [];
                        var snap = await FirebaseFirestore.instance.collection('crc_stack').doc(crcStack.id).collection('${crcStack.id}_docs').get();

                        List cardList = snap.docs;

                        for(var card in cardList){
                          var cardString = '{\n "className" : "${card['class_name']}",\n "responsibilities" : ${card['responsibilities']}, \n "collaborators" : [${card['collaborators']}],\n "note" : "${card['notes']}", \n "description" : "${card['description']}" \n }';
                          cards.add(cardString);
                        }
                        var jsonToWrite = '{\n''"name" : "${crcStack.id}",\n''"cards" : ${cards.toString()} \n }';

                        _writeForShare(jsonToWrite, crcStack.id);

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 5),
                          content: Text('Shared File!'),
                        ));
                      },
                      leading: const Icon(Icons.share),
                      title: Text('Share ${crcStack.id}')
                    ),
                    ListTile(
                      onTap: () => _deleteStack(context, snapshot, cardIndex, crcStack),
                      leading: const Icon(Icons.delete, color: Colors.red,),
                      title: Text('Delete ${crcStack.id}')
                    ),
                  ],
                );
              },
            ),
          );
        }
    );
  }

  _write(String text, stackName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/$stackName.json');
    await file.writeAsString(text);

  }

  _writeForShare(String text, stackName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/$stackName.json');
    await file.writeAsString(text);

    ShareExtend.share(file.path, "file");
  }


  @override
  void initState() {
    super.initState();
    stacks.clear();
    cardList.clear();
    setState(() {
      _buildStack();
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose(){
    setState(() {
      stackTitleController.clear();
      stacks.clear();
      cardList.clear();
    });
    super.dispose();
  }

}