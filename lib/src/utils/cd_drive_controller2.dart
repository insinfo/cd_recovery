// ignore_for_file: dead_code

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

const int CDROM_READ_TOC_EX_FORMAT_TOC = 0x00;
const int CDROM_READ_TOC_EX_FORMAT_SESSION = 0x01;
const int CDROM_READ_TOC_EX_FORMAT_FULL_TOC = 0x02;
const int CDROM_READ_TOC_EX_FORMAT_PMA = 0x03;
const int CDROM_READ_TOC_EX_FORMAT_ATIP = 0x04;
const int CDROM_READ_TOC_EX_FORMAT_CDTEXT = 0x05;
const IOCTL_CDROM_READ_TOC_EX_FORMAT_FULL_TOC = 0x02;

final IOCTL_CDROM_READ_TOC_EX =
    CTL_CODE(IOCTL_CDROM_BASE, 0x0015, METHOD_BUFFERED, FILE_READ_ACCESS);

final IOCTL_CDROM_RAW_READ =
    CTL_CODE(IOCTL_CDROM_BASE, 0x000F, METHOD_OUT_DIRECT, FILE_READ_ACCESS);

final IOCTL_CDROM_READ_TOC =
    CTL_CODE(IOCTL_CDROM_BASE, 0x0000, METHOD_BUFFERED, FILE_READ_ACCESS);

final IOCTL_SCSI_PASS_THROUGH_DIRECT = CTL_CODE(IOCTL_SCSI_BASE, 0x0405,
    METHOD_BUFFERED, FILE_READ_ACCESS | FILE_WRITE_ACCESS);

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
  // A contagem de quadros do CD é de 75 frames por segundo
// O LBA 0 é definido 2 segundos antes do primeiro setor de dados (isto é, LBA = MSF(00:02:00) = -150)
// Fórmula: LBA = (M * 60 + S) * 75 + F - 150
//return ((int)M * 60 + (int)S) * 75 + (int)F - 150;
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

// Timeout padrão
const DEFAULT_TIMEOUT = 30;

// Tamanho de um setor RAW
const SECTOR_RAW_SIZE = 2352;
// Tamanho setor de dados (ISO9660)
const SECTOR_SIZE_2048 = 2048;

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

// CDROM_READ_TOC_EX INPUT
@Packed(1)
base class CDROM_READ_TOC_EX extends Struct {
  @Uint8()
  external int FormatReservedMsf; // Combinação de Format, Reserved1 e Msf

  @Uint8()
  external int SessionTrack;

  @Uint8()
  external int Reserved2;

  @Uint8()
  external int Reserved3;
}

// Funções auxiliares para extrair os campos do primeiro byte
int getFormat(int formatReservedMsf) => formatReservedMsf & 0x0F;
int getReserved1(int formatReservedMsf) => (formatReservedMsf >> 4) & 0x07;
int getMsf(int formatReservedMsf) => (formatReservedMsf >> 7) & 0x01;

// CDROM_TOC_FULL_TOC_DATA_BLOCK
@Packed(1)
base class CDROM_TOC_FULL_TOC_DATA_BLOCK extends Struct {
  @Uint8()
  external int SessionNumber;

  @Uint8()
  external int ControlAdr; // Combinação de Control e Adr

  @Uint8()
  external int Reserved1;

  @Uint8()
  external int Point;

  @Array<Uint8>(3)
  external Array<Uint8> MsfExtra;

  @Uint8()
  external int Zero;

  @Array<Uint8>(3)
  external Array<Uint8> Msf;
}

// Funções auxiliares para extrair Control e Adr
int getControl(int controlAdr) => (controlAdr >> 4) & 0x0F;
int getAdr(int controlAdr) => controlAdr & 0x0F;

// CDROM_TOC_FULL_TOC_DATA
@Packed(1)
base class CDROM_TOC_FULL_TOC_DATA extends Struct {
  @Array<Uint8>(2)
  external Array<Uint8> Length; // Length[2]

  @Uint8()
  external int FirstCompleteSession;

  @Uint8()
  external int LastCompleteSession;
}

int getControlFromBlock(CDROM_TOC_FULL_TOC_DATA_BLOCK block) {
  // 4 bits superiores
  return (block.ControlAdr >> 4) & 0x0F;
}

