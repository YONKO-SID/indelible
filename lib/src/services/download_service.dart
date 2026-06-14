import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:flutter/material.dart';

/// Professional service for handling in-app file downloads and gallery saving.
class DownloadService {
  static final Dio _dio = Dio();

  /// Downloads a file from [url] and saves it to the device.
  /// [fileName] should include the extension.
  static Future<void> downloadAndSave(BuildContext context, String url, String fileName) async {
    try {
      // 1. Request Permissions
      if (Platform.isAndroid) {
        if (await Permission.storage.request().isDenied && 
            await Permission.manageExternalStorage.request().isDenied &&
            await Permission.photos.request().isDenied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permissions are required to download files.')),
            );
          }
          return;
        }
      }

      // 2. Show Progress SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Text('Downloading $fileName...'),
              ],
            ),
            duration: const Duration(days: 1), // Keep it open until finished
          ),
        );
      }

      // 3. Get Temporary Directory
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$fileName';

      // 4. Perform Download
      await _dio.download(url, savePath);

      // 5. Save to Gallery if it's an image or video
      bool savedToGallery = false;
      final ext = fileName.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
        await Gal.putImage(savePath);
        savedToGallery = true;
      } else if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
        await Gal.putVideo(savePath);
        savedToGallery = true;
      }

      // 6. Final UI feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: Text(savedToGallery 
              ? 'Successfully saved $fileName to Gallery!' 
              : 'Successfully downloaded $fileName to app storage!'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Download failed: ${e.toString()}'),
          ),
        );
      }
    }
  }
}
