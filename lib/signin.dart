import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<String> signInWithEmail(String email, String pass) async {
  _auth.signInWithEmailAndPassword(email: email, password: pass);
  // TODO, check return, redirect
  return "";
}
