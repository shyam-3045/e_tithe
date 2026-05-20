package com.example.e_tithe

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
	private val downloadChannel = "download_saver"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadChannel)
			.setMethodCallHandler { call, result ->
				if (call.method == "savePdfToDownloads") {
					val bytes = call.argument<ByteArray>("bytes")
					val fileName = call.argument<String>("fileName") ?: "receipt.pdf"

					if (bytes == null) {
						result.error("NO_BYTES", "Missing PDF bytes", null)
						return@setMethodCallHandler
					}

					try {
						val savedPath = savePdfToDownloads(fileName, bytes)
						result.success(savedPath)
					} catch (e: Exception) {
						result.error("SAVE_FAILED", e.message, null)
					}
				} else {
					result.notImplemented()
				}
			}
	}

	private fun savePdfToDownloads(fileName: String, bytes: ByteArray): String {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val resolver = applicationContext.contentResolver
			val values = ContentValues().apply {
				put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
				put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
				put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
			}

			val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
				?: throw Exception("Unable to create download entry")

			resolver.openOutputStream(uri).use { out ->
				if (out == null) throw Exception("Unable to open output stream")
				out.write(bytes)
				out.flush()
			}

			uri.toString()
		} else {
			val downloads = Environment.getExternalStoragePublicDirectory(
				Environment.DIRECTORY_DOWNLOADS,
			)
			if (!downloads.exists()) {
				downloads.mkdirs()
			}

			val file = File(downloads, fileName)
			FileOutputStream(file).use { stream ->
				stream.write(bytes)
				stream.flush()
			}

			file.absolutePath
		}
	}
}
