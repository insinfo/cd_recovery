import 'package:ffi/ffi.dart';
//import 'package:win32/win32.dart';
import 'dart:ffi';

import 'extensions/datetime_extesions.dart';
import 'win32_api.dart';

/// The [Window] message loop implementation.
/// - See https://learn.microsoft.com/en-us/windows/win32/winmsg/using-messages-and-message-queues
class Win32MessageLoop {
  /// Runs a [Window] message consumer loop that blocks the current thread/`Isolate`.
  ///
  /// - If [condition] is passed loops while [condition] is `true`.
  /// - Uses Win32 [GetMessage] to consume the [Window] messages (blocking call).
  /// - See [runLoopAsync].
  static void runLoop({bool Function()? condition}) {
    condition ??= () => true;
    final msg = calloc<MSG>();
    while (condition() && getMessage(msg, NULL, 0, 0) != 0) {
      translateMessage(msg);
      dispatchMessage(msg);
    }
    free(msg);
  }

  static const yieldMS1 = Duration(milliseconds: 1);
  static const yieldMS10 = Duration(milliseconds: 10);
  static const yieldMS30 = Duration(milliseconds: 30);

  /// Runs a [Window] message consumer loop capable to [timeout] and also
  /// allows Dart [Future]s to be processed while processing messages.
  ///
  /// - If [condition] is passed loops while [condition] is `true`.
  /// - Uses Win32 [PeekMessage] to consume the [Window] messages (non-blocking call).
  /// - See [runLoop].
  static Future<int> runLoopAsync(
      {Duration? timeout,
      int maxConsecutiveDispatches = 100,
      bool Function()? condition}) async {
    maxConsecutiveDispatches = maxConsecutiveDispatches.clamp(2, 1000);
    condition ??= () => true;

    final initTime = DateTime.now();

    final msg = calloc<MSG>();

    var totalMsgCount = 0;
    var noMsgCount = 0;
    var msgCount = 0;

    while (condition()) {
      var got = peekMessage(msg, NULL, 0, 0, 1);

      if (got == 0) {
        got = peekMessage(msg, NULL, 0, 0, 1);
      }

      if (got != 0) {
        totalMsgCount++;
        noMsgCount = 0;
        ++msgCount;

        translateMessage(msg);
        dispatchMessage(msg);

        if ((msgCount % maxConsecutiveDispatches) == 0 && msgCount > 0) {
          if (initTime.timeOut(timeout)) break;

          await Future.delayed(yieldMS1);
        }
      } else {
        ++noMsgCount;
        msgCount = 0;

        if (noMsgCount > 1) {
          if (initTime.timeOut(timeout)) break;

          var yieldMS = switch (noMsgCount) {
            > 300 => yieldMS30,
            > 100 => yieldMS10,
            _ => yieldMS1,
          };

          await Future.delayed(yieldMS);
        }
      }
    }

    free(msg);

    return totalMsgCount;
  }

  /// Consumes the message queue.
  /// - Returns the amount of processed messages.
  /// - Calls Win32 [PeekMessage] (removing from que queue).
  /// - Stops after consume reaches [maxMessages] or when the queue is empty.
  static int consumeQueue({int maxMessages = 3}) {
    final msg = calloc<MSG>();

    var totalMsgCount = 0;
    var noMessageCount = 0;

    while (totalMsgCount < maxMessages) {
      var got = peekMessage(msg, NULL, 0, 0, 1);

      if (got == 0) {
        got = peekMessage(msg, NULL, 0, 0, 1);
      }

      if (got != 0) {
        totalMsgCount++;

        translateMessage(msg);
        dispatchMessage(msg);
      } else {
        ++noMessageCount;

        if (noMessageCount >= 2) {
          break;
        }
      }
    }

    free(msg);

    return totalMsgCount;
  }
}
