import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'drawer.dart';
import 'login.dart';

void main() => runApp(FRC4003ScoutApp());

/*
 * Container class that holds data on a student.
 */
class Student {
  final String key;
  final String name;
  /* Dart has an handy constrcutor syntax to handle a common initialization case.  This is the equivalent to:
  Student(String key, String name) {
    this.key = key;
    this.name = name;
  }
  ... because that happens so often you sometimes find shortcuts for it.  This is Dart's.
  */
  Student(this.key, this.name);

  // JJB: you need to override this or the DropDown controls flip out about
  // having 0 or 2+ possible items for any value.
  bool operator ==(Object other) => other is Student && other.key == key;
  // ... and if you override == you should override hashCode
  int get hashCode => key.hashCode;
}

/*
 * Container class that holds data on a team.
 */

class Team {
  String teamNumber;
  String teamName;
  String schoolName;
  Team(this.teamNumber, this.teamName, this.schoolName);
  Team.fromSnapshot(DocumentSnapshot snapshot)
      : teamNumber = snapshot.documentID,
        teamName = snapshot['team_name'],
        schoolName = snapshot['school_name'];
  bool operator ==(Object other) =>
      other is Team && other.teamNumber == teamNumber;
  int get hashCode => teamNumber.hashCode;
}

/*
 * Class that represents the data we're storing for every scouted match in Firecloud.
 */

class ScoutResult {
  bool autoLine = false;
  int autoPortInner = 0;
  int autoPortTop = 0;
  int autoPortBottom = 0;
  bool controlPanel = false;
  bool controlPanelRotation = false;
  bool groundPickup = false;
  bool humanLoadingPort = false;
  bool underControlPanel = false;
  int teleopPortInner = 0;
  int teleopPortTop = 0;
  int teleopPortBottom = 0;
  bool canBuddyHang = false;
  String comments = "";
  String matchNumber = "";

  ScoutResult.fromSnapshot(DocumentSnapshot snapshot)
      : autoLine =
            snapshot['auto_line'] == null ? false : snapshot['auto_line'],
        autoPortInner = snapshot['auto_port_inner'] == null
            ? 0
            : snapshot['auto_port_inner'],
        autoPortTop =
            snapshot['auto_port_top'] == null ? 0 : snapshot['auto_port_top'],
        autoPortBottom = snapshot['auto_port_bottom'] == null
            ? 0
            : snapshot['auto_port_bottom'],
        controlPanel = snapshot['control_panel'] == null
            ? false
            : snapshot['control_panel'],
        controlPanelRotation = snapshot['control_panel_rotation'] == null
            ? false
            : snapshot['control_panel_rotation'],
        groundPickup = snapshot['ground_pickup'] == null
            ? false
            : snapshot['ground_pickup'],
        humanLoadingPort = snapshot['human_loading_port'] == null
            ? false
            : snapshot['human_loading_port'],
        underControlPanel = snapshot['goes_under_control_panel'] == null
            ? false
            : snapshot['goes_under_control_panel'],
        teleopPortInner = snapshot['teleop_port_inner'] == null
            ? 0
            : snapshot['teleop_port_inner'],
        teleopPortTop = snapshot['teleop_port_top'] == null
            ? 0
            : snapshot['teleop_port_top'],
        teleopPortBottom = snapshot['teleop_port_bottom'] == null
            ? 0
            : snapshot['teleop_port_bottom'],
        canBuddyHang = snapshot['can_buddy_hang'] == null
            ? false
            : snapshot['can_buddy_hang'];
}

// Unused class, keeping around for now.
class Match {
  String blue1;
  String blue2;
  String blue3;
  String red1;
  String red2;
  String red3;

  Match.fromSnapshot(DocumentSnapshot snapshot)
      : blue1 = snapshot['blue1'],
        blue2 = snapshot['blue2'],
        blue3 = snapshot['blue3'],
        red1 = snapshot['red1'],
        red2 = snapshot['red2'],
        red3 = snapshot['red3'];
}

class FRC4003ScoutApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trisonics Scouting',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: ScoutHomePage(title: 'Trisonics Scouting'),
    );
  }
}

class ScoutHomePage extends StatefulWidget {
  ScoutHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _ScoutHomePageState createState() => _ScoutHomePageState();
}

class _ScoutHomePageState extends State<ScoutHomePage> {
  Student _studentObj;
  Team _teamObj;
  String _matchNumber;
  bool _matchBegun;
  String _optionHang;
  String _optionMove;

  final _commentController = TextEditingController();
  final _matchNumberController = TextEditingController();

