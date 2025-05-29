import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaService {
  final ImagePicker _imagePicker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  MediaService();

  Future<File?> getImageFromGallery() async {
    final XFile? _file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (_file != null) return File(_file.path);
    return null;
  }

  /// Pick PDF file from device storage
  Future<File?> getPdfFromStorage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Error picking PDF file: $e');
      return null;
    }
  }

  /// Pick any document file (PDF, DOC, DOCX, etc.)
  Future<File?> getDocumentFromStorage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Error picking document file: $e');
      return null;
    }
  }


  Future<String> uploadImageToStorage(File image, String userId) async {
    try {
      // 1. Generate a unique cache-busting suffix
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${userId}_$timestamp${p.extension(image.path)}';
      final uniqueFilePath = 'users/$userId/$uniqueFileName';

      // 2. Upload the new image with unique filename
      await _supabase.storage
          .from('profile-images')
          .upload(
            uniqueFilePath,
            image,
            fileOptions: FileOptions(
              contentType:
                  'image/${p.extension(image.path).replaceFirst('.', '')}',
              upsert: true,
            ),
          );

      // 3. Get the public URL with cache-busting query parameter
      final imageUrl =
          '${_supabase.storage.from('profile-images').getPublicUrl(uniqueFilePath)}?t=$timestamp';

      // 4. Delete previous profile images for this user (optional cleanup)
      try {
        final existingFiles = await _supabase.storage
            .from('profile-images')
            .list(path: 'users/$userId/');

        for (var file in existingFiles) {
          if (file.name.startsWith('${userId}_') &&
              file.name != uniqueFileName) {
            await _supabase.storage.from('profile-images').remove([
              'users/$userId/${file.name}',
            ]);
          }
        }
      } catch (e) {
        print('Error cleaning old images: $e');
      }

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload chat image to Supabase Storage
  Future<String?> uploadImageToStorageFromChatUpload({
    required File file,
    required String chatId,
  }) async {
    try {
      final String fileName =
          '${DateTime.now().toIso8601String()}${p.extension(file.path)}';
      final String filePath = '$chatId/$fileName';

      // Upload file to the 'chat-uploads' bucket
      await _supabase.storage.from('chat-uploads').upload(filePath, file);

      // Get the public URL
      final String publicUrl = _supabase.storage
          .from('chat-uploads')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading chat image: $e');
      return null;
    }
  }

  /// Upload PDF file to Supabase Storage for chat
  Future<String?> uploadPdfToStorageFromChatUpload({
    required File file,
    required String chatId,
  }) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String originalName = p.basenameWithoutExtension(file.path);
      final String fileName = '${originalName}_$timestamp.pdf';
      final String filePath = '$chatId/pdf-uploads/$fileName';

      // Upload PDF file to the 'chat-uploads' bucket under pdf-uploads folder
      await _supabase.storage
          .from('chat-uploads')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );

      // Get the public URL
      final String publicUrl = _supabase.storage
          .from('chat-uploads')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading PDF file: $e');
      return null;
    }
  }

  /// Upload any document file to Supabase Storage for chat
  Future<String?> uploadDocumentToStorageFromChatUpload({
    required File file,
    required String chatId,
  }) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = p.extension(file.path);
      final String originalName = p.basenameWithoutExtension(file.path);
      final String fileName = '${originalName}_$timestamp$extension';
      final String filePath = '$chatId/pdf-uploads/$fileName';

      // Determine content type based on file extension
      String contentType;
      switch (extension.toLowerCase()) {
        case '.pdf':
          contentType = 'application/pdf';
          break;
        case '.doc':
          contentType = 'application/msword';
          break;
        case '.docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case '.txt':
          contentType = 'text/plain';
          break;
        case '.rtf':
          contentType = 'application/rtf';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      // Upload document file to the 'chat-uploads' bucket under pdf-uploads folder
      await _supabase.storage
          .from('chat-uploads')
          .upload(
            filePath,
            file,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      // Get the public URL
      final String publicUrl = _supabase.storage
          .from('chat-uploads')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading document file: $e');
      return null;
    }
  }

  /// Get file name from file path (useful for displaying file names in chat)
  String getFileName(String filePath) {
    return p.basename(filePath);
  }

  /// Get file extension from file path
  String getFileExtension(String filePath) {
    return p.extension(filePath);
  }

  /// Check if file is a PDF
  bool isPdfFile(String filePath) {
    return p.extension(filePath).toLowerCase() == '.pdf';
  }

  /// Check if file is an image
  bool isImageFile(String filePath) {
    final extension = p.extension(filePath).toLowerCase();
    return [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
    ].contains(extension);
  }

  /// Check if file is a document
  bool isDocumentFile(String filePath) {
    final extension = p.extension(filePath).toLowerCase();
    return ['.pdf', '.doc', '.docx', '.txt', '.rtf'].contains(extension);
  }

}
