import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'drawer.dart';
import 'signin.dart';
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(controller: _emailController),
              TextField(controller: _passController),
              SizedBox(height: 50),
              _signInButton(),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  /* Builds the sign in button with event handler to perform the login
   */
  Widget _signInButton() {
    return OutlineButton(
      splashColor: Colors.redAccent,
      onPressed: () {
        String email = _emailController.text.trim();
        String pass = _passController.text.trim();
        debugPrint("Logging in $email with $pass");
        signInWithEmail(email, pass).whenComplete(() {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ScoutHomePage(title: 'Trisonics Scouting')));
        });
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
