import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../crc/crc_entries.dart';

class DropDown extends StatefulWidget {
  final int index;
  final int stackIndex;
  DropDown(this.index, this.stackIndex);
  @override
  _DropDownState createState() => _DropDownState();
}

class _DropDownState extends State<DropDown> {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('crc_stack').doc('stack${widget.stackIndex}').collection('stack${widget.stackIndex}_docs')
        .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('Loading...');
          return _controllerHelper(snapshot);
        }
    );
  }


  _controllerHelper(snapshot,[bool editable = false, bool scrollable = false]) {
    var collaborators = [];
    String newValue;
    for(var i = 0; i < snapshot.data.docs.length; i++){
      var card = snapshot.data.docs[i];
      collaborators.add(card['class_name']);
    }

    return Row(
        children: [
          Text('${widget.index + 1}. '),
          const SizedBox(width: 10,),
          Expanded(
            child: DropdownButtonFormField<String>(
              hint: const Text("Please Choose"),
              isExpanded: true,
              value: newValue,
              items: collaborators.map<DropdownMenuItem<String>>((
                  dynamic value) {
                return DropdownMenuItem<String>(
                  child: Text(value),
                  value: value,
                );
              }).toList()..add(
                  const DropdownMenuItem(
                      child: Text('Still Deciding'),
                      value: 'Will Edit'
                  )
              ),
              onChanged: (String collaborator) {
                newValue = collaborator;
                setState(() {
                  newValue = collaborator;
                  CRCEntryNewState.collaboratorData[widget.index] = newValue;
                });
              },
            ),
          ),
        ]
    );
  }
}