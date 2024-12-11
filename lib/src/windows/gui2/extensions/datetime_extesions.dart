extension DateTimeExtension on DateTime {
  Duration get elapsedTime => DateTime.now().difference(this);

  Duration remainingTime(Duration timeout) => timeout - elapsedTime;

  bool hasRemainingTime(Duration? timeout) {
    if (timeout == null) return true;
    return remainingTime(timeout).inMilliseconds > 0;
  }

  bool timeOut(Duration? timeout) {
    return !hasRemainingTime(timeout);
  }
}
