import 'dart:ffi';
import 'dart:io';
import 'package:cd_recovery/src/windows/gui2/win32_api.dart';
import 'package:ffi/ffi.dart';

String sanitizeDriverLetter(String input) {
  // Check if input is null or empty
  if (input.isEmpty) {
    throw Exception('Driver Letter não pode ser vazio');
  }
  // Remove any non-alphabetic characters and convert to uppercase
  String sanitized = input.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();

  // Return the first character if it exists, otherwise return empty string
  return sanitized.isNotEmpty ? sanitized[0] : '';
}

String getVolumeName(String driveLetter) {
  // O drive deve terminar com \\
  // Exemplo: "D:\\"
  final dl = sanitizeDriverLetter(driveLetter);
  final driveRoot = '$dl:\\'.toNativeUtf16();

  // Buffers para receber a informação
  final volumeNameBuffer = calloc<Uint16>(MAX_PATH);
  final fileSystemNameBuffer = calloc<Uint16>(MAX_PATH);
  final lpVolumeSerialNumber = calloc<Uint32>();
  final lpMaximumComponentLength = calloc<Uint32>();
  final lpFileSystemFlags = calloc<Uint32>();

  final result = getVolumeInformation(
      driveRoot,
      volumeNameBuffer.cast(),
      MAX_PATH,
      lpVolumeSerialNumber,
      lpMaximumComponentLength,
      lpFileSystemFlags,
      fileSystemNameBuffer.cast(),
      MAX_PATH);

  calloc.free(driveRoot);
  calloc.free(lpVolumeSerialNumber);
  calloc.free(lpMaximumComponentLength);
  calloc.free(lpFileSystemFlags);
  calloc.free(fileSystemNameBuffer);

  if (result == 0) {
    calloc.free(volumeNameBuffer);
    final errorCode = getLastError();
    throw Exception('Falha ao obter o nome do volume. Erro: $errorCode');
  }

  final volumeName = volumeNameBuffer.cast<Utf16>().toDartString();
  calloc.free(volumeNameBuffer);
  return volumeName;
}

// Função para copiar todos os arquivos de sourceDir para destDir.
// sourceDir e destDir devem ser caminhos absolutos.
void copyDirectoryContents(String sourceDir, String destDir) {
  // Certificar que os diretórios terminam com barra invertida
  if (!sourceDir.endsWith('\\')) {
    sourceDir = '$sourceDir\\';
  }
  if (!destDir.endsWith('\\')) {
    destDir = '$destDir\\';
  }

  // Cria o diretório destino se não existir
  final destPtr = destDir.toNativeUtf16();
  final createRes = createDirectory(destPtr, nullptr);
  if (createRes == 0 && getLastError() != ERROR_ALREADY_EXISTS) {
    print('Falha ao criar diretório $destDir. Erro: ${getLastError()}');
  }
  calloc.free(destPtr);

  // Monta o padrão de busca sourceDir + '*'
  final searchPattern = '$sourceDir*'.toNativeUtf16();

  final findData = calloc<WIN32_FIND_DATA>();
  final hFind = findFirstFile(searchPattern, findData);
  calloc.free(searchPattern);

  if (hFind == INVALID_HANDLE_VALUE) {
    final err = getLastError();
    if (err != ERROR_FILE_NOT_FOUND) {
      print('Falha ao listar $sourceDir. Erro: $err');
    }
    calloc.free(findData);
    return;
  }

  do {
    final fileName = findData.ref.cFileName;
    final dartFileName = fileName;

    // Ignora "." e ".."
    if (dartFileName == '.' || dartFileName == '..') {
      continue;
    }

    final fullSourcePath = '$sourceDir$dartFileName';
    final fullDestPath = '$destDir$dartFileName';

    // Verifica se é diretório
    final isDirectory =
        (findData.ref.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;

    if (isDirectory) {
      // Recursão para copiar subdiretório
      copyDirectoryContents(fullSourcePath, fullDestPath);
    } else {
      // Copia arquivo
      final srcPtr = fullSourcePath.toNativeUtf16();
      final dstPtr = fullDestPath.toNativeUtf16();

      final result = copyFile(srcPtr, dstPtr, FALSE);
      if (result == 0) {
        print(
            'Falha ao copiar $fullSourcePath para $fullDestPath. Erro: ${getLastError()}');
      }

      calloc.free(srcPtr);
      calloc.free(dstPtr);
    }
  } while (findNextFile(hFind, findData) != 0);

  findClose(hFind);
  calloc.free(findData);
}

String readNullTerminatedString(Pointer<Uint8> ptr, int maxLen) {
  final bytes = <int>[];
  for (int i = 0; i < maxLen; i++) {
    final byte = ptr[i];
    if (byte == 0) break;
    bytes.add(byte);
  }
  return String.fromCharCodes(bytes);
}

List<String> listCDDrives() {
  final drives = <String>[];
  final buffer = calloc<Uint16>(26 * 4);
  try {
    final driveBitmap = logicalDrives(26 * 4, buffer.cast<Utf16>());
    for (int i = 0; i < 26; i++) {
      if (driveBitmap & (1 << i) != 0) {
        final drive = String.fromCharCode(65 + i) + ':\\';
        final driveType = _getDriveType(drive);
        if (driveType == 5) {
          // DRIVE_CDROM
          drives.add(drive);
        }
      }
    }
  } finally {
    calloc.free(buffer);
  }
  return drives;
}

int _getDriveType(String rootPath) {
  final pathPtr = rootPath.toNativeUtf16();
  try {
    return getDriveType(pathPtr);
  } finally {
    calloc.free(pathPtr);
  }
}

void openCdTray() {
  final command = 'set cdaudio door open'.toNativeUtf16();
  mciSendString(command, nullptr, 0, 0);
  calloc.free(command);
}

void closeCdTray() {
  final command = 'set cdaudio door closed'.toNativeUtf16();
  mciSendString(command, nullptr, 0, 0);
  calloc.free(command);
}

Future<int> getDirectorySize(Directory directory) async {
  int totalSize = 0;
  await for (var entity
      in directory.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      totalSize += await entity.length();
    }
  }
  return totalSize;
}
