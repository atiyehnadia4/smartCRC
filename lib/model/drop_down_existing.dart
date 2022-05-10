import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:smart_crc_gf/crc/crc_existing_entry.dart';

class DropDownExisting extends StatefulWidget {
  final List<String> value;
  final int index;
  final String currCard;
  final String stackName;
  DropDownExisting(this.value, this.index, this.currCard, this.stackName);
  @override
  _DropDownExistingState createState() => _DropDownExistingState();
}

class _DropDownExistingState extends State<DropDownExisting> {
  final _multiSelectKey = GlobalKey<FormFieldState>();
  String newValue;

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

    List<String> newValue  = widget.value;
    for (var i = 0; i < snapshot.data.docs.length; i++) {
      var card = snapshot.data.docs[i];
      collaborators.add(card['class_name']);
    }
    collaborators.remove(widget.currCard);

    return Row(
        children: [
          Text('${widget.index + 1}. '),
          const SizedBox(width: 10,),
          Expanded(
            child: MultiSelectBottomSheetField<String>(
              initialValue: newValue,
              key: _multiSelectKey,
              initialChildSize: 0.7,
              maxChildSize: 0.95,
              title: const Text("Select Collaborators"),
              items: collaborators.map((collaborator) =>
                  MultiSelectItem<String>(collaborator, collaborator)).toList(),
              searchable: true,
              onConfirm: (collaborator) {
                newValue = collaborator;
                setState(() {
                  newValue = collaborator;
                  CRCEntryExistingState.collaboratorData[widget.index] = newValue;
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