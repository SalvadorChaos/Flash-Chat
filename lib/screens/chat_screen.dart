import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/constants.dart';
import 'package:flutter/material.dart';

import 'welcome_screen.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_Screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

//  void getMessages() async {
//    final messages = await _firestore.collection('messages').getDocuments();
//    for (var message in messages.documents) {
//      print(message.data);
//    }
//  }

//  void messageStream() async {
//    await for (var snapshot in _firestore.collection('messages').snapshots()) {
//      for (var message in snapshot.documents) {
//        print(message.data);
//      }
//    }
//  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                _auth.signOut();
                Navigator.popUntil(
                  context,
                  ModalRoute.withName(WelcomeScreen.id),
                );
              }),
        ],
        title: Center(
          child: Text('⚡️Chat'),
        ),
        backgroundColor: Colors.black,
        brightness: Brightness.dark,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //Implement send functionality.
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'name': loggedInUser.displayName != null
                            ? loggedInUser.displayName
                            : loggedInUser.email,
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'timestamp': DateTime.now().toIso8601String(),
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore.collection('messages').orderBy('timestamp').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.yellowAccent,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.deepOrangeAccent),
            ),
          );
        } else {
          final messages = snapshot.data.documents.reversed;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages) {
            final senderName = message.data['name'];
            final messageText = message.data['text'];
            final messageSender = message.data['sender'];

            final currentUser = loggedInUser.email;

            if (currentUser == messageSender) {
              //The message from the logged in user.
            }

            final messageBubble = MessageBubble(
              text: messageText,
              sender: senderName,
              isMe: currentUser == messageSender,
            );
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              children: messageBubbles,
              padding: EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 20.0,
              ),
            ),
          );
        }
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.text, this.sender, this.isMe});
  final String text;
  final String sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.0,
            ),
          ),
          Material(
            borderRadius: BorderRadius.only(
              topLeft: isMe ? Radius.circular(30.0) : Radius.circular(0.0),
              topRight: isMe ? Radius.circular(0.0) : Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
            ),
            color: isMe ? Colors.orangeAccent : Colors.yellow,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15.0,
                ),
              ),
            ),
            elevation: 6.0,
          ),
        ],
      ),
    );
  }
}
