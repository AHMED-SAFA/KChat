import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
}
