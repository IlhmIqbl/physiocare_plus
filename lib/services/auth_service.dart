import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:physiocare/models/user_model.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> registerWithEmailPassword(
      String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _createUserDoc(credential.user!, name);
    return credential;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final oauthCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final credential = await _auth.signInWithCredential(oauthCredential);

    if (credential.additionalUserInfo?.isNewUser == true) {
      await _createUserDoc(credential.user!, googleUser.displayName ?? '');
    }

    return credential;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> _createUserDoc(User user, String name) async {
    final now = DateTime.now();

    await _firestore.collection('users').doc(user.uid).set(
      {
        'name': name,
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'userType': 'freemium',
        'bodyFocusAreas': [],
        'painSeverity': 0,
        'createdAt': Timestamp.fromDate(now),
      },
      SetOptions(merge: true),
    );

    await _firestore.collection('subscriptions').doc(user.uid).set(
      {
        'userId': user.uid,
        'type': 'freemium',
        'paymentStatus': 'active',
        'startDate': Timestamp.fromDate(now),
        'endDate': null,
      },
      SetOptions(merge: true),
    );
  }

  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}