int getAdrFromBlock(CDROM_TOC_FULL_TOC_DATA_BLOCK block) {
  // 4 bits inferiores
  return block.ControlAdr & 0x0F;
}

int bcdToDec(int bcd) {
  return ((bcd >> 4) * 10) + (bcd & 0x0F);
}

// no c++ é assim
// size 56 SCSI_PASS_THROUGH_DIRECT do ntddscsi.h
// typedef struct _SCSI_PASS_THROUGH_DIRECT {
//     USHORT Length;
//     UCHAR ScsiStatus;
//     UCHAR PathId;
//     UCHAR TargetId;
//     UCHAR Lun;
//     UCHAR CdbLength;
//     UCHAR SenseInfoLength;
//     UCHAR DataIn;
//     ULONG DataTransferLength;
//     ULONG TimeOutValue;
//     PVOID DataBuffer;
//     ULONG SenseInfoOffset;
//     UCHAR Cdb[16];
// }SCSI_PASS_THROUGH_DIRECT, *PSCSI_PASS_THROUGH_DIRECT;
base class SCSI_PASS_THROUGH_DIRECT extends Struct {
  @Uint16()
  external int Length; // 2 bytes

  @Uint8()
  external int ScsiStatus; // 1 byte
  @Uint8()
  external int PathId; // 1 byte
  @Uint8()
  external int TargetId; // 1 byte
  @Uint8()
  external int Lun; // 1 byte
  @Uint8()
  external int CdbLength; // 1 byte
  @Uint8()
  external int SenseInfoLength; // 1 byte
  @Uint8()
  external int DataIn; // 1 byte

  @Uint32()
  external int DataTransferLength; // 4 bytes
  @Uint32()
  external int TimeOutValue; // 4 bytes

  external Pointer<Void> DataBuffer; // 8 bytes

  @Uint32()
  external int SenseInfoOffset; // 4 bytes

  @Array<Uint8>(16)
  external Array<Uint8> Cdb; // 16 bytes

  // Precise padding to reach 56 bytes
  @Uint16()
  external int _padding8; //
}

/// Função readSectorUsingREAD10
bool readSectorUsingREAD10(
    int hDevice, int LBA, Pointer<Uint8> buffer, int bufferSize) {
  if (bufferSize < SECTOR_SIZE_2048) {
    print(
        'Falha: bufferSize ($bufferSize) < SECTOR_SIZE_2048 ($SECTOR_SIZE_2048)');
    return false;
  }

  // Montando o CDB do READ(10)
  final cdb = List<int>.filled(10, 0);
  cdb[0] = 0x28; // READ(10)
  cdb[2] = (LBA >> 24) & 0xFF;
  cdb[3] = (LBA >> 16) & 0xFF;
  cdb[4] = (LBA >> 8) & 0xFF;
  cdb[5] = LBA & 0xFF;
  cdb[8] = 0x01; // Ler 1 bloco

  final senseLength = 32;
  final sptdSize = sizeOf<SCSI_PASS_THROUGH_DIRECT>() + senseLength;

  final sptdPtr = calloc<Uint8>(sptdSize);
  final sptd = sptdPtr.cast<SCSI_PASS_THROUGH_DIRECT>();

  for (int i = 0; i < 16; i++) {
    sptd.ref.Cdb[i] = (i < cdb.length) ? cdb[i] : 0;
  }

  sptd.ref.Length = sizeOf<SCSI_PASS_THROUGH_DIRECT>();
  sptd.ref.CdbLength = 10;
  sptd.ref.SenseInfoLength = senseLength;
  sptd.ref.DataIn = SCSI_IOCTL_DATA_IN;
  sptd.ref.TimeOutValue = 30; // 30 segundos
  sptd.ref.DataTransferLength = SECTOR_SIZE_2048;
  sptd.ref.DataBuffer = buffer.cast();
  sptd.ref.SenseInfoOffset = sizeOf<SCSI_PASS_THROUGH_DIRECT>();

  final bytesReturned = calloc<Uint32>();

  final result = deviceIoControl(
      hDevice,
      IOCTL_SCSI_PASS_THROUGH_DIRECT,
      sptdPtr.cast(),
      sptdSize,
      sptdPtr.cast(),
      sptdSize,
      bytesReturned,
      nullptr);

  // Agora result é bool: true = sucesso, false = falha
  final scsiStatus = sptd.ref.ScsiStatus;
  final success = (result && scsiStatus == 0);

  if (!success) {
    final lastErr = getLastError();
    print('  ScsiStatus: $scsiStatus');
    print('  GetLastError: $lastErr');
  } else {
    print('Leitura via READ(10) bem-sucedida. Dados devem estar em buffer.');
  }

  calloc.free(sptdPtr);
  calloc.free(bytesReturned);

  return success;
}

