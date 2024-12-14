import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cd_recovery/src/windows/utils/utils.dart';
import 'package:cd_recovery/src/windows/windows_error_handler.dart';
import 'package:ffi/ffi.dart';

import '../windows/gui2/win32_api.dart';

//const int IOCTL_CDROM_BASE = 0x0000002d << 16;
const int IOCTL_CDROM_BASE = FILE_DEVICE_CD_ROM;

int CTL_CODE(int DeviceType, int Function, int Method, int Access) {
  return ((DeviceType << 16) | (Access << 14) | (Function << 2) | Method);
}

const IOCTL_SCSI_BASE = FILE_DEVICE_CONTROLLER;
const FILE_DEVICE_SCSI = 0x0000001b;

const DD_SCSI_DEVICE_NAME = "\\Device\\ScsiPort";

final int IOCTL_SCSI_PASS_THROUGH = CTL_CODE(IOCTL_SCSI_BASE, 0x0401,
    METHOD_BUFFERED, FILE_READ_ACCESS | FILE_WRITE_ACCESS);

const int FILE_ANY_ACCESS = 0;
const int FILE_SPECIAL_ACCESS = FILE_ANY_ACCESS;
const int FILE_READ_ACCESS = 0x0001; // file & pipe
const int FILE_WRITE_ACCESS = 0x0002; // file & pipe
const int METHOD_OUT_DIRECT = 2;

const int SCSI_IOCTL_DATA_OUT = 0;
const int SCSI_IOCTL_DATA_IN = 1;
const int SCSI_IOCTL_DATA_UNSPECIFIED = 2;

// IOCTL para leitura raw

final IOCTL_CDROM_RAW_READ =
    CTL_CODE(IOCTL_CDROM_BASE, 0x000F, METHOD_OUT_DIRECT, FILE_READ_ACCESS);

final IOCTL_CDROM_READ_TOC =
    CTL_CODE(IOCTL_CDROM_BASE, 0x0000, METHOD_BUFFERED, FILE_READ_ACCESS);

base class LARGE_INTEGER extends Struct {
  @Int64()
  external int QuadPart;
}

base class LARGE_INTEGER_U extends Union {
  @Uint32()
  external int lowPart;
  @Int32()
  external int highPart;
  @Int64()
  external int quadPart;
}

// Função auxiliar para converter MSF -> LBA
int msfToLba(int m, int s, int f) {
  // Calculo: LBA = ((M * 60) + S) * 75 + F - 150
  return ((m * 60) + s) * 75 + f - 150;
}

enum TRACK_MODE_TYPE {
  YellowMode2,
  XAForm2,
  CDDA,
  RawWithC2AndSubCode, // CD_RAW_SECTOR_WITH_C2_AND_SUBCODE_SIZE per sector
  RawWithC2, // CD_RAW_SECTOR_WITH_C2_SIZE per sector
  RawWithSubCode // CD_RAW_SECTOR_WITH_SUBCODE_SIZE per sector
}

const int CD_RAW_READ_C2_SIZE = 296;
const int CD_RAW_READ_SUBCODE_SIZE = 96;

/// 2648
const int CD_RAW_SECTOR_WITH_C2_SIZE = 2352 + 296;

/// 2448
const int CD_RAW_SECTOR_WITH_SUBCODE_SIZE = 2352 + 96;

/// 2744
const int CD_RAW_SECTOR_WITH_C2_AND_SUBCODE_SIZE = 2352 + 296 + 96;

// typedef struct __RAW_READ_INFO {
//     LARGE_INTEGER DiskOffset;
//     ULONG    SectorCount;
//     TRACK_MODE_TYPE TrackMode;
// } RAW_READ_INFO, *PRAW_READ_INFO;
base class RAW_READ_INFO extends Struct {
  external LARGE_INTEGER DiskOffset;
  @Uint32()
  external int SectorCount;
  @Uint32()
  external int TrackMode; // Use um valor do enum TRACK_MODE_TYPE
}

class CDDriveController {
  static const int FILE_BEGIN = 0;
  //Usar Setores de 2048 bytes (para CDs de dados) com a função readFile
  //Geralmente, um setor RAW de CD possui 2352 bytes
  static const int sectorSizeRaw = 2352; // Tamanho do setor bruto em bytes
  static const int sectorSizeNormal = 2048;

