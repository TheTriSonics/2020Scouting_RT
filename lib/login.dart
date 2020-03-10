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
class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    asyncInitState();
  }

  void asyncInitState() async {
    // Force the user to log out on app start for testing.
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
                    controller: _passController,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your password',
                      labelText: 'Password',
                    ),
                    style: Theme.of(context).textTheme.body1,
                  ),
                  SizedBox(height: 50),
                  _signInButton(),
                  SizedBox(height: 50),
                ],
              ),
            ),
          )),
        ));
  }

  /* Builds the sign in button with event handler to perform the login
   */
  Widget _signInButton() {
    return OutlineButton(
      splashColor: Colors.redAccent,
      onPressed: () {
        String email = _emailController.text.trim();
        String pass = _passController.text.trim();
        bool createSuccess = true;
        try {
          FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: pass)
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
                'Sign in with email/password',
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
