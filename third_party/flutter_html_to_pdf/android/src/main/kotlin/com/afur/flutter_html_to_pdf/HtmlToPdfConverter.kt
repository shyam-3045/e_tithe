package com.afur.flutter_html_to_pdf

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.pdf.PdfDocument
import android.webkit.WebView
import android.webkit.WebViewClient
import android.view.View
import java.util.concurrent.atomic.AtomicBoolean

import java.io.FileOutputStream
import java.io.File
import kotlin.math.max


class HtmlToPdfConverter {

    interface Callback {
        fun onSuccess(filePath: String)
        fun onFailure()
    }

    @SuppressLint("SetJavaScriptEnabled")
    fun convert(filePath: String, applicationContext: Context, callback: Callback) {
        val webView = WebView(applicationContext)
        val htmlContent = File(filePath).readText(Charsets.UTF_8)
        val completed = AtomicBoolean(false)
        webView.settings.javaScriptEnabled = true
        webView.settings.javaScriptCanOpenWindowsAutomatically = true
        webView.settings.allowFileAccess = true
        webView.settings.loadWithOverviewMode = true
        webView.settings.useWideViewPort = true
        webView.setBackgroundColor(0x00FFFFFF)
        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView, url: String) {
                super.onPageFinished(view, url)
                view.post {
                    try {
                        if (completed.compareAndSet(false, true)) {
                            createPdfFromWebView(webView, applicationContext, callback)
                        }
                    } catch (_: Exception) {
                        if (completed.compareAndSet(false, true)) {
                            callback.onFailure()
                        }
                    } finally {
                        view.destroy()
                    }
                }
            }
        }
        webView.loadDataWithBaseURL(null, htmlContent, "text/HTML", "UTF-8", null)

        // Fallback to avoid hanging forever if WebView callbacks are never delivered.
        webView.postDelayed({
            if (completed.compareAndSet(false, true)) {
                callback.onFailure()
                webView.destroy()
            }
        }, 15000)
    }

    fun createPdfFromWebView(webView: WebView, applicationContext: Context, callback: Callback) {
        val pdfWidth = 595
        webView.measure(
            View.MeasureSpec.makeMeasureSpec(pdfWidth, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        )
        val measuredWidth = max(webView.measuredWidth, pdfWidth)
        val measuredHeight = max(webView.measuredHeight, 842)
        webView.layout(0, 0, measuredWidth, measuredHeight)

        val pdfDocument = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(measuredWidth, measuredHeight, 1).create()
        val page = pdfDocument.startPage(pageInfo)
        val canvas: Canvas = page.canvas
        val scale = measuredWidth.toFloat() / webView.measuredWidth.toFloat()
        canvas.scale(scale, scale)
        webView.draw(canvas)
        pdfDocument.finishPage(page)

        val outputFile = File(applicationContext.filesDir, temporaryFileName)
        FileOutputStream(outputFile).use { outputStream ->
            pdfDocument.writeTo(outputStream)
        }
        pdfDocument.close()

        callback.onSuccess(outputFile.absolutePath)
    }

    companion object {
        const val temporaryDocumentName = "TemporaryDocumentName"
        const val temporaryFileName = "TemporaryDocumentFile.pdf"
    }
}
