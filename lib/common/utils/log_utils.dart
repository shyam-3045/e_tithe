/// Logging helpers for output that exceeds the platform log line limit.
///
/// Android's logcat truncates a single line at roughly 1000 bytes, which silently
/// cuts off JSON request/response bodies mid-string. [printLong] splits the text
/// into numbered chunks so the whole payload is readable.
void printLong(String label, String text, {int chunkSize = 800}) {
  if (text.length <= chunkSize) {
    print('$label: $text');
    return;
  }

  final int totalChunks = (text.length / chunkSize).ceil();
  print('$label: (${text.length} chars, $totalChunks parts)');

  for (int i = 0; i < totalChunks; i++) {
    final int start = i * chunkSize;
    final int end =
        (start + chunkSize) > text.length ? text.length : (start + chunkSize);
    print('$label [${i + 1}/$totalChunks]: ${text.substring(start, end)}');
  }
}
