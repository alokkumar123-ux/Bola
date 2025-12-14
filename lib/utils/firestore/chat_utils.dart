import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/conversation_admin_model.dart';
import 'package:poolmate/model/inbox_admin_model.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';

class ChatUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static late StreamSubscription<QuerySnapshot> adminChatSeenSubscription;

  static void setSeen() {
    final currentUserId = AuthUtils.getCurrentUid();

    adminChatSeenSubscription = FirebaseFirestore.instance
        .collection(CollectionName.adminChat)
        .doc(currentUserId)
        .collection("thread")
        .where('senderId', isEqualTo: Constant.adminType)
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((querySnapshot) async {
      for (final doc in querySnapshot.docs) {
        try {
          await doc.reference.update({'seen': true});
        } catch (e) {
          print(e.toString());
        }
      }
    }, onError: (error) {
      print(error.toString());
    });
  }

  static void stopSeenListener() {
    adminChatSeenSubscription.cancel();
  }

  static Future addInAdminBox(InboxAdminModel inboxModel) async {
    return await fireStore
        .collection(CollectionName.adminChat)
        .doc(AuthUtils.getCurrentUid())
        .set(inboxModel.toJson())
        .then((document) {
      return inboxModel;
    });
  }

  static Future addAdminChat(ConversationAdminModel conversationModel) async {
    return await fireStore
        .collection(CollectionName.adminChat)
        .doc(conversationModel.senderId)
        .collection("thread")
        .doc(conversationModel.id)
        .set(conversationModel.toJson())
        .then((document) {
      return conversationModel;
    });
  }
}