  static int getDiscSizeSimple(String drivePath) {
    var driveLetter = sanitizeDriverLetter(drivePath);
    driveLetter = '$driveLetter:\\';
    final drivePtr = driveLetter.toNativeUtf16();
    final freeBytesAvailableToCaller = calloc<Uint64>();
    final totalNumberOfBytes = calloc<Uint64>();
    final totalNumberOfFreeBytes = calloc<Uint64>();
    try {
      final result = getDiskFreeSpaceEx(drivePtr, freeBytesAvailableToCaller,
          totalNumberOfBytes, totalNumberOfFreeBytes);
      print(
          'getDiscSize freeBytesAvailable ${freeBytesAvailableToCaller.value} | totalNumberOfBytes ${totalNumberOfBytes.value} | totalNumberOfFreeBytes ${totalNumberOfFreeBytes.value} ');
      if (result == 0) {
        throw Exception('não foi possivel obter o tamanho');
      }
      return totalNumberOfBytes.value;
    } finally {
      calloc.free(drivePtr);
      calloc.free(freeBytesAvailableToCaller);
      calloc.free(totalNumberOfBytes);
      calloc.free(totalNumberOfFreeBytes);
    }
  }

  // Função para modelar dados de setores adjacentes
  static void fillWithAdjacentData(Pointer<Uint8> buffer,
      Pointer<Uint8>? previous, Pointer<Uint8>? next, int size) {
    for (int i = 0; i < size; i++) {
      if (previous != null && next != null) {
        buffer[i] = ((previous[i] + next[i]) ~/ 2);
      } else if (previous != null) {
        buffer[i] = previous[i];
      } else if (next != null) {
        buffer[i] = next[i];
      } else {
        buffer[i] = 0;
      }
    }
  }

  /// ejeta a gaveta do driver de CD
  static bool eject(String driveLetter) {
    // isso funciona
    // final command = 'set cdaudio door open'.toNativeUtf16();
    // mciSendString(command, nullptr, 0, 0);
    // calloc.free(command);

    final devicePath = '\\\\.\\${sanitizeDriverLetter(driveLetter)}:';
    final devicePtr = devicePath.toNativeUtf16();

//// HANDLE hCdRom = CreateFile(_T("\\\\.\\M:"), GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
    final handle = createFile(devicePtr, GENERIC_READ | GENERIC_WRITE, 0,
        nullptr, OPEN_EXISTING, 0, 0);

    if (handle == -1 || handle == 0) {
      print(
          'Erro ao abrir o handle para a unidade $driveLetter. Erro: ${getLastError()}');
      return false;
    }

    malloc.free(devicePtr);

    final bytesReturned = calloc<Uint32>();
    // // Open the door:
    ///// DeviceIoControl(hCdRom, IOCTL_STORAGE_EJECT_MEDIA, NULL, 0, NULL, 0, &dwBytes, NULL);
    final success = deviceIoControl(handle, IOCTL_STORAGE_EJECT_MEDIA, nullptr,
        0, nullptr, 0, bytesReturned, nullptr);

    if (!success) {
      print(
          'Falha ao ejetar a unidade $driveLetter. Erro: $success ${getLastError()} ${WindowsErrorHandler.getLastErrorAsString()}');
      return false;
    }
    closeHandle(handle);
    calloc.free(bytesReturned);

    return true;
  }

  static bool close(String driveLetter) {
    final devicePath = '\\\\.\\${sanitizeDriverLetter(driveLetter)}:';
    final devicePtr = devicePath.toNativeUtf16();

    final handle = createFile(devicePtr, GENERIC_READ | GENERIC_WRITE, 0,
        nullptr, OPEN_EXISTING, 0, 0);

    malloc.free(devicePtr);

    if (handle == -1 || handle == 0) {
      print(
          'Erro ao abrir o handle para a unidade $driveLetter. Erro: ${getLastError()}');
      return false;
    }

    final bytesReturned = calloc<Uint32>();

    final success = deviceIoControl(handle, IOCTL_STORAGE_LOAD_MEDIA, nullptr,
        0, nullptr, 0, bytesReturned, nullptr);

    calloc.free(bytesReturned);

    closeHandle(handle);

    if (!success) {
      print('Falha ao fechar a unidade $driveLetter. Erro: ${getLastError()}');
      return false;
    }

    return true;
  }

