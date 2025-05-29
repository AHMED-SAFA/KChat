import 'dart:io';
import 'dart:async';
import 'package:kchat/models/message.dart';
import 'package:kchat/services/activeUser_service.dart';
import 'package:kchat/services/auth_service.dart';
import 'package:kchat/services/chat_service.dart';
import 'package:kchat/services/media_service.dart';
import 'package:kchat/services/notification_service.dart';
import 'package:kchat/services/cloud_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'pdf_view_page.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final String loggedInUserName;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    required this.loggedInUserName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late AuthService _authService;
  late ChatService _chatService;
  late NotificationService _notificationService;
  late ActiveUserService _activeUserService;
  late MediaService _mediaService;
  late CloudService _cloudService;
  final GetIt _getIt = GetIt.instance;
  ChatUser? currentUser, otherUser;
  List<ChatMessage> messages = [];
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isUploading = false;
  bool _isOtherUserOnline = false;
  String _otherUserProfileImage = '';
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _chatService = _getIt.get<ChatService>();
    _activeUserService = _getIt.get<ActiveUserService>();
    _mediaService = _getIt.get<MediaService>();
    _notificationService = _getIt.get<NotificationService>();
    _cloudService = _getIt.get<CloudService>();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    currentUser = ChatUser(
      id: _authService.user!.uid,
      firstName: widget.loggedInUserName,
    );
    otherUser = ChatUser(
      id: widget.otherUserId,
      firstName: widget.otherUserName,
    );

    _getMessages();
    _loadOtherUserData();
    _startStatusPolling();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOtherUserData() async {
    try {
      Map<String, dynamic>? userData = await _cloudService
          .fetchLoggedInUserData(userId: widget.otherUserId);

      if (userData != null) {
        setState(() {
          _otherUserProfileImage = userData['profileImageUrl'] ?? '';
          _isOtherUserOnline = userData['ActiveStatus'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading other user data: $e');
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadOtherUserData();
    });
  }

  Future<void> _getMessages() async {
    _chatService.getMessages(widget.chatId).listen((QuerySnapshot snapshot) {
      List<ChatMessage> loadedMessages = snapshot.docs.map((doc) {
        Message message = Message.fromJson(doc.data() as Map<String, dynamic>);

        if (message.messageType == MessageType.Text) {
          return ChatMessage(
            user: message.senderID == widget.currentUserId
                ? currentUser!
                : otherUser!,
            text: message.content!,
            createdAt: message.sentAt!.toDate(),
          );
        } else if (message.messageType == MessageType.Document) {
          return ChatMessage(
            user: message.senderID == widget.currentUserId
                ? currentUser!
                : otherUser!,
            medias: [
              ChatMedia(
                url: message.content!,
                fileName: message.fileName ?? "Document",
                type: MediaType.file,
              ),
            ],
            createdAt: message.sentAt!.toDate(),
          );
        } else {
          return ChatMessage(
            user: message.senderID == widget.currentUserId
                ? currentUser!
                : otherUser!,
            medias: [
              ChatMedia(
                url: message.content!,
                fileName: "",
                type: MediaType.image,
              ),
            ],
            createdAt: message.sentAt!.toDate(),
          );
        }
      }).toList();

      setState(() {
        messages = loadedMessages;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
        ),
        child: DashChat(
          currentUser: currentUser!,
          messages: messages,
          onSend: _sendMessage,
          messageOptions: MessageOptions(
            showOtherUsersAvatar: true,
            showCurrentUserAvatar: false,
            avatarBuilder: _customAvatarBuilder,
            messageDecorationBuilder: _messageDecorationBuilder,
            messageMediaBuilder: _customMediaBuilder,
            containerColor: Colors.transparent,
            textColor: Colors.black87,
            currentUserContainerColor: const Color(0xFF007AFF),
            currentUserTextColor: Colors.white,
            messagePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            messageTimeBuilder: _customTimeBuilder,
            messageTextBuilder: (message, previousMessage, nextMessage) {
              return SelectableText(
                message.text ?? '',
                style: TextStyle(
                  color: message.user.id == currentUser?.id
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 14,
                ),
              );
            },
          ),
          inputOptions: InputOptions(
            inputDecoration: InputDecoration(
              hintText: "Type a message...",
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              suffixIcon: _isUploading
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            trailing: [
              AnimatedBuilder(
                animation: _fabAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _fabAnimation.value,
                    child: _mediaMessageButton(),
                  );
                },
              ),
            ],
            inputToolbarPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isOtherUserOnline ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: _otherUserProfileImage.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: _otherUserProfileImage,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.otherUserName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.otherUserName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.otherUserName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOtherUserOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOtherUserOnline ? "Online" : "Offline",
                      style: TextStyle(
                        fontSize: 12,
                        color: _isOtherUserOnline ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, size: 20),
                  SizedBox(width: 12),
                  Text('Clear Chat'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _customAvatarBuilder(
    ChatUser user,
    Function? onAvatarTap,
    Function? onAvatarLongPress,
  ) {
    bool isOtherUser = user.id == widget.otherUserId;

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isOtherUser && _isOtherUserOnline
              ? Colors.green
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: isOtherUser && _otherUserProfileImage.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: _otherUserProfileImage,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user.firstName?[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user.firstName?[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                ),
              ),
              child: Center(
                child: Text(
                  user.firstName?[0].toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
    );
  }

  BoxDecoration _messageDecorationBuilder(
    ChatMessage message,
    ChatMessage? previousMessage,
    ChatMessage? nextMessage,
  ) {
    bool isCurrentUser = message.user.id == currentUser!.id;

    return BoxDecoration(
      color: isCurrentUser ? const Color(0xFF007AFF) : Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
        bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _customMediaBuilder(
    ChatMessage message,
    ChatMessage? previousMessage,
    ChatMessage? nextMessage,
  ) {
    if (message.medias?.isNotEmpty ?? false) {
      final media = message.medias!.first;

      // Check if it's a PDF file
      if (media.type == MediaType.file &&
          media.fileName.toLowerCase().endsWith('.pdf')) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: GestureDetector(
            onTap: () => _openPDF(media.url, media.fileName),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[900]!, Colors.grey[850]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[600]!.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange[600]!.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.orange[500],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          media.fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PDF',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800]!.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.grey[300],
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Handle regular images
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onTap: () => _showImageDialog(media.url),
            child: Hero(
              tag: media.url,
              child: CachedNetworkImage(
                imageUrl: media.url,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.error, size: 40, color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _openPDF(String pdfUrl, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerPage(pdfUrl: pdfUrl, fileName: fileName),
      ),
    );
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    Message? message;

    if (chatMessage.medias?.isNotEmpty ?? false) {
      final media = chatMessage.medias!.first;
      if (media.type == MediaType.image) {
        message = Message(
          senderID: currentUser!.id,
          senderName: widget.loggedInUserName,
          content: media.url,
          messageType: MessageType.Image,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
        );
      } else if (media.type == MediaType.file) {
        message = Message(
          senderID: currentUser!.id,
          senderName: widget.loggedInUserName,
          content: media.url,
          fileName: media.fileName,
          messageType: MessageType.Document,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
        );
      }
    } else {
      message = Message(
        senderID: currentUser!.id,
        senderName: widget.loggedInUserName,
        content: chatMessage.text,
        messageType: MessageType.Text,
        sentAt: Timestamp.fromDate(chatMessage.createdAt),
      );
    }

    if (message != null) {
      await _chatService.addMessage(chatId: widget.chatId, message: message);

      // Check if the other user is active
      bool isOtherUserActive = await _activeUserService.getActiveUsersStatus(
        userID: widget.otherUserId,
      );

      // Store notification only if the user is inactive
      if (!isOtherUserActive) {
        await _notificationService.storeNotificationForMessage(
          chatId: widget.chatId,
          loggedInUserId: widget.currentUserId,
          loggedInUserName: widget.loggedInUserName,
          receiverId: widget.otherUserId,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to create message. Please try again."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Update your _mediaMessageButton to show options for image and PDF:
  Widget _mediaMessageButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'image') {
            _selectAndUploadImage();
          } else if (value == 'pdf') {
            _selectAndUploadPDF();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'image',
            child: Row(
              children: [
                Icon(Icons.photo_camera, size: 20),
                SizedBox(width: 12),
                Text('Image'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'pdf',
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, size: 20),
                SizedBox(width: 12),
                Text('PDF Document'),
              ],
            ),
          ),
        ],
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF007AFF),
            shape: BoxShape.circle,
          ),
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.attach_file, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  // Add this method to handle PDF selection and upload:
  Future<void> _selectAndUploadPDF() async {
    setState(() {
      _isUploading = true;
    });

    try {
      File? file = await _mediaService.getPdfFromStorage();
      if (file != null) {
        String? downloadPdfUrl = await _mediaService
            .uploadPdfToStorageFromChatUpload(
              file: file,
              chatId: widget.chatId,
            );

        if (downloadPdfUrl != null) {
          String fileName = _mediaService.getFileName(file.path);

          ChatMessage chatMessage = ChatMessage(
            user: currentUser!,
            createdAt: DateTime.now(),
            medias: [
              ChatMedia(
                url: downloadPdfUrl,
                fileName: fileName,
                type: MediaType.file,
              ),
            ],
          );
          await _sendMessage(chatMessage);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to upload PDF: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _customTimeBuilder(ChatMessage message, bool isNextMessageSameAuthor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        "${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}",
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: imageUrl,
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    minScale: 0.5,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.error, size: 60, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectAndUploadImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      File? file = await _mediaService.getImageFromGallery();
      if (file != null) {
        String? downloadImgUrl = await _mediaService
            .uploadImageToStorageFromChatUpload(
              file: file,
              chatId: widget.chatId,
            );

        if (downloadImgUrl != null) {
          ChatMessage chatMessage = ChatMessage(
            user: currentUser!,
            createdAt: DateTime.now(),
            medias: [
              ChatMedia(
                url: downloadImgUrl,
                fileName: "",
                type: MediaType.image,
              ),
            ],
          );
          await _sendMessage(chatMessage);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to upload image: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
