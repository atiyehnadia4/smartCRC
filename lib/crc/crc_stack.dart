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
  List<List<Widget>> cardLists = [];
  List<String> stackList = [];
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
        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _addStack();
              index++;
            }
        ),
        body: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('crc_stack')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text('Loading...');
              return ListView.builder(
                itemCount: cardLists.length,
                itemBuilder: (BuildContext context, int cardIndex) {
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
                      child: Slidable(
                          actionPane: const SlidableScrollActionPane(),
                          actionExtentRatio: .25,
                          secondaryActions: [
                            IconSlideAction(
                                caption: "Delete",
                                color: Colors.red,
                                icon: Icons.delete,
                                onTap: () =>
                                    _deleteStack(context, snapshot, cardIndex)
                            )
                          ],
                          child: InkWell(
                            child: CarouselSlider(
                              options: CarouselOptions(
                                  autoPlay: true,
                                  enlargeCenterPage: true,
                                  aspectRatio: 1.7,
                                  scrollDirection: Axis.vertical,
                              ),
                              items: cardLists[cardIndex],
                            ),

                            onLongPress: (){
                              _showStackSecondaryMenu(context, snapshot);
                            },
                          )
                      )
                  );
                },
              );
            }
        )
    );
  }

  _deleteStack(BuildContext context, snapshot, index) {
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
                      snapshot.
                      snapshot.data.doc('stack$index').delete();
                      // await FirebaseFirestore.instance.runTransaction((
                      //     Transaction myTransaction) async {
                      //   myTransaction.delete(
                      //     snapshot.data.doc()
                      //       snapshot.data.docs[index].reference);
                      // });

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

  _showStackSecondaryMenu(BuildContext context, snapshot) {
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
                      onTap: () => _deleteStack(context, snapshot, index),
                      leading: const Icon(Icons.delete, color: Colors.red,),
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
      //populate();
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
      cardLists.clear();
      stackList.clear();
    });

    super.dispose();
  }

  populate(){
    FirebaseFirestore.instance.collection('crc_stack').get().then(
            (snapshot){
          snapshot.docs.forEach((element) {
            setState(() {
              stackList.add(element.id);
            });
          });
        }
    );
    for(var stack in stackList){
      List<Widget> cardList = [];
      FirebaseFirestore.instance.collection('crc_stack').doc(stack).collection('${stack}_docs').get().then(
              (snapshot) {
            snapshot.docs.forEach((crc) {
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
              setState(() {
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
              });

            });
          }
      );
      setState(() {
        cardLists.add(cardList);
      });

    }
  }
}