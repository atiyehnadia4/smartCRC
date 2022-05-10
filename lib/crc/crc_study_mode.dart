import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CRCStudy extends StatefulWidget {
  final String stackName;
  const CRCStudy(this.stackName , {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CRCStudyState();
}

class CRCStudyState extends State<CRCStudy> {
  List<List<Widget>> cardList = [];
  List<Widget> stack = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('${widget.stackName} Stack',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20.0)),
        ),
        body: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('crc_stack')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('Loading...');
              }
              return ListView.builder(
                  itemCount: stack.length,
                  itemBuilder: (BuildContext context, int cardIndex) {
                    return Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width,
                        height: MediaQuery
                            .of(context)
                            .size
                            .height,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: InkWell(
                          child: stack[0],
                        ),
                    );
                  }
              );
            }
        ),
    );
  }

  _buildStack() async {
    stack.clear();
    cardList.clear();


      var crcCollectionSnapshot = await FirebaseFirestore.instance.collection(
          'crc_stack').doc(widget.stackName).collection('${widget.stackName}_docs').get();

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
                    children: <Widget> [
                      Text('${widget.stackName} Stack', textAlign: TextAlign.center, style: const TextStyle(fontSize: 30)),],) ),
            )
                , growable: true));
      }
      else{
        cardList.add(List<FlipCard>.filled(crcCardList.length, const FlipCard(back: null, front: null,), growable: true));
      }

      var j = 0;
      for (var crc in crcCardList) {
        var crcName = crc['class_name'] ?? '';
        var crcResponsibilities = crc['responsibilities'] ?? '';
        var crcCollaborators = crc['collaborators'] ?? '';
        var crcNotes = crc['notes'] ?? '';
        var crcDescription = crc['description'] ?? '';
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
        cardList[0][j] = _buildCardTile(crcName, crcResponsibilities, reducedCollaborators, crcNotes, crcDescription);

        j++;
      }
      stack.add(CarouselSlider(
        options: CarouselOptions(
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 1.7,
        ),
        items: cardList[0],
      ));

    setState(() {
      stack;
      cardList;
    });
  }

  FlipCard _buildCardTile(crcName, responsibilities, collaborators, notes, description) {
    return FlipCard(
      front: _buildFront(crcName, responsibilities, collaborators),
      back: _buildBack(crcName, description, notes),
    );
  }

  _buildFront(title, responsibilities, collaborators){
    return Card(
      child: Container(
        margin: const EdgeInsets.all(20),
        width: MediaQuery
            .of(context)
            .size
            .width * 3,
        height: MediaQuery
            .of(context)
            .size
            .height,
        child: ListView(
          children: [
            const Align(
              child: Text("Title:", textAlign: TextAlign.center),
              alignment: Alignment.topCenter,
            ),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30),),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildResponsibilitiesContainer(responsibilities),
                const SizedBox(width: 15),
                _buildCollaboratorsContainer(collaborators),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  _buildBack(title, description, notes){
    return Card(
      child: Container(
        margin: const EdgeInsets.all(20),
        width: MediaQuery
            .of(context)
            .size
            .width * 3,
        height: MediaQuery
            .of(context)
            .size
            .height,
        child: ListView(
          children: [
            const Align(
              child: Text("Title:", textAlign: TextAlign.center,),
              alignment: Alignment.topCenter,
            ),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30)),
            const SizedBox(
              height: 30,
            ),
            const Text('Description:'),
            const SizedBox(
              height: 5,
            ),
            Text(description, style: const TextStyle(fontSize: 20)),
            const SizedBox(
              height: 10,
            ),
            const Text('Notes:'),
            const SizedBox(
              height: 5,
            ),
            Text(notes, style: const TextStyle(fontSize: 20)),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  _buildResponsibilitiesContainer(responsibilities) {
    return Column(
      children: <Widget>[
        const Text(
            "Responsibilities:", textAlign: TextAlign.center),
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
                for(var response in responsibilities)
                  Text('- $response', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20),),
              ],
            )
        ),
      ],
    );
  }

  _buildCollaboratorsContainer(collaborators) {
    return Column(
      children: <Widget>[
        const Text("Collaborators:", textAlign: TextAlign.center),
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
            children: <Widget> [
              for(var collab in collaborators)
                Text('- $collab', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20),),
            ],
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
        )
      ],
    );
  }

  @override
  void initState(){
    super.initState();
    stack.clear();
    cardList.clear();
    setState(() {
      _buildStack();
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }
}