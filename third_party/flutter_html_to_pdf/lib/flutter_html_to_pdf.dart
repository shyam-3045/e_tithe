import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_html_to_pdf/file_utils.dart';

class FlutterHtmlToPdf {
  FlutterHtmlToPdf._(); 

  static const MethodChannel _channel = MethodChannel('flutter_html_to_pdf');


  static Future<File> convertFromHtmlContent(
    String htmlContent,
    String targetDirectory,
    String targetName,
  ) async {
    // Write the HTML to a temp file …
    final htmlFile = await FileUtils.createFileWithStringContent(
      htmlContent,
      '$targetDirectory/$targetName.html',
    );

    try {
      return await _convert(htmlFile.path, targetDirectory, targetName);
    } finally {
      // Delete the temp HTML without blocking the caller.
      htmlFile.delete().ignore();
    }
  }

  /// Convert an existing [htmlFile] to PDF.
  static Future<File> convertFromHtmlFile(
    File htmlFile,
    String targetDirectory,
    String targetName,
  ) =>
      _convert(htmlFile.path, targetDirectory, targetName);

  /// Convert the HTML file at [htmlFilePath] to PDF.
  static Future<File> convertFromHtmlFilePath(
    String htmlFilePath,
    String targetDirectory,
    String targetName,
  ) =>
      _convert(htmlFilePath, targetDirectory, targetName);

  // ─── Private helpers ─────────────────────────────────────────────────────────

  /// Core conversion: calls the native channel, then moves the result to the
  /// requested [targetDirectory] / [targetName] location.
  static Future<File> _convert(
    String htmlFilePath,
    String targetDirectory,
    String targetName,
  ) async {
    final String generatedPath = await _invokeConvert(htmlFilePath);
    // `copyAndDeleteOriginalFile` is synchronous-ish; it moves the native
    // output to the caller-supplied directory so it survives temp-dir cleanup.
    return FileUtils.copyAndDeleteOriginalFile(
      generatedPath,
      targetDirectory,
      targetName,
    );
  }

  /// Thin wrapper around the platform channel call.
  ///
  /// Returns the absolute path of the PDF file produced by the native side.
  static Future<String> _invokeConvert(String htmlFilePath) async {
    final result = await _channel.invokeMethod<String>(
      'convertHtmlToPdf',
      <String, dynamic>{'htmlFilePath': htmlFilePath},
    );
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'Native convertHtmlToPdf returned null.',
      );
    }
    return result;
  }
}