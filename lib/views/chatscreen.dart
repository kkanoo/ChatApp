import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/helperfunctions/sharedpref_helper.dart';
import 'package:messenger_clone/services/database.dart';
import 'package:random_string/random_string.dart';

class ChatScreen extends StatefulWidget {
  final String chatWithUserName, name;
  ChatScreen(this.chatWithUserName, this.name);
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? chatRoomId, messageId = "";
  String? myName, myProfilePic, myUserName, myEmail;
  TextEditingController messageTextEditingController = TextEditingController();
  Stream? messageStream;

  getMyInfoFromSharedPreference() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();
  }

  getChatRoomId() async {
    chatRoomId =
        await getChatRoomIdByUserNames(widget.chatWithUserName, myUserName);
  }

  Future<String?> getChatRoomIdByUserNames(String? a, String? b) async {
    if (a!.length > b!.length) {
      return "$a\'$b";
    } else if (b.length > a.length) {
      return "$b\'$a";
    } else {
      if (await DatabaseMethods().checkChatRoomId("$a\'$b")) {
        return "$a\'$b";
      } else
        return "$b\'$a";
    }
  }

  addMessage(bool sendClicked) {
    if (messageTextEditingController.text != "") {
      String message = messageTextEditingController.text;

      var lastMessageTs = DateTime.now();

      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy": myUserName,
        "ts": lastMessageTs,
        "imageUrl": myProfilePic,
      };

      //messageID
      if (messageId == "") {
        messageId = randomAlphaNumeric(12);
      }

      DatabaseMethods()
          .addMessage(chatRoomId, messageId, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastmessage": message,
          "lastMessageSendTs": lastMessageTs,
          "lastMessageSendBy": myUserName,
        };

        DatabaseMethods().updateLastMessageSend(chatRoomId, lastMessageInfoMap);

        if (sendClicked) {
          //remove the text in the message input field
          messageTextEditingController.text = "";

          //make message id blank to get regenrated on next message send
          messageId = "";
          setState(() {});
        }
      });
    }
  }

  Widget chatMessages() {
    return StreamBuilder<dynamic>(
      stream: messageStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return snapshot.hasData
            ? ListView.builder(
                padding: EdgeInsets.only(
                  bottom: 70,
                  top: 16,
                ),
                itemCount: snapshot.data.docs.length,
                reverse: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return chatMessageTile(
                      ds["message"], myUserName == ds["sendBy"]);
                })
            : Center(
                child: CircularProgressIndicator(),
              );
      },
    );
  }

  Widget chatMessageTile(String message, bool sendByMe) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment:
              sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomRight:
                        sendByMe ? Radius.circular(0) : Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomLeft:
                        sendByMe ? Radius.circular(24) : Radius.circular(0),
                  ),
                  color: sendByMe ? Colors.blue : Colors.blueGrey,
                ),
                //width: 270,
                margin: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                padding: EdgeInsets.all(16),
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  getAndSetMessages() async {
    setState(() {});
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomId);
    setState(() {});
  }

  doThisOnLaunch() async {
    await getMyInfoFromSharedPreference();
    await getChatRoomId();
    await getAndSetMessages();
  }

  @override
  void initState() {
    doThisOnLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            chatMessages(),
            Container(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black.withOpacity(
                  0.8,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      controller: messageTextEditingController,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Type a message",
                        hintStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      addMessage(true);
                    },
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
