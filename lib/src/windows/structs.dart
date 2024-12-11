import 'dart:ffi';

import 'package:ffi/ffi.dart';

final class LARGE_INTEGER extends Union {
  @Uint32()
  external int LowPart;

  @Int32()
  external int HighPart;

  @Int64()
  external int QuadPart;

  factory LARGE_INTEGER.allocate() {
    final largeInt = calloc<LARGE_INTEGER>().ref;
    return largeInt;
  }
}
