import 'dart:ffi';
import 'package:ffi/ffi.dart';
// to complile use:  dart compile exe .\bin\main.dart -o.\bin\main.exe 

// Use NativeFunction and NativeType from dart:ffi
typedef MemsetNative = Pointer<Void> Function(
    Pointer<Void> destination, Int32 value, IntPtr count);

typedef MemsetDart = Pointer<Void> Function(
    Pointer<Void> destination, int value, int count);
// Open the C runtime library
final dylib = DynamicLibrary.process();//.open('ucrtbase.dll');

// Look up the memset function using dart:ffi native types
final memset = dylib.lookupFunction<MemsetNative, MemsetDart>('memset');

void main() {
  // Define constants
  const bufSize = 20;

  // Allocate memory for the buffer
  final buffer = malloc<Uint8>(bufSize + 1);

  try {
    // Equivalent to memset(buffer, 0, sizeof(buffer))
    // First, zero out the entire buffer
    for (int i = 0; i < bufSize + 1; i++) {
      buffer[i] = 0;
    }

    // Cast buffer to void pointer and fill with 'A'
    final stringPtr = memset(buffer.cast<Void>(), 'A'.codeUnitAt(0), 10);

    // Print first buffer contents (first 10 'A's)
    final firstString = stringPtr.cast<Utf8>().toDartString(length: 10);
    print("\nBuffer contents: $firstString");

    // Equivalent to memset(buffer+10, 'B', 10)
    // Fill next 10 characters with 'B'
    memset(buffer.elementAt(10).cast<Void>(), 'B'.codeUnitAt(0), 10);

    // Print full buffer contents
    final fullString = buffer.cast<Utf8>().toDartString(length: bufSize);
    print("\nBuffer contents: $fullString");
  } finally {
    // Always free the allocated memory
    malloc.free(buffer);
  }
}
