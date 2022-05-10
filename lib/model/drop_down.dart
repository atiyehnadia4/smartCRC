import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../crc/crc_entries.dart';

class DropDown extends StatefulWidget {
  final int index;
  final String stackName;
  DropDown(this.index, this.stackName);
  @override
  _DropDownState createState() => _DropDownState();
}

class _DropDownState extends State<DropDown> {
  final _multiSelectKey = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('crc_stack').doc(widget.stackName).collection('${widget.stackName}_docs')
        .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('Loading...');
          return _controllerHelper(snapshot);
        }
    );
  }


  _controllerHelper(snapshot,[bool editable = false, bool scrollable = false]) {
    var collaborators = ['Will edit'];
    List<String> newValue  = [];
    // String newValue;
    for(var i = 0; i < snapshot.data.docs.length; i++){
      var card = snapshot.data.docs[i];
      collaborators.add(card['class_name']);
    }

    return Row(
        children: [
          Text('${widget.index + 1}. '),
          const SizedBox(width: 10,),
          Expanded(
            child: MultiSelectBottomSheetField<String>(
              key: _multiSelectKey,
              initialChildSize: 0.7,
              maxChildSize: 0.95,
              title: const Text("Select Collaborators"),
              items: collaborators.map((collaborator) => MultiSelectItem<String>(collaborator, collaborator)).toList(),
              searchable: true,
              onConfirm: (collaborator) {
                newValue = collaborator;
                setState(() {
                  newValue = collaborator;
                  CRCEntryNewState.collaboratorData[widget.index] = newValue;
                });
                _multiSelectKey.currentState.validate();
              },
              chipDisplay: MultiSelectChipDisplay(
                onTap: (item) {
                  setState(() {
                    newValue.remove(item);
                  });
                  _multiSelectKey.currentState.validate();
                },
              ),
            ),
          ),
        ]
    );
  }
}