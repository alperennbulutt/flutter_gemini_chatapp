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
  final List<ChatMessage> _messages = [];

  final ChatUser _currentUser = ChatUser(
      id: '0', firstName: "User", profileImage: "https://images.seeklogo.com/logo-png/55/1/divertida-mente-nojinho-logo-png_seeklogo-551767.png");

  final ChatUser _geminiUser = ChatUser(
      id: '1',
      firstName: "Gemini",
      profileImage: "https://images.seeklogo.com/logo-png/53/1/wi-max-fantasma-fantasminha-logo-png_seeklogo-533227.png?v=638622595440000000");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevRuler Chat App'),
      ),
      body: DashChat(
        inputOptions: InputOptions(trailing: [
          IconButton(
            onPressed: _sendMediaMessage,
            icon: const Icon(Icons.image),
          ),
        ]),
        currentUser: _currentUser,
        onSend: _sendMessage,
        messages: _messages,
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      _messages.insert(0, chatMessage);
    });

    if (chatMessage.text.isNotEmpty || chatMessage.medias?.isNotEmpty == true) {
      _handleGeminiResponse(chatMessage);
    }
  }

  void _handleGeminiResponse(ChatMessage chatMessage) {
    try {
      String question = chatMessage.text;
      List<Uint8List>? images = _extractImageBytes(chatMessage.medias);

      gemini.streamGenerateContent(question, images: images).listen((event) {
        String response = event.content?.parts?.map((part) => part.text).join(" ") ?? "";

        if (_isLastMessageFromGemini()) {
          _updateLastMessage(response);
        } else {
          _addNewGeminiMessage(response);
        }
      });
    } catch (e) {
      log("Error in Gemini response: $e");
    }
  }

  List<Uint8List>? _extractImageBytes(List<ChatMedia>? medias) {
    if (medias?.isNotEmpty == true) {
      return [File(medias!.first.url).readAsBytesSync()];
    }
    return null;
  }

  bool _isLastMessageFromGemini() {
    return _messages.isNotEmpty && _messages.first.user.id == _geminiUser.id;
  }

  void _updateLastMessage(String response) {
    setState(() {
      _messages.first.text = response;
    });
  }

  void _addNewGeminiMessage(String response) {
    final geminiMessage = ChatMessage(
      user: _geminiUser,
      createdAt: DateTime.now(),
      text: response,
    );

    setState(() {
      _messages.insert(0, geminiMessage);
    });
  }

  void _sendMediaMessage() async {
    try {
      XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (file != null) {
        final mediaMessage = ChatMessage(
          user: _currentUser,
          createdAt: DateTime.now(),
          text: "Fotoğrafı açıklayabilir misin?",
          medias: [
            ChatMedia(url: file.path, fileName: "", type: MediaType.image),
          ],
        );

        _sendMessage(mediaMessage);
      }
    } catch (e) {
      log("Error selecting image: $e");
    }
  }
}
