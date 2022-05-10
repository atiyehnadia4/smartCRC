import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../model/drop_down.dart';
import 'crc_list.dart';
import 'package:flip_card/flip_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CRCEntryNew extends StatefulWidget {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  final int i;
  final String stackName;

  CRCEntryNew(this.i, this.stackName, {Key key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CRCEntryNewState();
}

class CRCEntryNewState extends State<CRCEntryNew> with TickerProviderStateMixin {
  AnimationController controller;
  List<TextEditingController> responsibilityTECs = [];
  List<Column> responsibilityTextFormFields = [];
  List<Widget> collaboratorEntries = [];
  static List<List<String>> collaboratorData = [[]];
  TextEditingController _titleEditingController = TextEditingController();
  TextEditingController _descriptionEditingController = TextEditingController();
  TextEditingController _notesEditingController = TextEditingController();
  TextEditingController _newCardEditingController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  crcEntries() {
    _titleEditingController.addListener(() {});
    _descriptionEditingController.addListener(() {});
    _notesEditingController.addListener(() { });
  }

  @override
  Widget build(BuildContext context) {
    _titleEditingController = widget._title;
    _descriptionEditingController = widget._description;
    _notesEditingController = widget._notes;
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('crc_stack')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator(
            value: controller.value,
           );
          };
          return Scaffold(
              bottomNavigationBar:
              Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 10),
                  child: _buildControlButtons(context, snapshot)
              ),
              body: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(
                          height: 80.0,
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            child: const Text('Import'),
                            onPressed: () {
                              print('ol');
                            },
                          ),
                        ),
                        const Text("Create CRC Card",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20.0)),
                        const SizedBox(
                          height: 15.0,
                        ),
                        Container(
                          margin: const EdgeInsets.all(25),
                          child: _buildCardTile(context, snapshot),
                        ),
                      ],
                    ),
                  )));
        }
    );
  }

  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  FlipCard _buildCardTile(context, snapshot) {
    return FlipCard(
      front: _buildFront(context, snapshot),
      back: _buildBack(context),
    );
  }

  _buildFront(context, snapshot){
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
            _buildTitleContainer(),
            const SizedBox(height: 30),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: (){
                setState(() {
                  responsibilityTextFormFields.add(createResponsibilityForm());
                  collaboratorEntries.add(DropDown(responsibilityTextFormFields.length - 1, widget.stackName));
                  collaboratorData.add(null);
                });

              },

            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildResponsibilitiesContainer(context),
                const SizedBox(width: 15),
                _buildCollaboratorsContainer(context, snapshot),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  _buildBack(context){
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
            _buildTitleContainer(),
            const SizedBox(
              height: 30,
            ),
            const Text('Description'),
            _buildDescriptionContainer(),
            const SizedBox(
              height: 10,
            ),
            const Text('Notes'),
            _buildNotesContainer(),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  _buildTitleContainer(){
    return TextFormField(
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
    );
  }

  _buildDescriptionContainer(){
    return TextFormField(
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
    );
  }

  _buildNotesContainer(){
    return TextFormField(
      keyboardType: TextInputType.multiline,
      maxLines: null,
      decoration: const InputDecoration(hintText: 'Notes'),
      controller: _notesEditingController,
    );
  }

  _buildResponsibilitiesContainer(context) {
    return Column(
      children: <Widget>[
        const Text(
            "Responsibilities", textAlign: TextAlign.center),
        SizedBox(
            height: MediaQuery
                .of(context)
                .size
                .height/1.5,
            width: MediaQuery
                .of(context)
                .size
                .width * .30,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
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
                                })
                              }
                          ),
                        ],
                        child: responsibilityTextFormFields[index],
                      );
                    },
                  ),
                ),
              ],
            )
        ),
      ],
    );
  }

  _buildCollaboratorsContainer(context, snapshot , [bool scrollable = false]) {
    return Column(
      children: <Widget>[
        const Text("Collaborators", textAlign: TextAlign.center),
        SizedBox(
          height: MediaQuery
              .of(context)
              .size
              .height/1.5,
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

  _buildControlButtons(BuildContext context, snapshot) {
    return Row(children: [
      TextButton(
        child: const Text('Cancel'),
        onPressed: () {
          FocusScope.of(context).requestFocus(FocusNode());
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CRCList(widget.i, widget.stackName)),
            );
        },
      ),
      const Spacer(),
      TextButton(
        child: const Text('Save'),
        onPressed: () {
          _save(context, snapshot);
          FocusScope.of(context).requestFocus(FocusNode());
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CRCList(widget.i, widget.stackName)),
          );
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
      //     print(_onDoneCollaborators());
      //   },
      // ),
    ]);
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

  _save(BuildContext context, snapshot) async {
    if (!_formKey.currentState.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        content: Text('CRC Card not finish. Did not save'),
      ));
      return;
    }
    FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName)
        .collection('${widget.stackName}_docs').get()
        .then(
            (snapshot) {
          for (var crc in snapshot.docs) {
            if (_titleEditingController.value.text == crc['class_name']) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
                content: Text('CRC Card Already Exists'),
              ));
              return;
            }
          }
        });
    var responsibilities = _onDoneResponsibilities();
    var collaborators = _onDoneCollaborators();
    var notes = _notesEditingController.value.text ?? '';
    FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName)
        .collection('${widget.stackName}_docs').add(
        {
          "class_name": _titleEditingController.value.text,
          "description": _descriptionEditingController.value.text,
          "responsibilities": responsibilities,
          "collaborators": collaborators,
          "notes": notes,

        })
        .then((value) {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: Colors.green,
      duration: Duration(seconds: 4),
      content: Text('CRC Card saved'),
    ));

    responsibilityTECs.clear();
    responsibilityTextFormFields.clear();
    collaboratorEntries.clear();
    collaboratorData.clear();
  }

  _onDoneResponsibilities() {
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

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