/// Função getTotalSectorsFromISO9660 (usa READ(10) no LBA 16)
int getTotalSectorsFromISO9660(int hDevice) {
  final buffer = calloc<Uint8>(SECTOR_SIZE_2048);
  final ret = readSectorUsingREAD10(hDevice, 16, buffer, SECTOR_SIZE_2048);
  print('getTotalSectorsFromISO9660 ret $ret');
  if (!ret) {
    calloc.free(buffer);
    return -1;
  }
  print('getTotalSectorsFromISO9660 ${buffer[0]}');
  // Verifica se é um PVD (Primary Volume Descriptor)
  if (buffer[0] != 1) {
    calloc.free(buffer);
    return -1;
  }

  // total blocks em offset 80 (4 bytes LE)
  final totalBlocks = buffer.elementAt(80).cast<Uint32>().value;

  calloc.free(buffer);
  return totalBlocks;
}

// Função getTotalSectorsFromReadCapacity
// Definição da estrutura combinada igual ao C++
@Packed(1)
base class SptdWithSense extends Struct {
  // Apenas para forçar cast, substituiremos por SCSI_PASS_THROUGH_DIRECT manualmente
  @Uint8()
  external int firstByteOfSptd;
  // Não podemos diretamente aninhar outra struct aqui facilmente,
  // mas podemos alocar memória manualmente. A solução simples é:
  // Alocar memória para sptd + sense juntos e interpretar manualmente.
}

// ReadCapacity não é confiavel
int getTotalSectorsFromReadCapacity(int hDevice) {
  final cdb = List<int>.filled(10, 0);
  cdb[0] = 0x25; // READ CAPACITY(10)

  final data = calloc<Uint8>(8);
  // Vamos criar um bloco de memória para sptd + sense
  // Tamanho: sptd (56 bytes) + sense (32 bytes) = 88 bytes
  final senseLength = 32;
  final sptdSize = sizeOf<SCSI_PASS_THROUGH_DIRECT>();
  final totalSize = sptdSize + senseLength;

  final sptdPtr = calloc<Uint8>(totalSize);
  final sptd = sptdPtr.cast<SCSI_PASS_THROUGH_DIRECT>();

  // Preenche CDB
  for (int i = 0; i < 10; i++) {
    sptd.ref.Cdb[i] = cdb[i];
  }

  sptd.ref.Length = sptdSize;
  sptd.ref.CdbLength = 10;
  sptd.ref.DataIn = SCSI_IOCTL_DATA_IN;
  sptd.ref.TimeOutValue = 30;
  sptd.ref.DataBuffer = data.cast();
  sptd.ref.DataTransferLength = 8;
  sptd.ref.SenseInfoLength = senseLength;
  sptd.ref.SenseInfoOffset = sptdSize; // sense data logo após SPTD

  final bytesReturned = calloc<Uint32>();

  final result = deviceIoControl(
      hDevice,
      IOCTL_SCSI_PASS_THROUGH_DIRECT,
      sptdPtr.cast(),
      totalSize,
      sptdPtr.cast(),
      totalSize,
      bytesReturned,
      nullptr);

  int totalSectors = -1;
  if (result && sptd.ref.ScsiStatus == 0) {
    // Ler lastLBA em big-endian:
    final d = data.asTypedList(8);
    final lastLBA = (d[0] << 24) | (d[1] << 16) | (d[2] << 8) | d[3];
    totalSectors = lastLBA + 1;
  } else {
    print(
        "Falha no READ CAPACITY. GetLastError: ${getLastError()} ScsiStatus: ${sptd.ref.ScsiStatus}");
  }

  calloc.free(data);
  calloc.free(sptdPtr);
  calloc.free(bytesReturned);

  return totalSectors;
}

