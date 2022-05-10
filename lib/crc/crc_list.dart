import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:smart_crc_gf/crc/crc_entries.dart';
import 'package:smart_crc_gf/crc/crc_stack.dart';
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
          automaticallyImplyLeading: false,
          title: Text( widget.stackName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20.0)),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(icon: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.blue,), onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CRCStack()),
              );
            },), label: 'Back'),
            BottomNavigationBarItem(icon: IconButton(icon: const Icon(Icons.auto_awesome_motion,color: Colors.blue,), onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const CRCStack()),
              // );
              print('lol');
            },), label: 'Study Mode'),
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
    var crcResponsibilities = crc['responsibilities'] ?? '';
    var crcCollaborators = crc['collaborators'] ?? '';
    var reducedCollaborators = [];
    var seen = [];

    var collaborators = crcCollaborators as Map;
    collaborators.forEach((key, value) {
      for(var val in value){
        if(!seen.contains(val)){
          var add = val ?? '';
          reducedCollaborators.add(add);
          seen.add(val);
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
                            for(var response in crcResponsibilities)
                              Text(response, style: const TextStyle(
                                  fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 100,),
                      Container(
                        margin: const EdgeInsets.only(right: 20, bottom: 30),
                        // width: MediaQuery
                        //     .of(context)
                        //     .size
                        //     .width/2.6,
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


  @override
  void initState(){
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}