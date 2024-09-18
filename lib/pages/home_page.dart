import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];

  final ChatUser currentUser = ChatUser(
      id: '0', firstName: "User", profileImage: "https://images.seeklogo.com/logo-png/55/1/divertida-mente-nojinho-logo-png_seeklogo-551767.png");

  final ChatUser geminiUser = ChatUser(
      id: '1',
      firstName: "Gemini",
      profileImage: "https://images.seeklogo.com/logo-png/53/1/wi-max-fantasma-fantasminha-logo-png_seeklogo-533227.png?v=638622595440000000");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevRuler Chat App'),
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return DashChat(
        inputOptions: InputOptions(trailing: [
          IconButton(
            onPressed: _sendMediaMessage,
            icon: const Icon(Icons.image),
          ),
        ]),
        currentUser: currentUser,
        onSend: _sendMessage,
        messages: messages);
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      String question = chatMessage.text;
      List<Uint8List>? images;

      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(), // Convert the image to bytes
        ];
      }

      gemini.streamGenerateContent(question, images: images).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user.id == geminiUser.id) {
          String response = event.content?.parts?.fold("", (previousValue, current) => "$previousValue ${current.text}") ?? "";
          lastMessage = messages.removeAt(0);

          lastMessage.text = response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          String response = event.content?.parts?.fold("", (previousValue, current) => "$previousValue ${current.text}") ?? "";
          ChatMessage message = ChatMessage(user: geminiUser, createdAt: DateTime.now(), text: response);

          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {
      log(e.toString());
    }
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Fotoğrafı açıklayabilir misin?",
        medias: [
          ChatMedia(url: file.path, fileName: "", type: MediaType.image),
        ],
      );

      _sendMessage(chatMessage);
    }
  }
}
