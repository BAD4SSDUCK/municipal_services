import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {

  static final NotificationProvider _instance = NotificationProvider._internal();
  bool _hasUnreadMessages = false;
  bool _hasUnreadFinanceMessages = false;
  bool _hasUnreadNotices = false;
  bool _hasUnreadCouncillorMessages = false;

  bool get hasUnreadMessages => _hasUnreadMessages;
  bool get hasUnreadFinanceMessages => _hasUnreadFinanceMessages;
  bool get hasUnreadNotices => _hasUnreadNotices;
  bool get hasUnreadCouncillorMessages => _hasUnreadCouncillorMessages;

  // Getter for unread notices
  factory NotificationProvider() => _instance;

  NotificationProvider._internal() {

    _listenToRegularChatUpdates();
    _listenToFinanceChatUpdates();
    _listenToNoticesUpdates();
    _listenToCouncillorChatUpdates();
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

  void updateRegularUnreadMessagesStatus(bool hasUnreadMessages) {
    if (_hasUnreadMessages != hasUnreadMessages) {
      _hasUnreadMessages = hasUnreadMessages;
      notifyListeners();
    }
  }

  void _listenToCouncillorChatUpdates() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("Error: No authenticated user found.");
      return;
    }

    String userPhone = currentUser.phoneNumber ?? '';
    bool isCouncillor = await _checkIfUserIsCouncillor(userPhone);

    FirebaseFirestore.instance
        .collectionGroup('chatRoomCouncillor')
        .snapshots()
        .listen((snapshot) async {
      print('Listening to councillor chats for updates...');

      bool newUnreadCouncillorStatus = false;

      for (var councillorDoc in snapshot.docs) {
        QuerySnapshot userChatsSnapshot =
        await councillorDoc.reference.collection('userChats').get();

        for (var userChatDoc in userChatsSnapshot.docs) {
          QuerySnapshot unreadMessages = await userChatDoc.reference
              .collection('messages')
              .where(isCouncillor ? 'isReadByCouncillor' : 'isReadByUser',
              isEqualTo: false)
              .get();

          if (unreadMessages.docs.isNotEmpty) {
            newUnreadCouncillorStatus = true;

            print(
                'Unread Messages Found: ${unreadMessages.docs.length} for User: ${userChatDoc.id}');
            break;
          }
        }

        if (newUnreadCouncillorStatus) break;
      }

      // Update the state if the unread status changes
      if (_hasUnreadCouncillorMessages != newUnreadCouncillorStatus) {
        print("Provider: updating _hasUnreadCouncillorMessages to $newUnreadCouncillorStatus");
        _hasUnreadCouncillorMessages = newUnreadCouncillorStatus;
        notifyListeners();
      }
    });
  }


  /// Checks if the current user is a councillor
  Future<bool> _checkIfUserIsCouncillor(String phoneNumber) async {
    try {
      QuerySnapshot councillorCheck = await FirebaseFirestore.instance
          .collectionGroup('councillors')
          .where('councillorPhone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      return councillorCheck.docs.isNotEmpty;
    } catch (e) {
      print("Error checking if user is a councillor: $e");
      return false;
    }
  }


  void updateCouncillorUnreadMessagesStatus(bool hasUnread) {
    if (_hasUnreadCouncillorMessages != hasUnread) {
      _hasUnreadCouncillorMessages = hasUnread;
      notifyListeners();
    }
  }
}
