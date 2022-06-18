import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messenger_clone/helperfunctions/sharedpref_helper.dart';

class DatabaseMethods {
  Future addUserInfoToDB(
      String? userId, Map<String, dynamic> userInfoMap) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .set(userInfoMap, SetOptions(merge: true));
  }

  Future<Stream<QuerySnapshot>> getUserByUserName(String username) async {
    return FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .snapshots();
  }

  updateUserDetails(String userId, Map<String, dynamic> userInfoMap) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .set(userInfoMap, SetOptions(merge: true));
  }

  Future addMessage(String? chatRoomId, String? messageId,
      Map<String, dynamic> messageInfoMap) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .set(messageInfoMap);
  }

  updateLastMessageSend(
      String? chatRoomId, Map<String, dynamic> lastMessageInfoMap) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .set(lastMessageInfoMap, SetOptions(merge: true));
  }

  createChatRoom(String chatRoomId1, String chatRoomId2,
      Map<String, dynamic> chatRoomInfoMap) async {
    final snapShot1 = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId1)
        .get();
    final snapShot2 = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId2)
        .get();

    if (snapShot1.exists || snapShot2.exists) {
      //chatroom already exists
      return true;
    } else {
      //chatroom does not exists so making new one
      return FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId1)
          .set(chatRoomInfoMap);
    }
  }

  checkChatRoomId(String? chatRoomId) async {
    final snapShot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();
    if (snapShot.exists) {
      return true;
    } else {
      return false;
    }
  }

  Future<Stream<QuerySnapshot>> getChatRoomMessages(chatRoomId) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("ts", descending: true)
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String? myUsername = await SharedPreferenceHelper().getUserName();
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .orderBy("lastMessageSendTs", descending: true)
        .where("users", arrayContains: myUsername)
        .snapshots();
  }

  Future<QuerySnapshot> getUserInfo(String? username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .get();
  }
}
