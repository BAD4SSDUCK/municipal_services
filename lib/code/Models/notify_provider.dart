import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {

  static final NotificationProvider _instance = NotificationProvider._internal();
  final Map<String, bool> _councillorUnreadMessages = {};
  bool _hasUnreadMessages = false;
  bool _hasUnreadFinanceMessages = false;
  bool _hasUnreadNotices = false;
  bool _isListening = false;


  bool get hasUnreadMessages => _hasUnreadMessages;
  bool get hasUnreadFinanceMessages => _hasUnreadFinanceMessages;
  bool get hasUnreadNotices => _hasUnreadNotices;
  Map<String, bool> get councillorUnreadMessages => _councillorUnreadMessages;

  // Getter for unread notices
  factory NotificationProvider() => _instance;

  NotificationProvider._internal() {

    _listenToRegularChatUpdates();
    _listenToFinanceChatUpdates();
    _listenToNoticesUpdates();
  }


  void _listenToNoticesUpdates() {
    FirebaseFirestore.instance
        .collectionGroup('Notifications')
        .snapshots()
        .listen((snapshot) {
      bool newUnreadNoticesStatus = snapshot.docs.any((doc) => doc['read'] == false);

      if (_hasUnreadNotices != newUnreadNoticesStatus) {
        print("Provider: updating _hasUnreadNotices to $newUnreadNoticesStatus");
        _hasUnreadNotices = newUnreadNoticesStatus;
        notifyListeners();
      }
    });
  }


  void updateUnreadNoticesStatus(bool hasUnreadNotices) {
    _hasUnreadNotices = hasUnreadNotices;
    notifyListeners();
  }

  void _listenToRegularChatUpdates() {
    FirebaseFirestore.instance.collectionGroup('chats')
        .where('isReadByMunicipalUser', isEqualTo: false)
        .snapshots().listen((snapshot) {
      bool newUnreadStatus = snapshot.docs.isNotEmpty;
      if (_hasUnreadMessages != newUnreadStatus) {
        print("Provider: updating _hasUnreadMessages to $newUnreadStatus");
        _hasUnreadMessages = newUnreadStatus;
        notifyListeners();
      }
    });
  }

  void _listenToFinanceChatUpdates() {
    FirebaseFirestore.instance.collectionGroup('chats')
        .where('isReadByMunicipalUser', isEqualTo: false)
        .where('collectionType', isEqualTo: 'finance') // Adjust based on your finance chat field criteria
        .snapshots().listen((snapshot) {
      bool newUnreadFinanceStatus = snapshot.docs.isNotEmpty;
      if (_hasUnreadFinanceMessages != newUnreadFinanceStatus) {
        print("Provider: updating _hasUnreadFinanceMessages to $newUnreadFinanceStatus");
        _hasUnreadFinanceMessages = newUnreadFinanceStatus;
        notifyListeners();
      }
    });
  }

  void updateCouncillorUnreadMessages(String councillorPhone, bool hasUnread) {
    _councillorUnreadMessages[councillorPhone] = hasUnread;
    notifyListeners();
  }

  void updateRegularUnreadMessagesStatus(bool hasUnreadMessages) {
    if (_hasUnreadMessages != hasUnreadMessages) {
      _hasUnreadMessages = hasUnreadMessages;
      notifyListeners();
    }
  }

}
