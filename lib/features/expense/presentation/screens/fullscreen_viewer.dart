import 'dart:io';
import 'package:expense_tracker/core/utils/snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FullScreenViewer extends StatefulWidget {
  final String pathOrUrl;
  final String? productName;

  const FullScreenViewer({
    super.key,
    required this.pathOrUrl,
    this.productName,
  });

  @override
  State<FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<FullScreenViewer> {
  String? localPath;
  String? mimeType;
  bool isLoading = true;
  bool hasError = false;

  bool get isNetwork => widget.pathOrUrl.startsWith("http");

  bool get isImage => mimeType?.startsWith("image") ?? false;

  bool get isPdf => mimeType == "application/pdf";

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  Future<void> _prepareFile() async {
    try {
      if (isNetwork) {
        final dir = await getTemporaryDirectory();
        final filePath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}";

        final response = await Dio().get(
          widget.pathOrUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        final file = File(filePath);
        await file.writeAsBytes(response.data);

        mimeType = response.headers.value("content-type");

        localPath = filePath;
      } else {
        localPath = widget.pathOrUrl;

        final bytes = await File(localPath!).readAsBytes();

        if (_isImageBytes(bytes)) {
          mimeType = "image";
        } else if (_isPdfBytes(bytes)) {
          mimeType = "application/pdf";
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      hasError = true;
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  bool _isImageBytes(List<int> bytes) {
    return bytes.length > 4 && bytes[0] == 0xFF && bytes[1] == 0xD8;
  }

  bool _isPdfBytes(List<int> bytes) {
    return bytes.length > 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  Future<void> _downloadFile() async {
    if (localPath == null) return;

    try {
      final sourceFile = File(localPath!);

      if (!await sourceFile.exists()) {
        SnackbarManager.show(message: "File not found");
        return;
      }

      Directory targetDir;

      if (Platform.isAndroid) {
        // Try real Downloads folder
        final downloadsDir = Directory('/storage/emulated/0/Download');

        if (await downloadsDir.exists()) {
          targetDir = downloadsDir;
        } else {
          // fallback (important for newer Android)
          targetDir =
              await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final fileName = _generateFileName();

      final destinationPath = "${targetDir.path}/$fileName";

      await sourceFile.copy(destinationPath);

      SnackbarManager.show(message: "Saved to:\n$destinationPath");
    } catch (e) {
      debugPrint("Download error: $e");
      SnackbarManager.show(message: "Download failed");
    }
  }

  String _generateFileName() {
    final baseName = widget.productName ?? "file";

    if (isPdf) return "${baseName}_invoice.pdf";
    if (isImage) return "${baseName}_image.jpg";

    return "${baseName}_file";
  }

  Widget _buildContent() {
    if (hasError) {
      return const Center(
        child: Text(
          "Oops! Something went wrong",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    if (localPath == null) {
      return const Center(
        child: Text(
          "Oops! Something went wrong",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    if (isImage) {
      return InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Image.file(File(localPath!), fit: BoxFit.contain),
      );
    }

    if (isPdf) {
      return PDFView(filePath: localPath!);
    }

    return const Center(
      child: Text("Unsupported file format", style: TextStyle(fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_generateFileName()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadFile,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
}