  static bool isVirtualDrive(String driveLetter) {
    final devicePath = '\\\\.\\${sanitizeDriverLetter(driveLetter)}:';
    final devicePtr = devicePath.toNativeUtf16();

    final hDevice = createFile(
      devicePtr,
      GENERIC_READ,
      FILE_SHARE_READ | FILE_SHARE_WRITE,
      nullptr,
      OPEN_EXISTING,
      0,
      NULL,
    );

    calloc.free(devicePtr);

    if (hDevice == INVALID_HANDLE_VALUE) {
      print('Falha ao abrir o drive $driveLetter. Erro: ${getLastError()}');
      return false;
    }

    // Prepara a query
    final query = calloc<STORAGE_PROPERTY_QUERY>();
    query.ref.PropertyId = StorageDeviceProperty;
    query.ref.QueryType = PropertyStandardQuery;

    // Buffer para receber o descriptor
    // STORAGE_DEVICE_DESCRIPTOR é variável, então alocamos um buffer maior
    final bufferSize = 1024;
    final buffer = calloc<Uint8>(bufferSize);

    final bytesReturned = calloc<Uint32>();

    final result = deviceIoControl(
      hDevice,
      IOCTL_STORAGE_QUERY_PROPERTY,
      query.cast(),
      sizeOf<STORAGE_PROPERTY_QUERY>(),
      buffer.cast(),
      bufferSize,
      bytesReturned,
      nullptr,
    );

    closeHandle(hDevice);
    calloc.free(query);
    calloc.free(bytesReturned);

    if (result == 0) {
      calloc.free(buffer);
      print(
          'Falha ao obter STORAGE_DEVICE_DESCRIPTOR. Erro: ${getLastError()}');
      return false;
    }

    final descriptor = buffer.cast<STORAGE_DEVICE_DESCRIPTOR>().ref;

    // Verifica o tipo de barramento
    // Valores possíveis: https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntddstor/ne-ntddstor-_storage_bus_type
    // BusType = 1 => SCSI, 2 => ATAPI, 3 => ATA, 7 => SATA, ...
    // Muitas unidades virtuais se apresentam como SCSI.
    //
    // Apenas como heurística, se for SCSI, consideraremos virtual (não é 100% garantido).
    // Você pode refinar com VendorId e ProductId offsets, se quiser.

    bool isVirtual = false;
    switch (descriptor.BusType) {
      case 1: // SCSI
        isVirtual = true;
        break;
      case 7: // SATA
        isVirtual = false;
        break;
      default:
        // Caso não reconhecido, depender de heurísticas adicionais se desejado.
        isVirtual = false;
        break;
    }

    // Opcionalmente, checar VendorId/ProductId se offsets > 0
    // Exemplo:
    if (descriptor.ProductIdOffset > 0 &&
        descriptor.ProductIdOffset < descriptor.Size) {
      final productIdPtr =
          buffer.elementAt(descriptor.ProductIdOffset).cast<Uint8>();
      final productId = readNullTerminatedString(
          productIdPtr, bufferSize - descriptor.ProductIdOffset);
      // Se productId contém algo como 'Virtual', 'Msft', pode indicar virtual
      if (productId.toLowerCase().contains('virtual')) {
        isVirtual = true;
      }
    }

    calloc.free(buffer);
    return isVirtual;
  }

  /// Função para ler um setor raw com deviceIoControl
  static bool readRawSector(int deviceHandle, int sector, Pointer<Uint8> buffer,
      int bufferSize, int trackMode, int sectorSize) {
    // Preenche a estrutura RAW_READ_INFO
    final rawReadInfo = calloc<RAW_READ_INFO>();
    // Cada setor RAW geralmente = 2352 bytes. Ajuste conforme necessário.
    rawReadInfo.ref.DiskOffset.QuadPart = sector * sectorSize; //2048
    rawReadInfo.ref.SectorCount = 1;
    // Definir o modo de leitura. Caso seja um CD de dados modo 2:
    rawReadInfo.ref.TrackMode = trackMode;

    final bytesReturned = calloc<Uint32>();

    final ret = deviceIoControl(
        deviceHandle,
        IOCTL_CDROM_RAW_READ,
        rawReadInfo.cast(),
        sizeOf<RAW_READ_INFO>(),
        buffer.cast(),
        bufferSize,
        bytesReturned,
        nullptr);
    // esta retornando 2456
    print('readRawSector ${bytesReturned.value}');

    calloc.free(rawReadInfo);
    calloc.free(bytesReturned);

    return ret;
  }

