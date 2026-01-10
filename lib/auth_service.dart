import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign Up - පරිශීලකයා සාදා Firestore එකට දත්ත යැවීම
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    String? phone
  }) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      // 'role' එක අනිවාර්යයෙන්ම 'customer' ලෙස මෙහිදී ලබා දේ
      UserModel newUser = UserModel(
        uid: res.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: 'customer',
      );

      // Firestore හි 'users' collection එකට දත්ත ඇතුළත් කිරීම
      await _db.collection('users').doc(res.user!.uid).set(newUser.toMap());

      return newUser;
    } catch (e) {
      print("Sign Up Error: $e");
      rethrow;
    }
  }

  // Sign In - ලොග් වීම
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print("Login Error: $e");
      rethrow;
    }
  }

  // දැනට ලොග් වී සිටින User ගේ දත්ත ලබා ගැනීම
  Future<UserModel?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    }
    return null;
  }

  // Logout වීම
  Future<void> signOut() => _auth.signOut();
}