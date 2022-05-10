import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flip_card/flip_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_crc_gf/model/drop_down_existing.dart';
import 'crc_list.dart';


class CRCEntryExisting extends StatefulWidget{
  final int stackIndex;
  final int index;
  final String uid;
  final String stackName;

  CRCEntryExisting({Key key, this.index, this.uid, this.stackIndex, this.stackName}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CRCEntryExistingState();
}

class CRCEntryExistingState extends State<CRCEntryExisting> with TickerProviderStateMixin  {
  AnimationController controller;
  var index = 0;
  var responsibilityTECs = <TextEditingController>[];
  var responsibilityTextFormFields = <Column>[];
  List<Widget> collaboratorEntries = [];
  static List<List<String>> collaboratorData = [[]];
  var uid = '';
  final TextEditingController _titleEditingController = TextEditingController();
  final TextEditingController _descriptionEditingController = TextEditingController();
  final TextEditingController _notesEditingController = TextEditingController();
  final TextEditingController _newCardEditingController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  crcExistingEntries() {}

  @override
  Widget build(BuildContext context) {
    index = widget.index;
    uid = widget.uid;
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName).collection('${widget.stackName}_docs')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator(
              value: controller.value,
            );
          };
          DocumentSnapshot crc = snapshot.data.docs[index];
          return Scaffold(
              bottomNavigationBar: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 10),
                  child: _buildControlButtons(context, crc)
              ),
              body: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(
                          height: 100.0,
                        ),
                        const Text("Edit CRC Card",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20.0)),
                        const SizedBox(
                          height: 15.0,
                        ),
                        Container(
                          margin: const EdgeInsets.all(25),
                          child: _buildCardTile(context, crc),
                        ),
                      ],
                    ),
                  )
              )
          );
        }
    );
  }

  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  _buildCardTile(context, DocumentSnapshot crc) {
    return FlipCard(
      front: _buildFrontCard(context, crc),
      back: _buildBackCard(context, crc),
    );
  }

  _buildFrontCard(context, crc){
    return Card(
      child: Container(
        margin: const EdgeInsets.all(20),
        width: MediaQuery
            .of(context)
            .size
            .width,
        height: MediaQuery
            .of(context)
            .size
            .height,
        child: ListView(
          children: [
            const Align(
              child: Icon(Icons.rotate_right),
              alignment: Alignment.topLeft,
            ),
            const Align(
              child: Text("Title", textAlign: TextAlign.center),
              alignment: Alignment.topCenter,
            ),
            const SizedBox(height: 10),
            TextFormField(
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 25),
              decoration: const InputDecoration(hintText: 'Title'),
              controller: _titleEditingController,
              validator: (String value) {
                if (value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  responsibilityTextFormFields.add(
                      createResponsibilityForm());
                  List<String> newValue;
                  var currCard = crc['class_name'];
                  collaboratorEntries.add(DropDownExisting(newValue, responsibilityTextFormFields.length - 1, currCard , widget.stackName));
                  collaboratorData.add(null);
                }
                );
              }
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    const Text(
                        "Responsibilities", textAlign: TextAlign.center),
                    _buildResponsibilityContainer(context, crc),
                  ],
                ),
                const SizedBox(width: 15),
                Column(
                  children: <Widget>[
                    const Text("Collaborators", textAlign: TextAlign.center),
                    SizedBox(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height / 1.4,
                      width: MediaQuery
                          .of(context)
                          .size
                          .width * .30,
                      child: _buildCollaboratorsContainer(context, crc),
                    )
                  ],
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  _buildResponsibilityContainer(context, crc){
    return SizedBox(
        height: MediaQuery
            .of(context)
            .size
            .height/ 1.5,
        width: MediaQuery
            .of(context)
            .size
            .width * .30,
        child: Column(
          children: <Widget>[
            Expanded(
              child:
              ListView.builder(
                itemCount: responsibilityTextFormFields
                    .length,
                itemBuilder: (BuildContext context,
                    int index) {
                  return Slidable(
                    actionPane: const SlidableScrollActionPane(),
                    actionExtentRatio: .25,
                    secondaryActions: [
                      IconSlideAction(
                          caption: "Delete",
                          color: Colors.red,
                          icon: Icons.delete,
                          onTap: () =>
                          {
                            setState((){
                              responsibilityTextFormFields.removeAt(
                                  index);
                              responsibilityTECs.removeAt(index);
                              collaboratorEntries.removeAt(index);
                              collaboratorData.removeAt(index);
                              _updateList('r', crc);
                              Navigator.of(context);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                  const SnackBar(
                                      backgroundColor: Colors.red,
                                      duration: Duration(
                                          seconds: 2),
                                      content: Text(
                                          "Responsibility Deleted")
                                  )
                              );
                            }),
                          }
                      ),
                    ],child: responsibilityTextFormFields[index],
                  );
                },
              ),
            ),
          ],
        )
    );
  }

  _buildBackCard(context, crc){
    return Card(
      child: Container(
        margin: const EdgeInsets.all(20),
        width: MediaQuery
            .of(context)
            .size
            .width,
        height: MediaQuery
            .of(context)
            .size
            .height,
        child: ListView(
          children: [
            const Align(
              child: Icon(Icons.rotate_right),
              alignment: Alignment.topLeft,
            ),
            const Align(
              child: Text("Title", textAlign: TextAlign.center,),
              alignment: Alignment.topCenter,
            ),
            TextFormField(
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25),
              decoration: const InputDecoration(hintText: 'Title'),
              controller: _titleEditingController,
              validator: (String value) {
                if (value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(
              height: 30,
            ),
            const Text('Description'),
            TextFormField(
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: const InputDecoration(hintText: 'Description'),
              controller: _descriptionEditingController,
              validator: (String value) {
                if (value.isEmpty) {
                  return 'Please enter description for the Class';
                }
                return null;
              },
            ),
            const SizedBox(
              height: 10,
            ),
            const Text('Notes'),
            TextFormField(
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: const InputDecoration(hintText: 'Notes'),
              controller: _notesEditingController,
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  _buildCollaboratorsContainer(context, snapshot , [bool scrollable = false]) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: MediaQuery
              .of(context)
              .size
              .height/ 1.5,
          width: MediaQuery
              .of(context)
              .size
              .width * .30,
          child: Column(
            children: [
              Expanded(
                  child: ListView.separated(
                    itemCount: collaboratorEntries.length,
                    itemBuilder: (context, index) =>
                        collaboratorEntries.elementAt(index),
                    separatorBuilder: (context, index) =>
                    const SizedBox(height: 10,),
                    padding: const EdgeInsets.all(8),
                  )
              )
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        )
      ],
    );
  }

  _buildControlButtons(BuildContext context, DocumentSnapshot crc) {
    return Row(children: [
      TextButton(
        child: const Text('Cancel'),
        onPressed: () {
          FocusScope.of(context).requestFocus(FocusNode());
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CRCList(widget.stackIndex, widget.stackName)),
          );
        },
      ),
      const Spacer(),
      TextButton(
        child: const Text('Save'),
        onPressed: () {
          _save(context, crc);
        },
      ),
      const Spacer(),
      TextButton(
        child: const Text('Add Collaborator'),
        onPressed: () {
          _addCard();
        },
      ),
      // const Spacer(),
      // TextButton(
      //   child: const Text('Check'),
      //   onPressed: () {
      //     print(collaboratorData);
      //   },
      // ),
    ]);
  }

  _save(BuildContext context, DocumentSnapshot crc) async {
    if (!_formKey.currentState.validate()) {
      return;
    }

    var responsibilities = _onDone();
    var collaborators = _onDoneCollaborators();
    var notes = _notesEditingController.value.text ?? '';
    FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName).collection('${widget.stackName}_docs').doc(uid).update(
        {
          "class_name": _titleEditingController.value.text,
          "description": _descriptionEditingController.value.text,
          "responsibilities": responsibilities,
          "collaborators" : collaborators,
          "notes" : notes,

        }).then((value){
      print('success');
    });

    Navigator.pop(context);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: Colors.green,
      duration: Duration(seconds: 4),
      content: Text('CRC Card saved'),
    ));

    collaboratorData.clear();
  }

  _updateList(type, crc){
    if(type == 'r'){
      var response = _onDone();
      FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName).collection('${widget.stackName}_docs').doc(uid).update(
          {
            "responsibilities": response,
            "collaborators": collaboratorData
          }).then((value){
        print('success');
      });

    }
  }

  _onDone() {
    List<String> entries = [];
    for (int i = 0; i < responsibilityTextFormFields.length; i++) {
      var responsibility = responsibilityTECs[i].text;
      entries.add(responsibility);
    }
    return entries;
  }

  _onDoneCollaborators(){
    Map<String, List<String>> collabDict = {};
    var i = 0;
    for(var list in collaboratorData){
      if(list != null){
        var intString = i.toString();
        collabDict[intString] = list;
      }
      i++;
    }
    return collabDict;
  }

  createResponsibilityForm() {
    var responseController = TextEditingController();
    responsibilityTECs.add(responseController);
    return Column(
      children: <Widget>[
        TextFormField(
          maxLines: null,
          controller: responseController,
          validator: (String value) {
            if (value.isEmpty) {
              return 'Please enter a responsibility';
            }
            return null;
          },
          decoration: InputDecoration(

              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 2),
                child: Text('${responsibilityTextFormFields.length + 1}.'),
              )
          ),
        ),
      ],
    );
  }

  createExistingForm(TextEditingController tec){
    return Column(
      children: <Widget>[
        TextFormField(
          maxLines: null,
          controller: tec,
          validator: (String value) {
            if (value.isEmpty) {
              return 'Please enter a responsibility';
            }
            return null;
          },
          decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 2),
                child: Text('${responsibilityTextFormFields.length + 1}.'),
              )
          ),
        ),
      ],
    );
  }

  _addCard(){
    _newCardEditingController.clear();
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext alertContext) {
          return AlertDialog(
              title: const Text("Add Stack"),
              content: const Text(
                  "Please enter the name of your new CRC Card"),
              actions: [
                TextFormField(
                  controller: _newCardEditingController,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget> [
                    TextButton(child: const Text("Cancel"),
                      onPressed: () => {Navigator.of(alertContext).pop()},
                    ),
                    TextButton(child: const Text("Add"),
                        onPressed: () async {
                          FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName)
                              .collection('${widget.stackName}_docs').add(
                              {
                                "class_name": _newCardEditingController.value.text,
                                "description": '',
                                "responsibilities": [],
                                "collaborators": {'-1': ['lol']},
                                "notes": '',

                              })
                              .then((value) {});
                          Navigator.of(alertContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                  content: Text("CRC Card ${_newCardEditingController.value.text} created")
                              )
                          );
                        }
                    )],
                ),
              ]
          );
        }
    );
  }

  @override
  void initState(){
    super.initState();
    setState(() {
      collaboratorData.clear();
      populate();
    });
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
      setState(() {});
    });
    controller.repeat(reverse: true);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose(){
    controller.dispose();
    setState(() {
      collaboratorData.clear();
      collaboratorEntries.clear();
    });
    super.dispose();
  }

  populate() async{
    DocumentSnapshot crc = await FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName).collection('${widget.stackName}_docs').doc(widget.uid).get();
    for (var response in crc['responsibilities']) {
      var responseController = TextEditingController();
      responseController.text = response;
      setState(() {
        responsibilityTECs.add(responseController);
        var responseCol = createExistingForm(responseController);
        responsibilityTextFormFields.add(responseCol);
      });
    }

    var currCard = crc['class_name'];
    var collaborators = crc['collaborators'] as Map;
    collaborators.forEach((key, collaborator) {
      print(collaborator);
      List<String> collaboratorList = [];
      setState(() {
        if(key != '-1') {
          for (var collab in collaborator) {
            collaboratorList.add(collab.toString());
          }
          collaboratorEntries.add(DropDownExisting(collaboratorList, int.parse(key), currCard, widget.stackName));
          collaboratorData.add(collaboratorList);
        }
      });
    });

    _titleEditingController.text = crc['class_name'];
    _descriptionEditingController.text = crc['description'];
    _notesEditingController.text = crc['notes'] ?? '';

  }

}