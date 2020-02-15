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
  bool controlPanelColor = false;
  bool controlPanelRotation = false;
  bool groundPickup = false;
  bool humanLoadingPort = false;
  bool underControlPanel = false;
  int teleopPortInner = 0;
  int teleopPortTop = 0;
  int teleopPortBottom = 0;
  bool canBuddyHang = false;
  String optionHang;
  String optionMove;
  String comments = "";

  ScoutResult();
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
  ScoutResult _scoutResult;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _commentController = TextEditingController();
  final _matchController = TextEditingController();
  final _submitSnackbar = SnackBar(
    content: Text("Successfully submitted!"),
    backgroundColor: Colors.green,
  );

  final _validateErrorSnackbar = SnackBar(
    content: Text("Student, team, and match must be entered"),
    backgroundColor: Colors.red,
  );

  /* 
    * JJB: 
    * Part of me says this should be selectable and part of me says this might
    * as well be baked into the app to make really sure everybody is running
    * the proper version and nobody can possibly get confused and select the
    * wrong week. It's not lazy programming. I thought this through. On second
    * thought we could pick these values based on date. Just code the right
    * into the app. If curent date == X then compName = 'misjo' etc Setting
    * them in initState() makes the most sense if we do it that way.
    */
  String _compName = 'misjo';
  String _compYear = '2020';

  @override
  void initState() {
    super.initState();
    _scoutResult = new ScoutResult();
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
      }
    });
  }

  String getCurrDocumentID() {
    String matchNumber = _matchController.text;
    return "$_compYear:$_compName:${_teamObj.teamNumber}:${_studentObj.key}:$matchNumber";
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

  void verifyDocumentExists() {
    checkResultsDocumentExists(getCurrDocumentID()).then((e) {
      if (e == false) {
        createScoutResultDocument();
      }
    });
  }

  Widget buildAutoLine(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Moved completely off auto line?'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              _scoutResult.autoLine = b;
            });
          },
          value: _scoutResult.autoLine,
        )
      ],
    );
  }

  Widget buildControlPanel(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Control Panel To Correct Color'),
        Switch(
            onChanged: (bool b) {
              setState(() {
                _scoutResult.controlPanelColor = b;
              });
            },
            value: _scoutResult.controlPanelColor),
      ],
    );
  }

  Widget buildControlPanelRotation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Control Panel Rotation Count'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              _scoutResult.controlPanelRotation = b;
            });
          },
          value: _scoutResult.controlPanelRotation,
        )
      ],
    );
  }

  Widget buildGroundPickup(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Ground Pickup Capable'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              _scoutResult.groundPickup = b;
            });
          },
          value: _scoutResult.groundPickup,
        )
      ],
    );
  }

  Widget buildHumanLoadingPort(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Human Loading Port'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              _scoutResult.humanLoadingPort = b;
            });
          },
          value: _scoutResult.humanLoadingPort,
        )
      ],
    );
  }

  Widget buildUnderControlPanel(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Goes Under Control Panel'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              _scoutResult.underControlPanel = b;
            });
          },
          value: _scoutResult.underControlPanel,
        )
      ],
    );
  }

  Widget buildAutoPortInner(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Auto inner port score'),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    _scoutResult.autoPortInner--;
                    if (_scoutResult.autoPortInner < 0) {
                      _scoutResult.autoPortInner = 0;
                    }
                  });
                }),
            SizedBox(width: 16),
            Text(_scoutResult.autoPortInner.toString()),
            SizedBox(width: 16),
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _scoutResult.autoPortInner++;
                  });
                }),
          ],
        )
      ],
    );
  }

  Widget buildAutoPortTop(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Auto top port score'),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    _scoutResult.autoPortTop--;
                    if (_scoutResult.autoPortTop < 0) {
                      _scoutResult.autoPortTop = 0;
                    }
                  });
                }),
            SizedBox(width: 16),
            Text(_scoutResult.autoPortTop.toString()),
            SizedBox(width: 16),
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _scoutResult.autoPortTop++;
                  });
                }),
          ],
        )
      ],
    );
  }

  Widget buildAutoPortBottom(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Text('Auto bottom port score'),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    _scoutResult.autoPortBottom--;
                    if (_scoutResult.autoPortBottom < 0) {
                      _scoutResult.autoPortBottom = 0;
                    }
                  });
                }),
            SizedBox(width: 16),
            Text(_scoutResult.autoPortBottom.toString()),
            SizedBox(width: 16),
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _scoutResult.autoPortBottom++;
                  });
                }),
          ],
        )
      ],
    );
  }

  Widget buildCommentBar(BuildContext context) {
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

  Widget buildMatchNumber(BuildContext context) {
    Text('Match Number');
    return Row(
      children: <Widget>[
        new Flexible(
          child: new TextField(
            keyboardType: TextInputType.number,
            controller: _matchController,
            onChanged: (newtext) {
              debugPrint("Changed match.");
            },
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

  Widget buildSubmitButton(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Expanded(
          child: RaisedButton(
              color: Colors.red,
              child: Text('Submit'),
              onPressed: () {
                if (_studentObj == null ||
                    _teamObj == null ||
                    _matchController.text.trim().length == 0) {
                  _scaffoldKey.currentState
                      .showSnackBar(_validateErrorSnackbar);
                } else {
                  _scoutResult.comments = _commentController.text.trim();
                  var d = createMatchDocumentData();
                  Firestore.instance
                      .collection('scoutresults')
                      .document(getCurrDocumentID())
                      .setData(d);
                  _scaffoldKey.currentState.showSnackBar(_submitSnackbar);
                  setState(() {
                    _teamObj = null;
                    _scoutResult = new ScoutResult();
                    _matchController.text = "";
                    _commentController.text = "";
                  });
                }
              }),
        )
      ],
    );
  }

  Widget buildTeleopPortInner(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Teleop Inner Port Score'),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    _scoutResult.teleopPortInner--;
                    if (_scoutResult.teleopPortInner < 0) {
                      _scoutResult.teleopPortInner = 0;
                    }
                  });
                }),
            SizedBox(width: 16),
            Text(_scoutResult.teleopPortInner.toString()),
            SizedBox(width: 16),
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _scoutResult.teleopPortInner++;
                  });
                }),
          ],
        )
      ],
    );
  }

  Widget buildTeleopPortTop(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Teleop Top Port Score'),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
          IconButton(
              icon: Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  _scoutResult.teleopPortTop--;
                  if (_scoutResult.teleopPortTop < 0) {
                    _scoutResult.teleopPortTop = 0;
                  }
                });
              }),
          SizedBox(width: 16),
          Text(_scoutResult.teleopPortTop.toString()),
          SizedBox(width: 16),
          IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                setState(() {
                  _scoutResult.teleopPortTop++;
                });
              }),
        ])
      ],
    );
  }

  Widget buildTeleopPortBottom(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Teleop Bottom Port Score'),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    _scoutResult.teleopPortBottom--;
                    if (_scoutResult.teleopPortBottom < 0) {
                      _scoutResult.teleopPortBottom = 0;
                    }
                  });
                }),
            // TODO: Text() widgets aren't stateful, so changing the variable
            // behind one doesn't trigger a build(). So, we need to use a
            // TextField instead.
            SizedBox(width: 16), Text(_scoutResult.teleopPortBottom.toString()),
            SizedBox(width: 16),
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _scoutResult.teleopPortBottom++;
                  });
                }),
          ],
        )
      ],
    );
  }

  Widget buildBuddyHang(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('Can Buddy Climb'),
        Switch(
          onChanged: (bool b) {
            setState(() {
              _scoutResult.canBuddyHang = b;
            });
          },
          value: _scoutResult.canBuddyHang,
        )
      ],
    );
  }

  Widget buildCanHang(BuildContext context) {
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
                value: _scoutResult.optionHang,
                onChanged: (String v) {
                  setState(() {
                    _scoutResult.optionHang = v;
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

  Widget buildCanMove(BuildContext context) {
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
                value: _scoutResult.optionMove,
                onChanged: (String v) {
                  setState(() {
                    _scoutResult.optionMove = v;
                  });
                },
                items:
                    snapshot.data.documents.map<DropdownMenuItem<String>>((d) {
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

  Widget build2020ScoutingWidgets(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        SizedBox(height: 30),
        Text('Autonomous',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        buildAutoLine(context),
        buildAutoPortInner(context),
        buildAutoPortTop(context),
        buildAutoPortBottom(context),
        SizedBox(height: 30),
        Text('Teleop',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        buildTeleopPortInner(context),
        buildTeleopPortTop(context),
        buildTeleopPortBottom(context),
        buildUnderControlPanel(context),
        buildControlPanelRotation(context),
        buildControlPanel(context),
        buildGroundPickup(context),
        buildHumanLoadingPort(context),
        SizedBox(height: 30),
        Text('Endgame',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        buildCanHang(context),
        buildCanMove(context),
        buildBuddyHang(context),
        buildCommentBar(context),
        SizedBox(height: 20),
        buildSubmitButton(context),
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

  Map<String, dynamic> createMatchDocumentData() {
    //TODO: Pretty sure we're missing some here.
    var d = {
      'student_name': _studentObj.name,
      'match_number': _matchController.text.trim(),
      'team_number': _teamObj.teamNumber,
      'auto_line': _scoutResult.autoLine,
      'auto_port_inner': _scoutResult.autoPortInner,
      'auto_port_top': _scoutResult.autoPortTop,
      'auto_port_bottom': _scoutResult.autoPortBottom,
      'teleop_port_inner': _scoutResult.teleopPortInner,
      'teleop_port_top': _scoutResult.teleopPortTop,
      'teleop_port_bottom': _scoutResult.teleopPortBottom,
      'control_panel_color': _scoutResult.controlPanelColor,
      'control_panel_rotation': _scoutResult.controlPanelRotation,
      'ground_pickup': _scoutResult.groundPickup,
      'human_loading_port': _scoutResult.humanLoadingPort,
      'goes_under_control_panel': _scoutResult.underControlPanel,
      'can_buddy_hang': _scoutResult.canBuddyHang,
      'can_hang': _scoutResult.optionHang,
      'can_move': _scoutResult.optionMove,
      'comments': _scoutResult.comments
    };
    return d;
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

    var d = createMatchDocumentData();

    Firestore.instance
        .collection('scoutresults')
        .document(getCurrDocumentID())
        .setData(d);
  }

  @override
  Widget build(BuildContext context) {
    checkLogin(context);

    Widget scoutingArea = Text('Select student, team, and enter match first.');
    // This method is rerun every time setState is called and setState detects a
    // change that warrants a rebuild of the UI.
    // It's like magic.  OoOoOo!
    return Scaffold(
      drawer: buildAppDrawer(context),
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        margin: EdgeInsets.fromLTRB(16, 32, 16, 32),
        child: ListView(
          children: <Widget>[
            buildStudentSelector(context),
            buildTeamSelector(context),
            buildTeamDisplay(context),
            buildMatchNumber(context),
            build2020ScoutingWidgets(context),
          ],
        ),
      ),
    );
  }
}
