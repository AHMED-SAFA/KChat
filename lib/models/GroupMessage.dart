import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupMessageType { text, image, file, system }

class GroupMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final GroupMessageType messageType;
  final String? imageUrl;
  final String? fileName;
  final int? fileSize;
  final Map<String, dynamic>? metadata;

  GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.messageType = GroupMessageType.text,
    this.imageUrl,
    this.fileName,
    this.fileSize,
    this.metadata,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
      'messageType': messageType.toString().split('.').last,
      'imageUrl': imageUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      sentAt: (json['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageType: _parseMessageType(json['messageType']),
      imageUrl: json['imageUrl'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      metadata: json['metadata'],
    );
  }

  static GroupMessageType _parseMessageType(String? type) {
    switch (type) {
      case 'text':
        return GroupMessageType.text;
      case 'image':
        return GroupMessageType.image;
      case 'file':
        return GroupMessageType.file;
      case 'system':
        return GroupMessageType.system;
      default:
        return GroupMessageType.text;
    }
  }

  // Create a copy with updated fields
  GroupMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? sentAt,
    GroupMessageType? messageType,
    String? imageUrl,
    String? fileName,
    int? fileSize,
    Map<String, dynamic>? metadata,
  }) {
    return GroupMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'GroupMessage(id: $id, senderId: $senderId, senderName: $senderName, content: $content, sentAt: $sentAt, messageType: $messageType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