bool isDataCDFromBlock(CDROM_TOC_FULL_TOC_DATA_BLOCK block) {
  int control = getControlFromBlock(block);
  return (control & 0x04) != 0;
}

/// Função getTotalSectorsFromFullToc retorna um tamanho menor que o IsoBuster
int getTotalSectorsFromFullToc(int hDevice) {
  // Alocar e preencher o CDROM_READ_TOC_EX
  final tocInput = calloc<CDROM_READ_TOC_EX>();
  tocInput.ref.FormatReservedMsf =
      0x02; // Format=2 (FULL TOC), Reserved1=0, Msf=0
  tocInput.ref.SessionTrack = 0;
  tocInput.ref.Reserved2 = 0;
  tocInput.ref.Reserved3 = 0;

  // Alocar buffer de saída
  final outBufferSize = 0x1000;
  final outBuffer = calloc<Uint8>(outBufferSize);

  // Alocar bytesReturned
  final bytesReturned = calloc<Uint32>();

  // Chamar DeviceIoControl

  final result = deviceIoControl(
    hDevice,
    IOCTL_CDROM_READ_TOC_EX,
    tocInput.cast(),
    sizeOf<CDROM_READ_TOC_EX>(),
    outBuffer.cast(),
    outBufferSize,
    bytesReturned,
    nullptr,
  );

  if (!result) {
    final error = getLastError();
    print('Falha ao ler FULL TOC. Erro: $error');
    calloc.free(tocInput);
    calloc.free(outBuffer);
    calloc.free(bytesReturned);
    return -1;
  }

  // Parse CDROM_TOC_FULL_TOC_DATA
  final fullTocPtr = outBuffer.cast<CDROM_TOC_FULL_TOC_DATA>();
  final dataLength = (fullTocPtr.ref.Length[0] << 8) | fullTocPtr.ref.Length[1];

  final blockSize = sizeOf<CDROM_TOC_FULL_TOC_DATA_BLOCK>();
  print('blockSize: $blockSize');

  final entryCount = dataLength ~/ blockSize;
  print('entryCount: $entryCount');

  if (entryCount == 0) {
    print('Nenhum dado retornado no FULL TOC.');
    calloc.free(tocInput);
    calloc.free(outBuffer);
    calloc.free(bytesReturned);
    return -1;
  }

  // Apontar para os blocos de dados (Descriptors)
  final descriptorsOffset = sizeOf<CDROM_TOC_FULL_TOC_DATA>();
  final blocksPtr = outBuffer
      .elementAt(descriptorsOffset)
      .cast<CDROM_TOC_FULL_TOC_DATA_BLOCK>();
  print('blocksPtr alocado em: $blocksPtr');

  // Iterar sobre os blocos e imprimir detalhes
  for (int i = 0; i < entryCount; i++) {
    final block = blocksPtr.elementAt(i).ref;
    print('Bloco $i:');
    print('  SessionNumber: ${block.SessionNumber}');
    print('  ControlAdr: ${block.ControlAdr}');
    print('  Control: ${getControl(block.ControlAdr)}');
    print('  Adr: ${getAdr(block.ControlAdr)}');
    print('  Reserved1: ${block.Reserved1}');
    print('  Point: ${block.Point}');
    print(
        '  MsfExtra: ${block.MsfExtra[0]}:${block.MsfExtra[1]}:${block.MsfExtra[2]}');
    print('  Zero: ${block.Zero}');
    print('  Msf: ${block.Msf[0]}:${block.Msf[1]}:${block.Msf[2]}');
  }

  // Procurar a primeira faixa válida (1-99)
  int firstTrackIndex = -1;
  for (int i = 0; i < entryCount; i++) {
    final block = blocksPtr.elementAt(i).ref;
    int decPoint = bcdToDec(block.Point);
    print('Verificando bloco $i: decPoint=$decPoint');
    if (decPoint >= 1 && decPoint <= 99) {
      firstTrackIndex = i;
      print('Primeira faixa válida encontrada no bloco $i');
      break;
    }
  }

  if (firstTrackIndex < 0) {
    print('Não foi possível encontrar a primeira faixa.');
    calloc.free(tocInput);
    calloc.free(outBuffer);
    calloc.free(bytesReturned);
    return -1;
  }

  final firstBlock = blocksPtr.elementAt(firstTrackIndex).ref;
  print('firstBlock:');
  print('  SessionNumber: ${firstBlock.SessionNumber}');
  print('  ControlAdr: ${firstBlock.ControlAdr}');
  print('  Control: ${getControl(firstBlock.ControlAdr)}');
  print('  Adr: ${getAdr(firstBlock.ControlAdr)}');
  print('  Reserved1: ${firstBlock.Reserved1}');
  print('  Point: ${firstBlock.Point}');
  print(
      '  MsfExtra: ${firstBlock.MsfExtra[0]}:${firstBlock.MsfExtra[1]}:${firstBlock.MsfExtra[2]}');
  print('  Zero: ${firstBlock.Zero}');
  print(
      '  Msf: ${firstBlock.Msf[0]}:${firstBlock.Msf[1]}:${firstBlock.Msf[2]}');

  bool isDataCD = (getControl(firstBlock.ControlAdr) & 0x04) != 0;
  print('isDataCD: $isDataCD');

  // Verificar se é multi-sessão
  final sessionsFound = <int>[];
  for (int i = 0; i < entryCount; i++) {
    final sess = blocksPtr.elementAt(i).ref.SessionNumber;
    if (!sessionsFound.contains(sess)) {
      sessionsFound.add(sess);
      print('Sessão encontrada: $sess');
    }
  }
  final isMultisession = (sessionsFound.length > 1);
  print('isMultisession: $isMultisession');

  // Procurar lead-out com POINT = 0xA2 (162 decimal)
  int leadOutIndex = -1;
  for (int i = entryCount - 1; i >= 0; i--) {
    final b = blocksPtr.elementAt(i).ref;
    print('Procurando lead-out no bloco $i: Point=${b.Point}');
    if (b.Point == 0xA2) {
      leadOutIndex = i;
      print('Lead-out encontrado no bloco $i');
      break;
    }
  }

  if (leadOutIndex < 0) {
    print('Não foi possível encontrar o lead-out.');
    calloc.free(tocInput);
    calloc.free(outBuffer);
    calloc.free(bytesReturned);
    return -1;
  }

  final leadOutBlock = blocksPtr.elementAt(leadOutIndex).ref;
  print('leadOutBlock:');
  print('  SessionNumber: ${leadOutBlock.SessionNumber}');
  print('  ControlAdr: ${leadOutBlock.ControlAdr}');
  print('  Control: ${getControl(leadOutBlock.ControlAdr)}');
  print('  Adr: ${getAdr(leadOutBlock.ControlAdr)}');
  print('  Reserved1: ${leadOutBlock.Reserved1}');
  print('  Point: ${leadOutBlock.Point}');
  print(
      '  MsfExtra: ${leadOutBlock.MsfExtra[0]}:${leadOutBlock.MsfExtra[1]}:${leadOutBlock.MsfExtra[2]}');
  print('  Zero: ${leadOutBlock.Zero}');
  print(
      '  Msf: ${leadOutBlock.Msf[0]}:${leadOutBlock.Msf[1]}:${leadOutBlock.Msf[2]}');

  // Converter MSF para LBA
  int M = bcdToDec(leadOutBlock.Msf[0]);
  int S = bcdToDec(leadOutBlock.Msf[1]);
  int F = bcdToDec(leadOutBlock.Msf[2]);
  print('MSF do lead-out: M=$M, S=$S, F=$F');

  int lastLBA = msfToLba(M, S, F);
  print('lastLBA calculado: $lastLBA');

  // Clean up
  calloc.free(tocInput);
  calloc.free(outBuffer);
  calloc.free(bytesReturned);

  print('== Fim getTotalSectorsFromFullToc ==');

  return lastLBA;
}

