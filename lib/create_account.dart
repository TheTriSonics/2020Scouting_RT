import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'drawer.dart';
import 'main.dart';

/*
 * Simple page to handle logins via email/password combination
 * Decent documentation on how to handle this can be found here:
 * https://heartbeat.fritz.ai/firebase-user-authentication-in-flutter-1635fb175675
 */
class CreateAccountPage extends StatefulWidget {
  CreateAccountPage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _emailController = TextEditingController();
  final _pass1Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    asyncInitState();
  }

  void asyncInitState() async {
    // If the user is creating an account log them out of whatever they were in, if any.
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: buildAppDrawer(context),
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
          color: Colors.white,
          child: SingleChildScrollView(
              child: Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(48, 0, 48, 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image(
                      image: AssetImage('assets/TriSonicsLogo.png'),
                      height: 96),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter email address',
                      labelText: 'Email',
                    ),
                    style: Theme.of(context).textTheme.body1,
                  ),
                  SizedBox(height: 32),
                  TextField(
                    controller: _pass1Controller,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your new password',
                      labelText: 'Password',
                    ),
                    style: Theme.of(context).textTheme.body1,
                  ),
                  SizedBox(height: 50),
                  _createAcctButton(),
                  SizedBox(height: 50),
                ],
              ),
            ),
          )),
        ));
  }

  /* Builds the sign in button with event handler to perform the login
   */
  Widget _createAcctButton() {
    return OutlineButton(
      splashColor: Colors.redAccent,
      onPressed: () {
        String email = _emailController.text.trim();
        String pass1 = _pass1Controller.text.trim();
        bool createSuccess = true;
        try {
          FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: pass1)
              .catchError((error) {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Error"),
                    content: Text(error.message),
                    actions: <Widget>[
                      FlatButton(
                        child: Text("Ok"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  );
                });
            createSuccess = false;
          }).then((ar) {
            debugPrint("In the then() now.)");
            if (createSuccess) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ScoutHomePage(title: 'Trisonics Scouting')));
            }
          });
        } on PlatformException catch (error) {
          debugPrint(error.toString());
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      highlightElevation: 0,
      borderSide: BorderSide(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