  /// Função de cópia  do CD com callback de progresso
  static Future<void> copyCD(String driveLetter, String outputFile,
      {void Function(int sector, int totalSectors)? onProgress}) async {
    if (isVirtualDrive(driveLetter)) {
      throw Exception('Não é possivel ler dados de uma unidade virtual');
    }

    final totalSectors = getDiscTotalSectors(driveLetter);

    if (totalSectors < 1) {
      throw Exception('Não foi possivel obter o tamanho do disco');
    }

    print('copyCDRaw totalSectors $totalSectors');

    final devicePath = '\\\\.\\${sanitizeDriverLetter(driveLetter)}:';
    final devicePtr = devicePath.toNativeUtf16();

    // Abrir o dispositivo de CD
    var handleDevice = createFile(
        devicePtr,
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        nullptr,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        0);

    if (handleDevice == INVALID_HANDLE_VALUE) {
      handleDevice = createFile(
          devicePtr,
          GENERIC_READ,
          FILE_SHARE_READ | FILE_SHARE_WRITE,
          nullptr,
          OPEN_EXISTING,
          FILE_ATTRIBUTE_NORMAL,
          0);
    }

    if (handleDevice == -1 || handleDevice == 0) {
      print(
          'Erro ao abrir o handle para a unidade $driveLetter. Erro: ${getLastError()} ${WindowsErrorHandler.getLastErrorAsString()}');
      return;
    }

    malloc.free(devicePtr);

    print('copyCDRaw outputFile $outputFile');
    final outputFilePtr = outputFile.toNativeUtf16();
    // Criar arquivo de saída
    final hOut = createFile(outputFilePtr, GENERIC_WRITE, 0, nullptr,
        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);

    if (hOut == INVALID_HANDLE_VALUE) {
      print(
          'Erro ao criar o arquivo de saída $outputFile. Código de erro: ${getLastError()}');
      closeHandle(handleDevice);
      return;
    }

    try {
      // Alocação de memória para buffers
      final buffer = calloc<Uint8>(sectorSizeNormal);
      final previousSector = calloc<Uint8>(sectorSizeNormal);
      final nextSector = calloc<Uint8>(sectorSizeNormal);

      int sector = 0;
      bool hasPrevious = false;
      bool success = true;

      print('Iniciando a cópia do CD...');

      while (success && sector < totalSectors) {
        // Posicionar ponteiro no setor
        final sectorOffset = sector * sectorSizeNormal;
        setFilePointerEx(handleDevice, sectorOffset, nullptr, FILE_BEGIN);

        // Ler setor
        final bytesRead = calloc<Uint32>();
        final readFileStatus = readFile(
            handleDevice, buffer, sectorSizeNormal, bytesRead, nullptr);

        success = readFileStatus != 0;

        if (!success || bytesRead.value != sectorSizeNormal) {
          print('Setor $sector ilegível. Tentando usar dados adjacentes...');

          //throw Exception('error Setor $sector ilegível');

          // Tentar ler o próximo setor
          final nextOffset = (sector + 1) * sectorSizeNormal;
          setFilePointerEx(handleDevice, nextOffset, nullptr, FILE_BEGIN);

          final nextBytesRead = calloc<Uint32>();
          final nextSuccess = readFile(handleDevice, nextSector,
                  sectorSizeNormal, nextBytesRead, nullptr) !=
              0;

          if (!nextSuccess || nextBytesRead.value != sectorSizeNormal) {
            for (int i = 0; i < sectorSizeNormal; i++) {
              nextSector[i] = 0; // Preencher próximo setor com zeros se falhar
            }
          }

          // Preencher setor com dados modelados
          fillWithAdjacentData(
            buffer,
            hasPrevious ? previousSector : null,
            nextSuccess ? nextSector : null,
            sectorSizeNormal,
          );

          success = true; // Continuar mesmo com setor ilegível
          calloc.free(nextBytesRead);
        }

        // Escrever setor no arquivo de saída
        final bytesWritten = calloc<Uint32>();
        success =
            writeFile(hOut, buffer, sectorSizeNormal, bytesWritten, nullptr) !=
                0;

        if (!success || bytesWritten.value != sectorSizeNormal) {
          print('Erro ao escrever no arquivo de saída.');
          break;
        }

        // Copiar setor atual para setor anterior
        for (int i = 0; i < sectorSizeNormal; i++) {
          previousSector[i] = buffer[i];
        }
        hasPrevious = true;

        sector++;
        // Atualizar o progresso através do callback
        if (onProgress != null) {
          onProgress(sector, totalSectors);
        }

        calloc.free(bytesRead);
        calloc.free(bytesWritten);
      }

      // Liberar memória alocada
      calloc.free(buffer);
      calloc.free(previousSector);
      calloc.free(nextSector);
    } finally {
      closeHandle(handleDevice);
      closeHandle(hOut);
    }

    print('Cópia concluída com sucesso!');
  }

