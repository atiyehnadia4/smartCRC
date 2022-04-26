import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:smart_crc_gf/crc/crc_list.dart';

class CRCStack extends StatefulWidget {

  const CRCStack({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CRCStackState();
}

class CRCStackState extends State<CRCStack> {
  var index = 0;
  List<Widget> cardList = [];
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
              Navigator.pop(context);
            },), label: 'Back'),
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
              if (!snapshot.hasData) return const Text('Loading...');
              return ListView.builder(
                itemCount: snapshot.data.docs.length,
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
                        child: _buildStack(crcStack, context),
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

  _deleteStack(BuildContext context, snapshot, cardIndex) {
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
                      await FirebaseFirestore.instance.runTransaction((Transaction myTransaction) async {
                        myTransaction.delete(snapshot.data.docs[cardIndex].reference);
                      });
                      Navigator.of(context);
                      Navigator.of(alertContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                              content: Text("CRC Stack deleted")
                          )
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

  _buildStack(stackCRC, context) {
    var stackName = stackCRC.id;
    FirebaseFirestore.instance.collection('crc_stack').doc(stackName)
        .collection('${stackName}_docs').get()
        .then(
            (snapshot) {
          for (var crc in snapshot.docs) {
            var crcName = crc['class_name'] ?? '';
            var crcResponsibilities = crc['responsibilities'] ?? '';
            var crcCollaborators = crc['collaborators'] ?? '';
            var reducedCollaborators = [];
            List<dynamic> seen = [];
            for (var collaborator in crcCollaborators) {
              if (!seen.contains(collaborator)) {
                var add = collaborator ?? '';
                reducedCollaborators.add(add);
                seen.add(collaborator);
              }
            }
            cardList.add(
                Card(
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
                )
            );
          }
        });

    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 1.7,
        // scrollDirection: Axis.vertical,
      ),
      items: cardList,
    );
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
                      onTap: () {},
                      leading: const Icon(Icons.ios_share),
                      title: const Text('Share'),
                    ),
                    ListTile(
                      onTap: () => _deleteStack(context, snapshot, cardIndex),
                      leading: const Icon(Icons.delete, color: Colors.red,),
                      title: Text('Delete ${crcStack.id}')
                    )
                  ],
                );
              },
            ),
          );
        }
    );
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      // populate();
      // print(cardLists);
      // print(stackList);
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
    });
    super.dispose();
  }
}