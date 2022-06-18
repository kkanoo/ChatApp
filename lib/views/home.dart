import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/services/auth.dart';
import 'package:messenger_clone/services/database.dart';
import 'package:messenger_clone/views/chatscreen.dart';
import 'package:messenger_clone/views/signin.dart';
import 'package:messenger_clone/views/settings.dart';
import '../helperfunctions/sharedpref_helper.dart';

enum Menu { signOut, settings }

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isSearching = false;
  String? myName, myProfilePic, myUserName, myEmail;
  Stream? userStream, chatRoomsStream;
  TextEditingController searchusernameEditingController =
      TextEditingController();
  getMyInfoFromSharedPreference() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();
  }

  getChatRoomIdByUserNames(String? a, String? b) {
    if (a!.length > b!.length) {
      return "$a\'$b";
    } else {
      return "$b\'$a";
    }
  }

  onSearchBtnClick() async {
    isSearching = true;
    setState(() {});
    userStream = await DatabaseMethods()
        .getUserByUserName(searchusernameEditingController.text);

    setState(() {});
  }

  Widget searchListUserTile(
      {String? profileUrl, String? name, String? username, String? email}) {
    return GestureDetector(
      onTap: () {
        var chatRoomId1 = getChatRoomIdByUserNames(username, myUserName);
        var chatRoomId2 = getChatRoomIdByUserNames(myUserName, username);
        Map<String, dynamic> chatRoomInfoMap = {
          "users": [myUserName, username]
        };
        DatabaseMethods()
            .createChatRoom(chatRoomId1, chatRoomId2, chatRoomInfoMap);
        setState(() {});
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(username!, name!)),
        ).then((value) {
          setState(() {});
        });
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.network(
              profileUrl!,
              height: 30,
              width: 30,
            ),
          ),
          SizedBox(
            width: 12,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name!),
              Text(
                email!,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget searchUserList() {
    return StreamBuilder<dynamic>(
        stream: userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView.builder(
              itemCount: snapshot.data.docs.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                DocumentSnapshot ds = snapshot.data.docs[index];
                return searchListUserTile(
                    profileUrl: ds["imageUrl"],
                    name: ds["name"],
                    email: ds["email"],
                    username: ds["username"]);
              });
        });
  }

  Widget chatRoomList() {
    return StreamBuilder<dynamic>(
      stream: chatRoomsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return snapshot.hasData
            ? ListView.builder(
                itemCount: snapshot.data.docs.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  print(index);
                  print(ds.get("lastmessage"));
                  print("${ds["lastmessage"]!} ${ds.id}, ${myUserName!}");
                  return Column(
                    children: [
                      SizedBox(
                        height: 16,
                      ),
                      ChatRoomListTile(
                          ds["lastmessage"]!, ds.id, myUserName!, true)
                    ],
                  );
                })
            : Center(
                child: CircularProgressIndicator(),
              );
      },
    );
  }

  getChatRooms() async {
    setState(() {});
    chatRoomsStream = await DatabaseMethods().getChatRooms();
    setState(() {});
  }

  onScreenLoaded() async {
    await getMyInfoFromSharedPreference();
    await getChatRooms();
  }

  @override
  void initState() {
    onScreenLoaded();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[900],
        title: Text("Messenger"),
        actions: [
          PopupMenuButton<Menu>(
              onSelected: (Menu selectedValue) {
                if (selectedValue == Menu.signOut) {
                  AuthMethods().signOut().then((s) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignIn(),
                      ),
                    );
                  });
                } else {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Settings1()));
                }
              },
              itemBuilder: (_) => [
                    PopupMenuItem(
                      child: Text("Sign Out"),
                      value: Menu.signOut,
                    ),
                    PopupMenuItem(
                      child: Text("Settings"),
                      value: Menu.settings,
                    )
                  ])
        ],
      ),
      body: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Column(
          children: [
            Row(
              children: [
                isSearching
                    ? GestureDetector(
                        onTap: () {
                          isSearching = false;
                          searchusernameEditingController.text = "";
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                            right: 12,
                          ),
                          child: Icon(Icons.arrow_back),
                        ),
                      )
                    : Container(),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.0,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(
                        24,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchusernameEditingController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Username",
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (searchusernameEditingController.text != "") {
                              onSearchBtnClick();
                            }
                          },
                          child: Icon(
                            Icons.search,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            isSearching ? searchUserList() : chatRoomList(),
          ],
        ),
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  final String lastMessage, chatRoomId, myUsername;
  bool ischanged;
  ChatRoomListTile(
      this.lastMessage, this.chatRoomId, this.myUsername, this.ischanged);

  @override
  State<ChatRoomListTile> createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String? profilePicUrl = "", name = "", username = "";

  getThisUSerInfo() async {
    username = widget.chatRoomId
        .replaceAll(widget.myUsername, "")
        .replaceAll("\'", "");
    setState(() {});
    QuerySnapshot querySnapshot =
        await DatabaseMethods().getUserInfo(username!);
    print(
        "something ${querySnapshot.docs[0].id} ${querySnapshot.docs[0]["imageUrl"]} ${querySnapshot.docs[0]["name"]} ${widget.chatRoomId} ${username} ${widget.myUsername} ${widget.lastMessage}");
    name = "${querySnapshot.docs[0]["name"]}";
    profilePicUrl = "${querySnapshot.docs[0]["imageUrl"]}";
    setState(() {});
  }

  @override
  void initState() {
    getThisUSerInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ischanged) {
      getThisUSerInfo();
      widget.ischanged = false;
    }

    return GestureDetector(
      onTap: () {
        setState(() {});
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(username!, name!)),
        ).then((value) {
          setState(() {});
        });
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: profilePicUrl != ""
                ? Image.network(
                    profilePicUrl!,
                    height: 40,
                    width: 40,
                  )
                : Container(),
          ),
          SizedBox(
            width: 12,
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name!,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 3,
                ),
                Text(
                  widget.lastMessage,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