  /// Exemplo de função copyCDRaw completa usando deviceIoControl
  static Future<void> copyCDRaw(String driveLetter, String outputFile,
      {void Function(int sector, int totalSectors)? onProgress}) async {
    // Verifica se a unidade não é virtual
    if (isVirtualDrive(driveLetter)) {
      throw Exception('Não é possível ler dados brutos de uma unidade virtual');
    }

    final devicePath = '\\\\.\\${sanitizeDriverLetter(driveLetter)}:';
    final devicePtr = devicePath.toNativeUtf16();

    var handleDevice = createFile(
        devicePtr,
        GENERIC_READ,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        nullptr,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        NULL);

    if (handleDevice == INVALID_HANDLE_VALUE || handleDevice == 0) {
      calloc.free(devicePtr);
      throw Exception(
          'Erro ao abrir o handle para a unidade $driveLetter. Erro: ${getLastError()} ${WindowsErrorHandler.getLastErrorAsString()}');
    }

    calloc.free(devicePtr);

    final outputFilePtr = outputFile.toNativeUtf16();
    final hOut = createFile(outputFilePtr, GENERIC_WRITE, 0, nullptr,
        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    calloc.free(outputFilePtr);

    if (hOut == INVALID_HANDLE_VALUE) {
      closeHandle(handleDevice);
      throw Exception(
          'Erro ao criar o arquivo de saída $outputFile. Código de erro: ${getLastError()}');
    }

    try {
      // Setor RAW típico
      const sectorSize = CD_RAW_SECTOR_WITH_C2_AND_SUBCODE_SIZE;

      final buffer = calloc<Uint8>(sectorSize);
      final previousSector = calloc<Uint8>(sectorSize);
      final nextSector = calloc<Uint8>(sectorSize);

      int sector = 0;
      bool hasPrevious = false;

      // Aqui você deve obter o total de setores do CD. Isso envolve leitura da TOC.
      final totalSectors = getDiscTotalSectors(driveLetter);
      print('copyCDRaw total sectors $totalSectors');

      // Aqui decidimos o TrackMode. Se for CD de dados Modo 2, use YellowMode2.
      // Se for áudio, use CDDA.
      // Isso pode precisar ser detectado dinamicamente consultando a TOC do CD.
      TRACK_MODE_TYPE trackMode = TRACK_MODE_TYPE.RawWithC2AndSubCode;
      // TRACK_MODE_TYPE.YellowMode2;

      while (sector < totalSectors) {
        bool success = readRawSector(handleDevice, sector, buffer, sectorSize,
            trackMode.index, sectorSize);

        if (!success) {
          // tem algum bug pois esta repostando o setor 19615 como ilegivel mais no IsoBuster esta reportando como ilegivel os setores 26281, 26282
          print(
              'Setor $sector ilegível. Tentando usar dados adjacentes... totalSectors $totalSectors');

          // Ler próximo setor para tentar interpolar
          bool nextSuccess = readRawSector(handleDevice, sector + 1, nextSector,
              sectorSize, trackMode.index, sectorSize);
          if (!nextSuccess) {
            for (int i = 0; i < sectorSize; i++) {
              nextSector[i] = 0;
            }
          }

          fillWithAdjacentData(
            buffer,
            hasPrevious ? previousSector : null,
            nextSuccess ? nextSector : null,
            sectorSize,
          );

          // Continua mesmo assim
          success = true;
        }

        // Escrever setor no arquivo de saída
        final bytesWritten = calloc<Uint32>();
        final writeSuccess =
            writeFile(hOut, buffer, sectorSize, bytesWritten, nullptr) != 0;
        if (!writeSuccess || bytesWritten.value != sectorSize) {
          calloc.free(bytesWritten);
          throw Exception(
              'Erro ao escrever no arquivo de saída. Erro: ${getLastError()}');
        }
        calloc.free(bytesWritten);

        // Atualizar previousSector
        for (int i = 0; i < sectorSize; i++) {
          previousSector[i] = buffer[i];
        }
        hasPrevious = true;

        sector++;
        // Callback de progresso
        if (onProgress != null) {
          onProgress(sector, totalSectors);
        }
      }

      calloc.free(buffer);
      calloc.free(previousSector);
      calloc.free(nextSector);
    } finally {
      closeHandle(handleDevice);
      closeHandle(hOut);
    }

    print('Cópia RAW concluída!');
  }

  /// obtem o total de setores do disco
  /// número total de setores (no sentido de endereços lógicos do CD)
  static int getDiscTotalSectors(String driveLetter) {
    final devicePath = '\\\\.\\${sanitizeDriverLetter(driveLetter)}:';
    final devicePathPtr = devicePath.toNativeUtf16();

    final handleDevice = createFile(
        devicePathPtr,
        GENERIC_READ,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        nullptr,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        NULL);

    calloc.free(devicePathPtr);

    if (handleDevice == INVALID_HANDLE_VALUE || handleDevice == 0) {
      throw Exception(
          'Erro ao abrir o dispositivo $devicePath. Erro: ${getLastError()}');
    }

    try {
      // Prepara buffer para TOC
      // CDROM_TOC não é muito grande, 804 bytes no máximo (100 faixas * tamanho TRACK_DATA + cabeçalho)
      final tocSize = sizeOf<CDROM_TOC>();
      final tocBuffer = calloc<Uint8>(tocSize);
      final bytesReturned = calloc<Uint32>();

      final success = deviceIoControl(handleDevice, IOCTL_CDROM_READ_TOC,
          nullptr, 0, tocBuffer.cast(), tocSize, bytesReturned, nullptr);

      if (success == 0) {
        calloc.free(tocBuffer);
        calloc.free(bytesReturned);
        throw Exception(
            'Falha ao ler TOC. Erro: ${getLastError()} ${WindowsErrorHandler.getLastErrorAsString()}');
      }

      // Interpretar TOC
      final pToc = tocBuffer.cast<CDROM_TOC>().ref;
      final firstTrack = pToc.FirstTrack;
      final lastTrack = pToc.LastTrack;

      // O lead-out track é a última entrada após a última faixa
      // Índice da lead-out: (lastTrack - firstTrack + 1)
      // Por exemplo, se FirstTrack=1 e LastTrack=12, então:
      // TrackData[0] ... TrackData[LastTrack-FirstTrack] = TrackData[11] (12 faixas)
      // Lead-out = TrackData[12]
      final leadOutIndex = (lastTrack - firstTrack + 1);
      if (leadOutIndex < 0 || leadOutIndex >= 100) {
        // Inconsistência
        calloc.free(tocBuffer);
        calloc.free(bytesReturned);
        throw Exception('TOC inválida ou não suportada.');
      }

      final leadOut = pToc.TrackData[leadOutIndex];

      final m = leadOut.Address1;
      final s = leadOut.Address2;
      final f = leadOut.Address3;

      final leadOutLba = msfToLba(m, s, f);
      // leadOutLba indica o setor do lead-out, que é basicamente o final do disco.

      // LBA (Logical Block Addressing) e tamanho de setor:
      // O LBA conta o número de setores lógicos do CD, cada um deles representando
      // 2048 bytes de dados de usuário em um CD modo 1.
      // O leadOutLba obtido da TOC (Table of Contents) indica
      // o número total de setores (no sentido de endereços lógicos do CD).

      // Se quiser o tamanho total em bytes para leitura RAW (2352 bytes por setor):
      // int totalBytes = leadOutLba * 2352;
      // Caso queira o tamanho em bytes padrão (CD modo 1 -> 2048 bytes/sector):

      calloc.free(tocBuffer);
      calloc.free(bytesReturned);

      return leadOutLba;
    } finally {
      closeHandle(handleDevice);
    }
  }
}
