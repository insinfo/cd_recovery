import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsErrorHandler {
  static int MAKELANGID(int primaryLanguage, int subLanguage) {
    return (subLanguage << 10) | primaryLanguage;
  }

  static const int FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100;
  static const int LANG_NEUTRAL = 0x00;
  static const int SUBLANG_DEFAULT = 0x01;

  static String getLastErrorAsString() {
    // Get the error message ID
    final errorMessageID = GetLastError();

    // If no error, return empty string
    if (errorMessageID == 0) {
      return '';
    }

    // Allocate memory for the error message buffer
    final messageBuffer = calloc<Pointer<Utf16>>();

    try {
      // Format the error message
      final size = FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
        nullptr,
        errorMessageID,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        messageBuffer.cast(),
        0,
        nullptr,
      );

      // If message formatting fails, return empty string
      if (size == 0) {
        return '';
      }

      // Convert the error message to a Dart string
      final errorMessage = messageBuffer.value.toDartString();

      // Return the error message, trimming any trailing whitespace
      return errorMessage.trim();
    } finally {
      // Free the allocated memory
      if (messageBuffer.value != nullptr) {
        LocalFree(messageBuffer.value.cast<Void>());
      }
      calloc.free(messageBuffer);
    }
  }
}
