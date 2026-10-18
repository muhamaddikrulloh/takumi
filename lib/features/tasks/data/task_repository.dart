import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_track/core/utils/app_logger.dart';
import 'package:task_track/features/tasks/domain/task.dart';

abstract class TaskRepository {
  String? get currentVerifiedUid;
  Stream<List<Task>> watchTasks();
  Future<void> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String taskId);
}

class FirestoreTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreTaskRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  @override
  String? get currentVerifiedUid {
    final user = _auth.currentUser;
    return user != null && user.emailVerified ? user.uid : null;
  }

  String get _uid {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      throw StateError('Verified user required');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('users').doc(_uid).collection('tasks');

  @override
  Stream<List<Task>> watchTasks() {
    return _tasksCollection
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) {
          final tasks = <Task>[];
          for (final doc in snapshot.docs) {
            try {
              tasks.add(Task.fromFirestoreMap({...doc.data(), 'id': doc.id}));
            } catch (error) {
              logDebug('Skipping malformed task ${doc.id}', error: error);
            }
          }
          return tasks;
        });
  }

  @override
  Future<void> createTask(Task task) async {
    await _tasksCollection.doc(task.id).set(task.toFirestoreMap());
  }

  @override
  Future<void> updateTask(Task task) async {
    await _tasksCollection.doc(task.id).update(task.toFirestoreMap());
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }
}