  /* 
    * JJB: 
    * Part of me says this should be selectable and part of me says this might
    * as well be baked into the app to make really sure everybody is running
    * the proper version and nobody can possibly get confused and select the
    * wrong week.
    * It's not lazy programming.  I thought this through. 
    */
  String _compName = 'misjo';
  String _compYear = '2020';

  @override
  void initState() {
    super.initState();
    _matchNumber = "1";
    _matchBegun = false;
  }

  /* Check to see if the user is logged in.  If not send them to the login
   * page.
   */
  void checkLogin(BuildContext context) {
    FirebaseAuth.instance.currentUser().then((FirebaseUser user) {
      if (user == null) {
        debugPrint("Not logged in... redirecting.");
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => LoginPage(title: 'Login')));
      } else {
        debugPrint("Current user id: ${user.uid}");
      }
    });
  }

  String getCurrDocumentID() {
    return "$_compYear:$_compName:${_teamObj.teamNumber}:${_studentObj.key}:$_matchNumber";
  }

  Widget buildStudentSelector(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return LinearProgressIndicator();
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Who are you?'),
              DropdownButton<Student>(
                value: _studentObj,
                onChanged: (Student v) {
                  /*
                  debugPrint("Student key set to ${v.key}");
                  debugPrint("Student name set to ${v.name}");
                  */
                  setState(() {
                    _studentObj = v;
                  });
                },
                items:
                    snapshot.data.documents.map<DropdownMenuItem<Student>>((d) {
                  /*
                  debugPrint("Student documentID dump: ${d.documentID}");
                  debugPrint("Student name dump: ${d['name']}");
                  */
                  return DropdownMenuItem<Student>(
                    value: Student(d.documentID, d['name']),
                    child: Text(d['name']),
                  );
                }).toList(),
              ),
            ],
          );
        });
  }

  Widget buildTeamSelector(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('competitions')
            .document(_compYear)
            .collection(_compName)
            .orderBy('sort_order')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return LinearProgressIndicator();
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Who are they?'),
              DropdownButton<Team>(
                value: _teamObj,
                onChanged: (Team v) async {
                  setState(() {
                    _teamObj = v;
                  });
                  bool mb =
                      await checkResultsDocumentExists(getCurrDocumentID());
                  setState(() {
                    _matchBegun = mb;
                  });
                },
                items: snapshot.data.documents.map<DropdownMenuItem<Team>>((d) {
                  /*
                  debugPrint("Team documentID dump: ${d.documentID}");
                  debugPrint("Team name dump: ${d['team_name']}");
                  */
                  return DropdownMenuItem<Team>(
                    value: Team(d.documentID, d['team_name'], d['school_name']),
                    child: Text(d.documentID),
                  );
                }).toList(),
              ),
            ],
          );
        });
  }

  Widget buildTeamDisplay(BuildContext context) {
    if (_teamObj != null && _teamObj.teamName.length > 0) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[Text('You have selected ${_teamObj.teamName}')]);
    }
    return SizedBox.shrink();
  }

  Widget buildStartButton(BuildContext context) {
    if (_teamObj != null && _teamObj.teamName.length > 0) {
      return Visibility(
          visible: _matchBegun == false,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                    child: Text('Begin scouting!'),
                    onPressed: () {
                      setState(() {
                        _matchBegun = true;
                      });
                      createScoutResultDocument();
                    })
              ]));
    }
    return SizedBox.shrink();
  }

  Widget buildAutoLine(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Moved completely off auto line?'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'auto_line': b});
            });
          },
          value: sr.autoLine,
        )
      ],
    );
  }

  Widget buildControlPanel(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Control Panel To Correct Color'),
        Switch(
            onChanged: (bool b) {
              setState(() {
                Firestore.instance
                    .collection('scoutresults')
                    .document(getCurrDocumentID())
                    .updateData({'control_panel': b});
              });
            },
            value: sr.controlPanel),
      ],
    );
  }

  Widget buildControlPanelRotation(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Control Panel Rotation Count'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'control_panel_rotation': b});
            });
          },
          value: sr.controlPanelRotation,
        )
      ],
    );
  }

  Widget buildGroundPickup(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Ground Pickup Capable'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'ground_pickup': b});
            });
          },
          value: sr.groundPickup,
        )
      ],
    );
  }

  Widget buildHumanLoadingPort(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Human Loading Port'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'human_loading_port': b});
            });
          },
          value: sr.humanLoadingPort,
        )
      ],
    );
  }

  Widget buildUnderControlPanel(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Goes Under Control Panel'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'goes_under_control_panel': b});
            });
          },
          value: sr.underControlPanel,
        )
      ],
    );
  }

  Widget buildAutoPortInner(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }

    // JJB: Note the pre-increment version of ++ and -- below; they're not the
    // typical post increment that you see.  We're doing ++c not c++.
    // There is a difference.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Auto inner port score'),
        IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'auto_port_inner': --sr.autoPortInner});
            }),
        Text(sr.autoPortInner.toString()),
        IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'auto_port_inner': ++sr.autoPortInner});
            }),
      ],
    );
  }

  Widget buildAutoPortTop(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }

    // JJB: Note the pre-increment version of ++ and -- below; they're not the
    // typical post increment that you see.  We're doing ++c not c++.
    // There is a difference.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Auto top port score'),
        IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'auto_port_top': --sr.autoPortTop});
            }),
        Text(sr.autoPortTop.toString()),
        IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'auto_port_top': ++sr.autoPortTop});
            }),
      ],
    );
  }

  Widget buildAutoPortBottom(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }
    // JJB: Note the pre-increment version of ++ and -- below; they're not the
    // typical post increment that you see.  We're doing ++c not c++.
    // There is a difference.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Text('Auto bottom port score'),
        IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'auto_port_bottom': --sr.autoPortBottom});
            }),
        Text(sr.autoPortBottom.toString()),
        IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'auto_port_bottom': ++sr.autoPortBottom});
            }),
      ],
    );
  }

  Widget buildCommentBar(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }

    return Row(
      children: <Widget>[
        new Flexible(
          child: new TextField(
            controller: _commentController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Comments',
            ),
            style: Theme.of(context).textTheme.body1,
          ),
        ),
      ],
    );
  }

  Widget buildMatchNumber(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }
    Text('Match Number');
    return Row(
      children: <Widget>[
        new Flexible(
          child: new TextField(
            controller: _matchNumberController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Match Number',
            ),
            style: Theme.of(context).textTheme.body1,
          ),
        ),
      ],
    );
  }

  Widget buildSubmitButton(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }

    return Row(
      children: <Widget>[
        RaisedButton(
            child: Text('Submit'),
            onPressed: () {
              debugPrint("Handle submit here.");
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'comments': _commentController.text.trim()});
            }),
      ],
    );
  }

  Widget buildTeleopPortInner(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }

    // JJB: Note the pre-increment version of ++ and -- below; they're not the
    // typical post increment that you see.  We're doing ++c not c++.
    // There is a difference.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Teleop Inner Port Score'),
        IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'teleop_port_inner': --sr.teleopPortInner});
            }),
        Text(sr.teleopPortInner.toString()),
        IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'teleop_port_inner': ++sr.teleopPortInner});
            }),
      ],
    );
  }

  Widget buildTeleopPortTop(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }

    // JJB: Note the pre-increment version of ++ and -- below; they're not the
    // typical post increment that you see.  We're doing ++c not c++.
    // There is a difference.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Teleop Top Port Score'),
        IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'teleop_port_top': --sr.teleopPortTop});
            }),
        Text(sr.teleopPortTop.toString()),
        IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'teleop_port_top': ++sr.teleopPortTop});
            }),
      ],
    );
  }

  Widget buildTeleopPortBottom(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }

    // JJB: Note the pre-increment version of ++ and -- below; they're not the
    // typical post increment that you see.  We're doing ++c not c++.
    // There is a difference.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Teleop Bottom Port Score'),
        IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'teleop_port_bottom': --sr.teleopPortBottom});
            }),
        Text(sr.teleopPortBottom.toString()),
        IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'teleop_port_bottom': ++sr.teleopPortBottom});
            }),
      ],
    );
  }

  Widget buildBuddyHang(BuildContext context, ScoutResult sr) {
    if (_studentObj == null) {
      return Text('select student first.');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Can Buddy Climb'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              Firestore.instance
                  .collection('scoutresults')
                  .document(getCurrDocumentID())
                  .updateData({'can_buddy_hang': b});
            });
          },
          value: sr.canBuddyHang,
        )
      ],
    );
  }

  Widget buildCanHang(BuildContext context, ScoutResult sr) {
    return StreamBuilder(
        stream: Firestore.instance.collection('dropdownoptions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return LinearProgressIndicator();
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Can Hang?'),
              DropdownButton<String>(
                value: _optionHang,
                onChanged: (String v) {
                  /*
                  debugPrint("Student key set to ${v.key}");
                  debugPrint("Student name set to ${v.name}");
                  */
                  setState(() {
                    _optionHang = v;
                  });
                },
                items:
                    snapshot.data.documents.map<DropdownMenuItem<String>>((d) {
                  /*
                  debugPrint("Student documentID dump: ${d.documentID}");
                  debugPrint("Student name dump: ${d['name']}");
                  */
                  return DropdownMenuItem<String>(
                    value: d['option'],
                    child: Text(d['option']),
                  );
                }).toList(),
              ),
            ],
          );
        });
  }

  Widget buildCanMove(BuildContext context, ScoutResult sr) {
    return StreamBuilder(
        stream: Firestore.instance.collection('dropdownoptions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return LinearProgressIndicator();
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Can Move On Bar?'),
              DropdownButton<String>(
                value: _optionMove,
                onChanged: (String v) {
                  /*
                  debugPrint("Student key set to ${v.key}");
                  debugPrint("Student name set to ${v.name}");
                  */
                  setState(() {
                    _optionMove = v;
                  });
                },
                items:
                    snapshot.data.documents.map<DropdownMenuItem<String>>((d) {
                  /*
                  debugPrint("Student documentID dump: ${d.documentID}");
                  debugPrint("Student name dump: ${d['name']}");
                  */
                  return DropdownMenuItem<String>(
                    value: d['option'],
                    child: Text(d['option']),
                  );
                }).toList(),
              ),
            ],
          );
        });
  }

  Widget build2020ScoutingWidgets(BuildContext context, ScoutResult sr) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        buildMatchNumber(context, sr),
        SizedBox(height: 30),
        Text('Autonomous', style: TextStyle(fontWeight: FontWeight.bold)),
        buildAutoLine(context, sr),
        buildAutoPortInner(context, sr),
        buildAutoPortTop(context, sr),
        buildAutoPortBottom(context, sr),
        SizedBox(height: 30),
        Text('Teleop', style: TextStyle(fontWeight: FontWeight.bold)),
        buildTeleopPortInner(context, sr),
        buildTeleopPortTop(context, sr),
        buildTeleopPortBottom(context, sr),
        buildUnderControlPanel(context, sr),
        buildControlPanelRotation(context, sr),
        buildControlPanel(context, sr),
        buildGroundPickup(context, sr),
        buildHumanLoadingPort(context, sr),
        SizedBox(height: 30),
        Text('Endgame', style: TextStyle(fontWeight: FontWeight.bold)),
        buildCanHang(context, sr),
        buildCanMove(context, sr),
        buildBuddyHang(context, sr),
        buildCommentBar(context, sr),
        buildSubmitButton(context, sr),
      ],
    );
  }

  Future<bool> checkResultsDocumentExists(String docID) async {
    final snap = await Firestore.instance
        .collection('scoutresults')
        .document(getCurrDocumentID())
        .get();
    return snap.exists;
  }

  void createScoutResultDocument() async {
    // Prefixing an async function call with await forces it to await for it to finish.
    // This returns us to a synchronous programming model.
    final snap = await Firestore.instance
        .collection('scoutresults')
        .document(getCurrDocumentID())
        .get();
    if (snap.exists) {
      return; // Nothing needs to be done.
    }

    var d = {
      'student_name': _studentObj.name,
      'auto_line': false,
      'auto_port_bottom': 0
    };
    Firestore.instance
        .collection('scoutresults')
        .document(getCurrDocumentID())
        .setData(d);
  }

  Widget build2020ScoutingStream(BuildContext context) {
    if (_matchNumber == null ||
        _matchNumber.length == 0 ||
        _teamObj == null ||
        _teamObj.teamNumber.length == 0 ||
        _studentObj == null) {
      return SizedBox.shrink();
    }

    return StreamBuilder(
        stream: Firestore.instance
            .collection('scoutresults')
            .document(getCurrDocumentID())
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data == null ||
              !snapshot.data.exists) {
            return SizedBox.shrink();
          }
          return build2020ScoutingWidgets(
              context, ScoutResult.fromSnapshot(snapshot.data));
        });
  }

  @override
  Widget build(BuildContext context) {
    checkLogin(context);
    // This method is rerun every time setState is called and setState detects a
    // change that warrants a rebuild of the UI.
    // It's like magic.  OoOoOo!
    return Scaffold(
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        margin: EdgeInsets.fromLTRB(16, 32, 16, 32),
        child: ListView(
          //mainAxisAlignment: MainAxisAlignment.start,
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            buildStudentSelector(context),
            buildTeamSelector(context),
            buildTeamDisplay(context),
            buildStartButton(context),
            build2020ScoutingStream(context),
          ],
        ),
      ),
    );
  }
}