// Função readSector (similar ao C++), usando comando READ CD (0xBE)
bool readSector(int hDevice, int LBA, Pointer<Uint8> buf, bool abortOnError) {
  // CDB do READ CD (0xBE)
  final cdb = List<int>.filled(12, 0);
  cdb[0] = 0xBE;
  // LBA
  cdb[2] = (LBA >> 24) & 0xFF;
  cdb[3] = (LBA >> 16) & 0xFF;
  cdb[4] = (LBA >> 8) & 0xFF;
  cdb[5] = LBA & 0xFF;

  // 1 bloco
  cdb[8] = 0x01;

  // F8 = Sync+Header+UserData+EDC/ECC
  cdb[9] = 0xF8;

  final sptdSize = sizeOf<SCSI_PASS_THROUGH_DIRECT>() + 128;
  final sptdPtr = calloc<Uint8>(sptdSize);
  final sptd = sptdPtr.cast<SCSI_PASS_THROUGH_DIRECT>();

  sptd.ref.Length = sizeOf<SCSI_PASS_THROUGH_DIRECT>();
  sptd.ref.CdbLength = 12;
  sptd.ref.DataIn = SCSI_IOCTL_DATA_IN;
  sptd.ref.TimeOutValue = DEFAULT_TIMEOUT;
  sptd.ref.DataBuffer = buf.cast();
  sptd.ref.DataTransferLength = SECTOR_RAW_SIZE;
  sptd.ref.SenseInfoOffset = sizeOf<SCSI_PASS_THROUGH_DIRECT>();
  for (int i = 0; i < 12; i++) {
    sptd.ref.Cdb[i] = cdb[i];
  }

  final bytesReturned = calloc<Uint32>();
  final result = deviceIoControl(
      hDevice,
      IOCTL_SCSI_PASS_THROUGH_DIRECT,
      sptdPtr.cast(),
      sptdSize,
      sptdPtr.cast(),
      sptdSize,
      bytesReturned,
      nullptr);

  bool success = (result != 0 && sptd.ref.ScsiStatus == 0);
  if (!success && !abortOnError) {
    // Preenche com zeros se não abortar
    for (int i = 0; i < SECTOR_RAW_SIZE; i++) {
      buf[i] = 0;
    }
    success = true;
  }

  calloc.free(sptdPtr);
  calloc.free(bytesReturned);
  return success;
}

