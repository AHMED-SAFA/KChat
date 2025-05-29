import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/cloud_service.dart';
import '../services/bot_service.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
final groqApiKey = dotenv.env['GROQ_API_KEY'];


enum AIModel {
  gemini('Gemini AI', 'gemini-1.5-flash-latest', Icons.auto_awesome, [
    Color(0xFF0F2027),
    Color(0xFF203A43),
    Color(0xFF2C5364),
  ]),
  groq('Groq AI', 'llama3-8b-8192', Icons.psychology,
      [Color(0xFF1a1a2e), Color(0xFF0f3460)]);

  const AIModel(this.displayName, this.modelId, this.icon, this.colors);
  final String displayName;
  final String modelId;
  final IconData icon;
  final List<Color> colors;
}

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> with TickerProviderStateMixin {
  ChatUser? myself;
  late ChatUser bot;
  List<ChatMessage> allMessages = [];
  List<ChatUser> typing = [];
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late CloudService _cloudService;
  late BotService _botService;
  late String _loggedInUserId;
  Map<String, dynamic>? _loggedInUserData;
  late AnimationController _animationController;
  bool _isLoadingMessages = true;

  // Model selection
  AIModel _selectedModel = AIModel.gemini;
  List<PlatformFile> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();

    _authService = _getIt.get<AuthService>();
    _cloudService = _getIt.get<CloudService>();
    _botService = _getIt.get<BotService>();
    _loggedInUserId = _authService.user!.uid;

    _initializeBot();
    _fetchLoggedInUserData();
  }

  void _initializeBot() {
    bot = ChatUser(
      id: _selectedModel.modelId,
      firstName: _selectedModel.displayName,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLoggedInUserData() async {
    _loggedInUserData =
        await _cloudService.fetchLoggedInUserData(userId: _loggedInUserId);
    setState(() {
      myself = ChatUser(
        id: _loggedInUserId,
        firstName: _loggedInUserData?['name'],
      );
    });
    await _loadPreviousMessages();
  }

  Future<void> _loadPreviousMessages() async {
    try {
      setState(() {
        _isLoadingMessages = true;
      });

      // Use the enhanced BotService method with model filtering
      List<Map<String, dynamic>> savedMessages =
          await _botService.getBotChatMessages(
        userId: _loggedInUserId,
        model: _selectedModel.modelId,
      );

      List<ChatMessage> chatMessages = savedMessages.map((msg) {
        return ChatMessage(
          user: ChatUser(
            id: msg['user']['id'],
            firstName: msg['user']['firstName'],
          ),
          createdAt: msg['createdAt'] != null
              ? (msg['createdAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(
                  msg['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
          text: msg['text'],
          customProperties: {
            'docId': msg['id'],
            'model': msg['model'],
            'attachments': msg['attachments'] ?? [],
          },
        );
      }).toList();

      setState(() {
        allMessages = chatMessages;
        _isLoadingMessages = false;
      });
    } catch (e) {
      print('Error loading previous messages: $e');
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _onModelChanged(AIModel? newModel) async {
    if (newModel != null && newModel != _selectedModel) {
      setState(() {
        _selectedModel = newModel;
        _isLoadingMessages = true;
        _attachedFiles.clear();
      });
      _initializeBot();
      await _loadPreviousMessages();
    }
  }

  Future<String?> _saveMessage(ChatMessage message,
      {bool isFromUser = true}) async {
    try {
      Map<String, dynamic> messageData = {
        'text': message.text,
        'user': {
          'id': message.user.id,
          'firstName': message.user.firstName,
        },
        'isFromUser': isFromUser,
        'model': _selectedModel.modelId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'attachments': message.customProperties?['attachments'] ?? [],
      };

      String docId = await _botService.saveBotChatMessageToSubcollection(
        userId: _loggedInUserId,
        messageData: messageData,
      );
      return docId;
    } catch (e) {
      print('Error saving message: $e');
      return null;
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      String? docId = message.customProperties?['docId'];
      if (docId != null) {
        await _botService.deleteSpecificMessage(
          userId: _loggedInUserId,
          docId: docId,
        );

        setState(() {
          allMessages
              .removeWhere((msg) => msg.customProperties?['docId'] == docId);
        });

        _showSnackBar('Message deleted successfully', Colors.green);
      }
    } catch (e) {
      print('Error deleting message: $e');
      _showSnackBar('Failed to delete message', Colors.red);
    }
  }

  void _showDeleteDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMessage(message);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendMessage(ChatMessage message) async {
    typing.add(bot);
    allMessages.insert(0, message);
    setState(() {});

    // Add uploaded files to message
    ChatMessage messageWithFiles = ChatMessage(
      user: message.user,
      createdAt: message.createdAt,
      text: message.text,
    );

    // Save user message
    String? userDocId = await _saveMessage(messageWithFiles, isFromUser: true);
    if (userDocId != null) {
      setState(() {
        allMessages[0] = ChatMessage(
          user: messageWithFiles.user,
          createdAt: messageWithFiles.createdAt,
          text: messageWithFiles.text,
          customProperties: {
            'docId': userDocId,
            'model': _selectedModel.modelId,
          },
        );
      });
    }

    // Send to AI based on selected model
    try {
      String? response = await _sendToAI(message.text);
      if (response != null) {
        ChatMessage botMessage = ChatMessage(
          user: bot,
          createdAt: DateTime.now(),
          text: response,
        );
        allMessages.insert(0, botMessage);

        // Save bot message
        String? botDocId = await _saveMessage(botMessage, isFromUser: false);
        if (botDocId != null) {
          setState(() {
            allMessages[0] = ChatMessage(
              user: botMessage.user,
              createdAt: botMessage.createdAt,
              text: botMessage.text,
              customProperties: {
                'docId': botDocId,
                'model': _selectedModel.modelId, // Add model info
              },
            );
          });
        }
      }
    } catch (e) {
      print('Error sending to AI: $e');
      ChatMessage errorMessage = ChatMessage(
        user: bot,
        createdAt: DateTime.now(),
        text:
            "Sorry, I'm experiencing technical difficulties. Please try again later.",
      );
      allMessages.insert(0, errorMessage);
    }

    // Clear attached files
    setState(() {
      _attachedFiles.clear();
    });

    typing.remove(bot);
    setState(() {});
  }

  Future<String?> _sendToAI(String text) async {
    switch (_selectedModel) {
      case AIModel.gemini:
        return await _sendToGemini(text);
      case AIModel.groq:
        return await _sendToGroq(text);
    }
  }

  Future<String?> _sendToGemini(String text) async {
    final headers = {'Content-Type': 'application/json'};
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$geminiApiKey";

    // Construct parts array with text and files
    List<Map<String, dynamic>> parts = [
      {"text": text}
    ];

    var data = {
      "contents": [
        {"parts": parts}
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        return result["candidates"][0]["content"]["parts"][0]["text"];
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Gemini API Error: $e');
    }
    return null;
  }

  Future<String?> _sendToGroq(String text) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $groqApiKey',
    };
    final url = "https://api.groq.com/openai/v1/chat/completions";

    String messageText = text;

    var data = {
      "messages": [
        {"role": "user", "content": messageText}
      ],
      "model": "llama3-8b-8192",
      "temperature": 0.7,
      "max_tokens": 1024,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        return result["choices"][0]["message"]["content"];
      } else {
        print('Groq API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Groq API Error: $e');
    }
    return null;
  }

  Future<void> _clearAllMessages() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Messages'),
          content: Text(
              'Are you sure you want to delete all ${_selectedModel.displayName} messages? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Use enhanced service method to delete by model
                  await _botService.deleteAllBotChatMessages(
                    userId: _loggedInUserId,
                    model: _selectedModel.modelId,
                  );

                  setState(() {
                    allMessages.clear();
                  });
                  _showSnackBar(
                      'All ${_selectedModel.displayName} messages cleared successfully',
                      Colors.green);
                } catch (e) {
                  _showSnackBar('Failed to clear messages', Colors.red);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _selectedModel.colors,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AIModel>(
                  value: _selectedModel,
                  onChanged: _onModelChanged,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  dropdownColor: _selectedModel.colors.first,
                  items: AIModel.values.map((model) {
                    return DropdownMenuItem<AIModel>(
                      value: model,
                      child: Row(
                        children: [
                          Icon(model.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            model.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _clearAllMessages,
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: 'Clear all messages',
          ),
          IconButton(
            onPressed: _loadPreviousMessages,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh messages',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ..._selectedModel.colors,
              _selectedModel.colors.last.withOpacity(0.8)
            ],
          ),
        ),
        child: myself == null || _isLoadingMessages
            ? Center(
                child: FadeTransition(
                  opacity: _animationController,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isLoadingMessages
                            ? 'Loading chat history...'
                            : 'Initializing ${_selectedModel.displayName}...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        top: _attachedFiles.isNotEmpty ? 8 : 100,
                        left: 0,
                        right: 0,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: DashChat(
                          messageOptions: MessageOptions(
                            showTime: true,
                            textColor: const Color(0xFF2D3748),
                            containerColor: const Color(0xFFF7FAFC),
                            currentUserTimeTextColor:
                                _selectedModel.colors.first,
                            timeTextColor: const Color(0xFF718096),
                            currentUserTextColor: Colors.white,
                            currentUserContainerColor:
                                _selectedModel.colors.first,
                            messagePadding: const EdgeInsets.all(12),
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                            borderRadius: 20,
                            messageTextBuilder:
                                (message, previousMessage, nextMessage) {
                              return Text(
                                message.text,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: message.user.id == myself?.id
                                      ? Colors.white
                                      : const Color(0xFF2D3748),
                                ),
                              );
                            },
                            onLongPressMessage: (ChatMessage message) {
                              _showDeleteDialog(message);
                            },
                          ),
                          inputOptions: InputOptions(
                            inputDecoration: InputDecoration(
                              hintText:
                                  "Ask ${_selectedModel.displayName} anything...",
                              hintStyle: const TextStyle(
                                color: Colors.black54,
                                fontSize: 15,
                              ),
                              filled: true,
                              fillColor:
                                  _selectedModel.colors.first.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            sendButtonBuilder: (onSend) {
                              return Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: FloatingActionButton(
                                  onPressed: onSend,
                                  backgroundColor: _selectedModel.colors.first,
                                  mini: true,
                                  elevation: 2,
                                  child: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                            inputToolbarPadding: const EdgeInsets.all(16),
                          ),
                          typingUsers: typing,
                          currentUser: myself!,
                          onSend: _sendMessage,
                          messages: allMessages,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
