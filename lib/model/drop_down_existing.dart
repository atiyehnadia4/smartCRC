import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_crc_gf/crc/crc_existing_entry.dart';

class DropDownExisting extends StatefulWidget {
  final String value;
  final int index;
  final String currCard;
  final String stackName;
  DropDownExisting(this.value, this.index, this.currCard, this.stackName);
  @override
  _DropDownExistingState createState() => _DropDownExistingState();
}

class _DropDownExistingState extends State<DropDownExisting> {
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
    var collaborators = [];
    String newValue = widget.value;
    for(var i = 0; i < snapshot.data.docs.length; i++){
      var card = snapshot.data.docs[i];
      collaborators.add(card['class_name']);
    }
    collaborators.remove(widget.currCard);

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
                  CRCEntryExistingState.collaboratorData[widget.index] = newValue;
                });
              },
            ),
          ),
        ]
    );
  }

}