void main2() {
  final drivePath = '\\\\.\\E:';
  final devicePtr = drivePath.toNativeUtf16();
  final hDevice = createFile(
      devicePtr,
      GENERIC_READ | GENERIC_WRITE,
      FILE_SHARE_READ | FILE_SHARE_WRITE,
      nullptr,
      OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL,
      0);

  if (hDevice == INVALID_HANDLE_VALUE) {
    print("Falha ao abrir dispositivo. Erro: ${getLastError()}");
    return;
  }

  int totalSectorsISO = getTotalSectorsFromISO9660(hDevice);
  if (totalSectorsISO > 0) {
    print("Total de setores (via ISO9660): $totalSectorsISO");
  } else {
    print("Não foi possível obter via ISO9660 ou não é um CD de dados.");
  }

  int totalSectorsCapacity = getTotalSectorsFromReadCapacity(hDevice);
  if (totalSectorsCapacity > 0) {
    print("Total de setores (via READ CAPACITY): $totalSectorsCapacity");
  } else {
    print("Não foi possível obter via READ CAPACITY.");
  }

  int totalSectorsToc = getTotalSectorsFromFullToc(hDevice);
  if (totalSectorsToc > 0) {
    print("Total de setores (via FULL TOC): $totalSectorsToc");
  } else {
    print("Não foi possível obter via FULL TOC.");
  }

  //return;

  // Exemplo de leitura de setores raw:
  if (totalSectorsISO > 0) {
    final outputFile = File('faixa1.bin').openSync(mode: FileMode.write);
    final buf = calloc<Uint8>(SECTOR_RAW_SIZE);
    bool abortOnError = false;
    for (int LBA = 0; LBA <= totalSectorsISO; LBA++) {
      if (!readSector(hDevice, LBA, buf, abortOnError)) {
        print("Erro ao ler setor $LBA");
        if (abortOnError) {
          calloc.free(buf);
          outputFile.closeSync();
          closeHandle(hDevice);
          break;
        }
      }
      // escrever no arquivo
      final dataList = buf.asTypedList(SECTOR_RAW_SIZE);
      outputFile.writeFromSync(dataList);
      if (LBA % 1000 == 0) {
        print("Lendo LBA $LBA/$totalSectorsISO");
      }
    }
    outputFile.closeSync();
    calloc.free(buf);
    print("Extração concluída com sucesso. Arquivo: faixa1.bin");
  }

  closeHandle(hDevice);
}
