import 'dart:ffi';
import 'package:ffi/ffi.dart';

/// A zero value; used to represent an empty bitmask.
const NULL = 0;

/// Boolean false value returned from the Win32 API
const FALSE = 0;

/// Boolean true value returned from the Win32 API
const TRUE = 1;

// Path length
const MAX_PATH = 260;

/// Incorrect function.
const ERROR_INVALID_FUNCTION = 1;

/// The system cannot find the file specified.
const ERROR_FILE_NOT_FOUND = 2;

/// The system cannot find the path specified.
const ERROR_PATH_NOT_FOUND = 3;

/// The system cannot open the file.
const ERROR_TOO_MANY_OPEN_FILES = 4;

/// Access is denied.
const ERROR_ACCESS_DENIED = 5;

/// The handle is invalid.
const ERROR_INVALID_HANDLE = 6;

const ERROR_ALREADY_EXISTS = 183;

const FILE_SHARE_READ = 0x00000001;
const FILE_SHARE_WRITE = 0x00000002;
const FILE_SHARE_DELETE = 0x00000004;
const FILE_ATTRIBUTE_READONLY = 0x00000001;
const FILE_ATTRIBUTE_HIDDEN = 0x00000002;
const FILE_ATTRIBUTE_SYSTEM = 0x00000004;
const FILE_ATTRIBUTE_DIRECTORY = 0x00000010;
const FILE_ATTRIBUTE_ARCHIVE = 0x00000020;
const FILE_ATTRIBUTE_DEVICE = 0x00000040;
const FILE_ATTRIBUTE_NORMAL = 0x00000080;
const FILE_ATTRIBUTE_TEMPORARY = 0x00000100;
const FILE_ATTRIBUTE_SPARSE_FILE = 0x00000200;
const FILE_ATTRIBUTE_REPARSE_POINT = 0x00000400;
const FILE_ATTRIBUTE_COMPRESSED = 0x00000800;
const FILE_ATTRIBUTE_OFFLINE = 0x00001000;
const FILE_ATTRIBUTE_NOT_CONTENT_INDEXED = 0x00002000;
const FILE_ATTRIBUTE_ENCRYPTED = 0x00004000;
const FILE_ATTRIBUTE_INTEGRITY_STREAM = 0x00008000;
const FILE_ATTRIBUTE_VIRTUAL = 0x00010000;
const FILE_ATTRIBUTE_NO_SCRUB_DATA = 0x00020000;
const FILE_ATTRIBUTE_EA = 0x00040000;
const FILE_ATTRIBUTE_PINNED = 0x00080000;
const FILE_ATTRIBUTE_UNPINNED = 0x00100000;
const FILE_ATTRIBUTE_RECALL_ON_OPEN = 0x00040000;
const FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS = 0x00400000;
const TREE_CONNECT_ATTRIBUTE_PRIVACY = 0x00004000;
const TREE_CONNECT_ATTRIBUTE_INTEGRITY = 0x00008000;
const TREE_CONNECT_ATTRIBUTE_GLOBAL = 0x00000004;
const TREE_CONNECT_ATTRIBUTE_PINNED = 0x00000002;
const FILE_ATTRIBUTE_STRICTLY_SEQUENTIAL = 0x20000000;
const FILE_NOTIFY_CHANGE_FILE_NAME = 0x00000001;
const FILE_NOTIFY_CHANGE_DIR_NAME = 0x00000002;
const FILE_NOTIFY_CHANGE_ATTRIBUTES = 0x00000004;
const FILE_NOTIFY_CHANGE_SIZE = 0x00000008;
const FILE_NOTIFY_CHANGE_LAST_WRITE = 0x00000010;
const FILE_NOTIFY_CHANGE_LAST_ACCESS = 0x00000020;
const FILE_NOTIFY_CHANGE_CREATION = 0x00000040;
const FILE_NOTIFY_CHANGE_SECURITY = 0x00000100;
const FILE_ACTION_ADDED = 0x00000001;
const FILE_ACTION_REMOVED = 0x00000002;
const FILE_ACTION_MODIFIED = 0x00000003;
const FILE_ACTION_RENAMED_OLD_NAME = 0x00000004;
const FILE_ACTION_RENAMED_NEW_NAME = 0x00000005;
const MAILSLOT_NO_MESSAGE = -1;
const MAILSLOT_WAIT_FOREVER = -1;

const METHOD_BUFFERED = 0;
const METHOD_IN_DIRECT = 1;
const METHOD_OUT_DIRECT = 2;
const METHOD_NEITHER = 3;

const int FILE_DEVICE_BEEP = 0x00000001;
const int FILE_DEVICE_CD_ROM = 0x00000002;
const int FILE_DEVICE_CD_ROM_FILE_SYSTEM = 0x00000003;
const int FILE_DEVICE_CONTROLLER = 0x00000004;
const int FILE_DEVICE_DATALINK = 0x00000005;
const int FILE_DEVICE_DFS = 0x00000006;
const int FILE_DEVICE_DISK = 0x00000007;
const int FILE_DEVICE_DISK_FILE_SYSTEM = 0x00000008;
const int FILE_DEVICE_FILE_SYSTEM = 0x00000009;
const int FILE_DEVICE_INPORT_PORT = 0x0000000a;
const int FILE_DEVICE_KEYBOARD = 0x0000000b;
const int FILE_DEVICE_MAILSLOT = 0x0000000c;
const int FILE_DEVICE_MIDI_IN = 0x0000000d;
const int FILE_DEVICE_MIDI_OUT = 0x0000000e;
const int FILE_DEVICE_MOUSE = 0x0000000f;
const int FILE_DEVICE_MULTI_UNC_PROVIDER = 0x00000010;
const int FILE_DEVICE_NAMED_PIPE = 0x00000011;
const int FILE_DEVICE_NETWORK = 0x00000012;
const int FILE_DEVICE_NETWORK_BROWSER = 0x00000013;
const int FILE_DEVICE_NETWORK_FILE_SYSTEM = 0x00000014;
const int FILE_DEVICE_NULL = 0x00000015;
const int FILE_DEVICE_PARALLEL_PORT = 0x00000016;
const int FILE_DEVICE_PHYSICAL_NETCARD = 0x00000017;
const int FILE_DEVICE_PRINTER = 0x00000018;
const int FILE_DEVICE_SCANNER = 0x00000019;
const int FILE_DEVICE_SERIAL_MOUSE_PORT = 0x0000001a;
const int FILE_DEVICE_SERIAL_PORT = 0x0000001b;
const int FILE_DEVICE_SCREEN = 0x0000001c;
const int FILE_DEVICE_SOUND = 0x0000001d;
const int FILE_DEVICE_STREAMS = 0x0000001e;
const int FILE_DEVICE_TAPE = 0x0000001f;
const int FILE_DEVICE_TAPE_FILE_SYSTEM = 0x00000020;
const int FILE_DEVICE_TRANSPORT = 0x00000021;
const int FILE_DEVICE_UNKNOWN = 0x00000022;
const int FILE_DEVICE_VIDEO = 0x00000023;
const int FILE_DEVICE_VIRTUAL_DISK = 0x00000024;
const int FILE_DEVICE_WAVE_IN = 0x00000025;
const int FILE_DEVICE_WAVE_OUT = 0x00000026;
const int FILE_DEVICE_8042_PORT = 0x00000027;
const int FILE_DEVICE_NETWORK_REDIRECTOR = 0x00000028;
const int FILE_DEVICE_BATTERY = 0x00000029;
const int FILE_DEVICE_BUS_EXTENDER = 0x0000002a;
const int FILE_DEVICE_MODEM = 0x0000002b;
const int FILE_DEVICE_VDM = 0x0000002c;
const int FILE_DEVICE_MASS_STORAGE = 0x0000002d;
const int FILE_DEVICE_SMB = 0x0000002e;
const int FILE_DEVICE_KS = 0x0000002f;
const int FILE_DEVICE_CHANGER = 0x00000030;
const int FILE_DEVICE_SMARTCARD = 0x00000031;
const int FILE_DEVICE_ACPI = 0x00000032;
const int FILE_DEVICE_DVD = 0x00000033;
const int FILE_DEVICE_FULLSCREEN_VIDEO = 0x00000034;
const int FILE_DEVICE_DFS_FILE_SYSTEM = 0x00000035;
const int FILE_DEVICE_DFS_VOLUME = 0x00000036;
const int FILE_DEVICE_SERENUM = 0x00000037;
const int FILE_DEVICE_TERMSRV = 0x00000038;
const int FILE_DEVICE_KSEC = 0x00000039;
const int FILE_DEVICE_FIPS = 0x0000003A;
const int FILE_DEVICE_INFINIBAND = 0x0000003B;
const int FILE_DEVICE_VMBUS = 0x0000003E;
const int FILE_DEVICE_CRYPT_PROVIDER = 0x0000003F;
const int FILE_DEVICE_WPD = 0x00000040;
const int FILE_DEVICE_BLUETOOTH = 0x00000041;
const int FILE_DEVICE_MT_COMPOSITE = 0x00000042;
const int FILE_DEVICE_MT_TRANSPORT = 0x00000043;
const int FILE_DEVICE_BIOMETRIC = 0x00000044;
const int FILE_DEVICE_PMI = 0x00000045;
const int FILE_DEVICE_EHSTOR = 0x00000046;
const int FILE_DEVICE_DEVAPI = 0x00000047;
const int FILE_DEVICE_GPIO = 0x00000048;
const int FILE_DEVICE_USBEX = 0x00000049;
const int FILE_DEVICE_CONSOLE = 0x00000050;
const int FILE_DEVICE_NFP = 0x00000051;
const int FILE_DEVICE_SYSENV = 0x00000052;
const int FILE_DEVICE_VIRTUAL_BLOCK = 0x00000053;
const int FILE_DEVICE_POINT_OF_SERVICE = 0x00000054;
const int FILE_DEVICE_STORAGE_REPLICATION = 0x00000055;
const int FILE_DEVICE_TRUST_ENV = 0x00000056;
const int FILE_DEVICE_UCM = 0x00000057;
const int FILE_DEVICE_UCMTCPCI = 0x00000058;
const int FILE_DEVICE_PERSISTENT_MEMORY = 0x00000059;
const int FILE_DEVICE_NVDIMM = 0x0000005a;
const int FILE_DEVICE_HOLOGRAPHIC = 0x0000005b;
const int FILE_DEVICE_SDFXHCI = 0x0000005c;
const int FILE_DEVICE_UCMUCSI = 0x0000005d;
const int FILE_DEVICE_PRM = 0x0000005e;
const int FILE_DEVICE_EVENT_COLLECTOR = 0x0000005f;
const int FILE_DEVICE_USB4 = 0x00000060;
const int FILE_DEVICE_SOUNDWIRE = 0x00000061;

// Handles
const INVALID_HANDLE_VALUE = -1;
const ATTACH_PARENT_PROCESS = -1;
const FOREGROUND_BLUE = 0x0001;
const FOREGROUND_GREEN = 0x0002;
const FOREGROUND_RED = 0x0004;
const FOREGROUND_INTENSITY = 0x0008;
const BACKGROUND_BLUE = 0x0010;
const BACKGROUND_GREEN = 0x0020;
const BACKGROUND_RED = 0x0040;
const BACKGROUND_INTENSITY = 0x0080;

/// Creates a new file, always.
const CREATE_ALWAYS = 2;

// Estilos para barras de rolagem
const int SBS_AUTOTICKS = 0x0010;
const int SBS_VERT = 0x0001;
const int SBS_HORZ = 0x0000;

// Constantes de sistema para obter métricas
const int SM_CXVSCROLL = 0x0275;
const int SM_CYHSCROLL = 0x0276;

const int NULL_BRUSH = 5; // CBRUSH(5) corresponde a NULL_BRUSH

// Mensagens de controle de barra de rolagem
const int SBM_SETRANGE = 0x00B1;
const int SBM_SETSCROLLPOS = 0x00E0;
const int SBM_SETSCROLLINFO = 0x00E9;
const int SBM_SETPOS = 0x00C0;
const int SBM_GETPOS = 0x00C0;

// Mensagens de rolagem
const int WM_VSCROLL = 0x0115;
const int WM_HSCROLL = 0x0114;

// Códigos de rolagem
const int SB_LINEUP = 0;
const int SB_LINEDOWN = 1;
const int SB_PAGEUP = 2;
const int SB_PAGEDOWN = 3;
const int SB_THUMBTRACK = 5;
const int SB_THUMBPOSITION = 4;

const int SIF_RANGE = 0x0001;
const int SIF_PAGE = 0x0002;
const int SIF_POS = 0x0004;
const int SIF_TRACKPOS = 0x0010;
const int SIF_ALL = SIF_RANGE | SIF_PAGE | SIF_POS | SIF_TRACKPOS;

const int RET_OK = 1; // valor esperado para sucesso
const int BS_PUSHBUTTON = 0x00000000;
const int BS_OWNERDRAW = 0x0000000B;
const int WM_CREATE = 0x0001;
const int WM_COMMAND = 0x0111;
const int WM_DESTROY = 0x0002;
const int WM_NOTIFY = 0x004E;
const int WM_CLOSE = 0x0010;
const WM_CTLCOLOREDIT = 0x0133;
const CB_GETLBTEXT = 0x0148;
const CB_ADDSTRING = 0x0143;
const CBS_DROPDOWNLIST = 0x0003;
const CB_GETCURSEL = 0x0147;

/// Sets the text of a window.
const WM_SETTEXT = 0x000C;

/// The window has a thin-line border.
const WS_BORDER = 0x00800000;

const ES_MULTILINE = 0x0004;

/// The window has a vertical scroll bar.
const WS_VSCROLL = 0x00200000;

/// The window has a horizontal scroll bar.
const WS_HSCROLL = 0x00100000;

/// Automatically scrolls text up one page when the user presses the ENTER key
/// on the last line.
const ES_AUTOVSCROLL = 0x0040;

/// Automatically scrolls text to the right by 10 characters when the user types
/// a character at the end of the line. When the user presses the ENTER key, the
/// control scrolls all text back to position zero.
const ES_AUTOHSCROLL = 0x0080;

const CW_USEDEFAULT = 0x80000000;

/// The window has a title bar (includes the WS_BORDER style).
const WS_CAPTION = 0x00C00000;

/// The window is a child window. A window with this style cannot have a menu
/// bar. This style cannot be used with the WS_POPUP style.
const WS_CHILD = 0x40000000;

/// The window has a window menu on its title bar. The WS_CAPTION style must
/// also be specified.
const WS_SYSMENU = 0x00080000;

/// The window has a sizing border. Same as the WS_SIZEBOX style.
const WS_THICKFRAME = 0x00040000;

/// The window has a minimize button. Cannot be combined with the
/// WS_EX_CONTEXTHELP style. The WS_SYSMENU style must also be specified.
const WS_MINIMIZEBOX = 0x00020000;

/// The window has a maximize button. Cannot be combined with the
/// WS_EX_CONTEXTHELP style. The WS_SYSMENU style must also be specified.
const WS_MAXIMIZEBOX = 0x00010000;

/// The window is an overlapped window. An overlapped window has a title bar and
/// a border. Same as the WS_TILED style.
const WS_OVERLAPPED = 0x00000000;

/// The window is an overlapped window. Same as the WS_TILEDWINDOW style.
const WS_OVERLAPPEDWINDOW = WS_OVERLAPPED |
    WS_CAPTION |
    WS_SYSMENU |
    WS_THICKFRAME |
    WS_MINIMIZEBOX |
    WS_MAXIMIZEBOX;

/// Redraws the entire window if a movement or size adjustment changes the
/// height of the client area.
const CS_VREDRAW = 0x0001;

/// Redraws the entire window if a movement or size adjustment changes the width
/// of the client area.
const CS_HREDRAW = 0x0002;

// Background modes
const TRANSPARENT = 1;
const OPAQUE = 2;
const BKMODE_LAST = 2;

const PS_SOLID = 0;
// Valor padrão para eventos customizados.
const int NM_CUSTOMDRAW = -12;
const int CDIS_SELECTED = 0x0001;
const int CDIS_HOT = 0x0002;

// Retorno padrão para desenho customizado
const int CDRF_DODEFAULT = 0x00000000;
// Constantes para bordas arredondadas
const int PS_INSIDEFRAME = 6;
// para desenho customizado
const int WM_DRAWITEM = 0x002B;
const int WM_CTLCOLORBTN = 0x0135;

// Adicione a mensagem WM_SETFONT
const WM_SETFONT = 0x0030;

const int WS_VISIBLE = 0x10000000;
const DT_CENTER = 0x00000001;
const DT_VCENTER = 0x00000004;
const DT_SINGLELINE = 0x00000020;

const ODS_SELECTED = 0x0001;
const ODS_HOTLIGHT = 0x0040;
const BN_CLICKED = 0;

// Estilos do Label
const int SS_LEFT = 0x00000000;
const int SS_CENTER = 0x00000001;
const int SS_RIGHT = 0x00000002;

// Mensagens para controles estáticos
const int WM_CTLCOLORSTATIC = 0x0138;

// Cores  Valor padrão para cores do sistema
const int COLOR_WINDOW = 5;
const int COLOR_BTNFACE = 15;

// Estilos da Barra de Progresso
const int PBS_SMOOTH = 0x01;
const int PBS_MARQUEE = 0x08;

// Mensagens da Barra de Progresso
const int PBM_SETRANGE = 0x0400 + 1;
const int PBM_SETPOS = 0x0400 + 2;
const int PBM_SETMARQUEE = 0x0400 + 10;

const int IOCTL_STORAGE_LOAD_MEDIA = 2967564;

const int GENERIC_READ = 0x80000000;
const int GENERIC_WRITE = 0x40000000;
const int OPEN_EXISTING = 3;
const int IOCTL_STORAGE_EJECT_MEDIA = 2967560;

const int WM_DEVICECHANGE = 0x0219;

/// The following messages are for WM_DEVICECHANGE. The immediate list
/// is for the wParam. ALL THESE MESSAGES PASS A POINTER TO A STRUCT
/// STARTING WITH A DWORD SIZE AND HAVING NO POINTER IN THE STRUCT.
const int DBT_DEVICEARRIVAL = 0x8000; // system detected a new device
const int DBT_DEVICEQUERYREMOVE = 0x8001; // wants to remove, may fail
const int DBT_DEVICEQUERYREMOVEFAILED = 0x8002; // removal aborted
const int DBT_DEVICEREMOVEPENDING = 0x8003; // about to remove, still avail.
const int DBT_DEVICEREMOVECOMPLETE = 0x8004; // device is gone
const int DBT_DEVICETYPESPECIFIC = 0x8005; // type specific event

const int DBT_DEVTYP_VOLUME = 0x00000002;
const int DBTF_MEDIA = 0x0001;

// Função MAKELPARAM
int MAKELPARAM(int low, int high) => (high << 16) | (low & 0xFFFF);

// Valores relacionados a STORAGE_PROPERTY_QUERY
const int StorageDeviceProperty = 0;
const int PropertyStandardQuery = 0;

// IOCTL_STORAGE_QUERY_PROPERTY =
// CTL_CODE(IOCTL_STORAGE_BASE, 0x500, METHOD_BUFFERED, FILE_ANY_ACCESS)
// IOCTL_STORAGE_BASE = 0x0000002d
// CTL_CODE macro: ((0x2d << 16) | (0x500 << 2))
const int IOCTL_STORAGE_QUERY_PROPERTY = (0x2d << 16) | (0x500 << 2);

/// STORAGE_PROPERTY_QUERY structure
/// https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntddstor/ns-ntddstor-_storage_property_query
base class STORAGE_PROPERTY_QUERY extends Struct {
  @Uint32()
  external int PropertyId; // STORAGE_PROPERTY_ID (int)

  @Uint32()
  external int QueryType; // STORAGE_QUERY_TYPE (int)

  @Uint8()
  external int
      AdditionalParameters; // Primeira posição do array AdditionalParameters[1]
}

base class TRACK_DATA extends Struct {
  @Uint8()
  external int Reserved;
  @Uint8()
  external int ControlAdr; // 4 bits Control, 4 bits ADR
  @Uint8()
  external int TrackNumber;
  @Uint8()
  external int Reserved1;
  @Uint8()
  external int Address0; // Endereço MSF: [0] deve ser 0
  @Uint8()
  external int Address1; // Minutos
  @Uint8()
  external int Address2; // Segundos
  @Uint8()
  external int Address3; // Frames
}

base class CDROM_TOC extends Struct {
  @Array<Uint8>(2)
  external Array<Uint8> Length; // Tamanho do TOC em bytes (Big-Endian)
  @Uint8()
  external int FirstTrack;
  @Uint8()
  external int LastTrack;
  @Array<TRACK_DATA>(100)
  external Array<TRACK_DATA> TrackData;
}

// STRUCTURE: STORAGE_DEVICE_DESCRIPTOR
// https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntddstor/ns-ntddstor-_storage_device_descriptor
base class STORAGE_DEVICE_DESCRIPTOR extends Struct {
  @Uint32()
  external int Version;
  @Uint32()
  external int Size;
  @Uint8()
  external int DeviceType;
  @Uint8()
  external int DeviceTypeModifier;
  @Uint8()
  external int RemovableMedia;
  @Uint8()
  external int CommandQueueing;
  @Uint32()
  external int VendorIdOffset;
  @Uint32()
  external int ProductIdOffset;
  @Uint32()
  external int ProductRevisionOffset;
  @Uint32()
  external int SerialNumberOffset;
  @Uint32()
  external int BusType; // STORAGE_BUS_TYPE enum
  @Uint32()
  external int RawPropertiesLength;
  // RawDeviceProperties[1] começa aqui, mas é variável
}

base class SCSI_PASS_THROUGH extends Struct {
  @Uint16()
  external int Length;
  @Uint8()
  external int ScsiStatus;
  @Uint8()
  external int PathId;
  @Uint8()
  external int TargetId;
  @Uint8()
  external int Lun;
  @Uint8()
  external int CdbLength;
  @Uint8()
  external int SenseInfoLength;
  @Uint8()
  external int DataIn;
  @Uint8()
  external int Reserved;
  @Uint32()
  external int DataTransferLength;
  @Uint32()
  external int TimeOutValue;
  @Uint64()
  external int DataBufferOffset; // uintptr_t
  @Uint32()
  external int SenseInfoOffset;
}

/// Contains information used in asynchronous (or overlapped) input and
/// output (I/O).
///
/// {@category struct}
base class OVERLAPPED extends Struct {
  @IntPtr()
  external int Internal;

  @IntPtr()
  external int InternalHigh;

  external _OVERLAPPED__Anonymous_e__Union Anonymous;

  @IntPtr()
  external int hEvent;
}

/// {@category struct}
sealed class _OVERLAPPED__Anonymous_e__Union extends Union {
  external _OVERLAPPED__Anonymous_e__Union__Anonymous_e__Struct Anonymous;

  external Pointer Pointer_;
}

/// {@category struct}
sealed class _OVERLAPPED__Anonymous_e__Union__Anonymous_e__Struct
    extends Struct {
  @Uint32()
  external int Offset;

  @Uint32()
  external int OffsetHigh;
}

extension OVERLAPPED__Anonymous_e__Union_Extension on OVERLAPPED {
  int get Offset => this.Anonymous.Anonymous.Offset;
  set Offset(int value) => this.Anonymous.Anonymous.Offset = value;

  int get OffsetHigh => this.Anonymous.Anonymous.OffsetHigh;
  set OffsetHigh(int value) => this.Anonymous.Anonymous.OffsetHigh = value;
}

extension OVERLAPPED_Extension on OVERLAPPED {
  _OVERLAPPED__Anonymous_e__Union__Anonymous_e__Struct get Anonymous =>
      this.Anonymous.Anonymous;
  set Anonymous(_OVERLAPPED__Anonymous_e__Union__Anonymous_e__Struct value) =>
      this.Anonymous.Anonymous = value;

  Pointer get Pointer_ => this.Anonymous.Pointer_;
  set Pointer_(Pointer value) => this.Anonymous.Pointer_ = value;
}

/// Contains the information returned by a call to the
/// GetQueuedCompletionStatusEx function.
///
/// {@category struct}
base class OVERLAPPED_ENTRY extends Struct {
  @IntPtr()
  external int lpCompletionKey;

  external Pointer<OVERLAPPED> lpOverlapped;

  @IntPtr()
  external int Internal;

  @Uint32()
  external int dwNumberOfBytesTransferred;
}

/// Contains a 64-bit value representing the number of 100-nanosecond
/// intervals since January 1, 1601 (UTC).
///
/// {@category struct}
base class FILETIME extends Struct {
  @Uint32()
  external int dwLowDateTime;

  @Uint32()
  external int dwHighDateTime;
}

/// The SECURITY_ATTRIBUTES structure contains the security descriptor for
/// an object and specifies whether the handle retrieved by specifying this
/// structure is inheritable. This structure provides security settings for
/// objects created by various functions, such as CreateFile, CreatePipe,
/// CreateProcess, RegCreateKeyEx, or RegSaveKeyEx.
///
/// {@category struct}
base class SECURITY_ATTRIBUTES extends Struct {
  @Uint32()
  external int nLength;

  external Pointer lpSecurityDescriptor;

  @Int32()
  external int bInheritHandle;
}

/// Contains information about the file that is found by the FindFirstFile,
/// FindFirstFileEx, or FindNextFile function.
///
/// {@category struct}
base class WIN32_FIND_DATA extends Struct {
  @Uint32()
  external int dwFileAttributes;

  external FILETIME ftCreationTime;

  external FILETIME ftLastAccessTime;

  external FILETIME ftLastWriteTime;

  @Uint32()
  external int nFileSizeHigh;

  @Uint32()
  external int nFileSizeLow;

  @Uint32()
  external int dwReserved0;

  @Uint32()
  external int dwReserved1;

  @Array(260)
  external Array<Uint16> _cFileName;

  String get cFileName {
    final charCodes = <int>[];
    for (var i = 0; i < 260; i++) {
      if (_cFileName[i] == 0x00) break;
      charCodes.add(_cFileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set cFileName(String value) {
    final stringToStore = value.padRight(260, '\x00');
    for (var i = 0; i < 260; i++) {
      _cFileName[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Array(14)
  external Array<Uint16> _cAlternateFileName;

  String get cAlternateFileName {
    final charCodes = <int>[];
    for (var i = 0; i < 14; i++) {
      if (_cAlternateFileName[i] == 0x00) break;
      charCodes.add(_cAlternateFileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set cAlternateFileName(String value) {
    final stringToStore = value.padRight(14, '\x00');
    for (var i = 0; i < 14; i++) {
      _cAlternateFileName[i] = stringToStore.codeUnitAt(i);
    }
  }
}

// Estruturas necessárias
base class WNDCLASSEX extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int style;

  external Pointer<NativeFunction<WndProc>> lpfnWndProc;

  @Int32()
  external int cbClsExtra;

  @Int32()
  external int cbWndExtra;

  @IntPtr()
  external int hInstance;

  @IntPtr()
  external int hIcon;

  @IntPtr()
  external int hCursor;

  @IntPtr()
  external int hbrBackground;

  external Pointer<Utf16> lpszMenuName;

  external Pointer<Utf16> lpszClassName;

  @IntPtr()
  external int hIconSm;
}

final class WNDCLASS extends Struct {
  @Uint32()
  external int style;
  external Pointer<NativeFunction<WndProc>> lpfnWndProc;
  @Int32()
  external int cbClsExtra;
  @Int32()
  external int cbWndExtra;
  @IntPtr()
  external int hInstance;
  @IntPtr()
  external int hIcon;
  @IntPtr()
  external int hCursor;
  @IntPtr()
  external int hbrBackground;
  external Pointer<Utf16> lpszMenuName;
  external Pointer<Utf16> lpszClassName;
}

final class MSG extends Struct {
  @IntPtr()
  external int hwnd;
  @Uint32()
  external int message;
  @IntPtr()
  external int wParam;
  @IntPtr()
  external int lParam;
  @Uint32()
  external int time;
  external POINT pt;
}

final class POINT extends Struct {
  @Int32()
  external int x;
  @Int32()
  external int y;
}

final class DRAWITEMSTRUCT extends Struct {
  @Uint32()
  external int CtlType;
  @Uint32()
  external int CtlID;
  @Uint32()
  external int itemID;
  @Uint32()
  external int itemAction;
  @Uint32()
  external int itemState;
  @IntPtr()
  external int hwndItem;
  @IntPtr()
  external int hDC;
  external RECT rcItem;
  @IntPtr()
  external int itemData;
}

final class RECT extends Struct {
  @Int32()
  external int left;
  @Int32()
  external int top;
  @Int32()
  external int right;
  @Int32()
  external int bottom;
}

final class NMHDR extends Struct {
  @IntPtr()
  external int hwndFrom;

  @IntPtr()
  external int idFrom;

  @Uint32()
  external int code;
}

final class NMCUSTOMDRAW extends Struct {
  external NMHDR hdr;

  @Uint32()
  external int dwDrawStage;

  @IntPtr()
  external int hdc;

  external RECT rc;

  @Uint32()
  external int dwItemSpec;

  @Uint32()
  external int uItemState;

  @IntPtr()
  external int lItemlParam;
}

/// Estruturas de cores formato RGB
final class COLORREF extends Struct {
  @Uint8()
  external int red;

  @Uint8()
  external int green;

  @Uint8()
  external int blue;

  @Uint8()
  external int reserved;
}

final class SCROLLINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int fMask;

  @Int32()
  external int nMin;

  @Int32()
  external int nMax;

  @Uint32()
  external int nPage;

  @Int32()
  external int nPos;

  @Int32()
  external int nTrackPos;
}

// Contém informações básicas sobre o dispositivo.
base class DEV_BROADCAST_HDR extends Struct {
  @Uint32()
  external int dbch_size;

  @Uint32()
  external int dbch_devicetype;

  @Uint32()
  external int dbch_reserved;
}

// Contém detalhes específicos do volume (como a unidade afetada).
base class DEV_BROADCAST_VOLUME extends Struct {
  @Uint32()
  external int dbcv_size;

  @Uint32()
  external int dbcv_devicetype;

  @Uint32()
  external int dbcv_reserved;

  @Uint32()
  external int dbcv_unitmask;

  @Uint16()
  external int dbcv_flags;
}

typedef HPEN = IntPtr;
typedef HGDIOBJ = IntPtr;
typedef LPNMHDR = Pointer<NMHDR>;
typedef LPNMCUSTOMDRAW = Pointer<NMCUSTOMDRAW>;

// Importações necessárias para a API Win32
final user32 = DynamicLibrary.open('user32.dll');
final kernel32 = DynamicLibrary.open('kernel32.dll');
final gdi32 = DynamicLibrary.open('gdi32.dll');

void free(Pointer pointer) => calloc.free(pointer);

typedef GetSystemMetricsC = Int32 Function(Int32 nIndex);
typedef GetSystemMetricsDart = int Function(int nIndex);

final getSystemMetrics =
    user32.lookupFunction<GetSystemMetricsC, GetSystemMetricsDart>(
        'GetSystemMetrics');

typedef WndProc = IntPtr Function(
    IntPtr hwnd, Uint32 uMsg, IntPtr wParam, IntPtr lParam);
typedef WndProcDart = IntPtr Function(
    IntPtr hwnd, Uint32 uMsg, IntPtr wParam, IntPtr lParam);

final getModuleHandle = kernel32.lookupFunction<
    IntPtr Function(Pointer<Utf16> lpModuleName),
    int Function(Pointer<Utf16> lpModuleName)>('GetModuleHandleW');

final registerClass = user32.lookupFunction<Uint16 Function(Pointer<WNDCLASS>),
    int Function(Pointer<WNDCLASS>)>('RegisterClassW');

int registerClassEx(Pointer<WNDCLASSEX> param0) => _registerClassEx(param0);
final _registerClassEx = user32.lookupFunction<
    Uint16 Function(Pointer<WNDCLASSEX> param0),
    int Function(Pointer<WNDCLASSEX> param0)>('RegisterClassExW');

final getLastError =
    kernel32.lookupFunction<Uint32 Function(), int Function()>('GetLastError');

final createWindowEx = user32.lookupFunction<
    IntPtr Function(
        Uint32 dwExStyle,
        Pointer<Utf16> lpClassName,
        Pointer<Utf16> lpWindowName,
        Uint32 dwStyle,
        Int32 x,
        Int32 y,
        Int32 nWidth,
        Int32 nHeight,
        IntPtr hWndParent,
        IntPtr hMenu,
        IntPtr hInstance,
        Pointer<Void> lpParam),
    int Function(
        int dwExStyle,
        Pointer<Utf16> lpClassName,
        Pointer<Utf16> lpWindowName,
        int dwStyle,
        int x,
        int y,
        int nWidth,
        int nHeight,
        int hWndParent,
        int hMenu,
        int hInstance,
        Pointer<Void> lpParam)>('CreateWindowExW');

final showWindow = user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Int32 nCmdShow),
    int Function(int hWnd, int nCmdShow)>('ShowWindow');

final updateWindow =
    user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'UpdateWindow');

final getMessage = user32.lookupFunction<
    Int32 Function(Pointer<MSG> lpMsg, IntPtr hWnd, Uint32 wMsgFilterMin,
        Uint32 wMsgFilterMax),
    int Function(Pointer<MSG> lpMsg, int hWnd, int wMsgFilterMin,
        int wMsgFilterMax)>('GetMessageW');

final dispatchMessage = user32.lookupFunction<
    IntPtr Function(Pointer<MSG> lpMsg),
    int Function(Pointer<MSG> lpMsg)>('DispatchMessageW');

final postQuitMessage = user32.lookupFunction<Void Function(Int32 nExitCode),
    void Function(int nExitCode)>('PostQuitMessage');

final getModuleHandleW = kernel32
    .lookupFunction<IntPtr Function(), int Function()>('GetModuleHandleW');

final defWindowProc = user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
    int Function(int hWnd, int Msg, int wParam, int lParam)>('DefWindowProcW');

final translateMessage = user32.lookupFunction<
    Int32 Function(Pointer<MSG> lpMsg),
    int Function(Pointer<MSG> lpMsg)>('TranslateMessage');

final getSysColorBrush = user32.lookupFunction<IntPtr Function(Int32 nIndex),
    int Function(int nIndex)>('GetSysColorBrush');

final destroyWindow =
    user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'DestroyWindow');

int getStockObject(int i) => _getStockObject(i);

final getWindowTextLengthW =
    user32.lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
        'GetWindowTextLengthW');

final _getStockObject =
    gdi32.lookupFunction<IntPtr Function(Uint32 i), int Function(int i)>(
        'GetStockObject');

final roundRect = gdi32.lookupFunction<
    Int32 Function(IntPtr hdc, Int32 left, Int32 top, Int32 right, Int32 bottom,
        Int32 width, Int32 height),
    int Function(int hdc, int left, int top, int right, int bottom, int width,
        int height)>('RoundRect');

final createPen = gdi32.lookupFunction<
    IntPtr Function(Uint32 fnPenStyle, Int32 nWidth, Uint32 crColor),
    int Function(int fnPenStyle, int nWidth, int crColor)>('CreatePen');

typedef CreateSolidBrushNative = IntPtr Function(Uint32 color);
typedef CreateSolidBrushDart = int Function(int color);

final createSolidBrush = gdi32
    .lookup<NativeFunction<CreateSolidBrushNative>>('CreateSolidBrush')
    .asFunction<CreateSolidBrushDart>();

// Preencher o fundo do botão
final fillRect = user32.lookupFunction<
    Int32 Function(IntPtr hDC, Pointer<RECT> lprc, IntPtr hbr),
    int Function(int hDC, Pointer<RECT> lprc, int hbr)>('FillRect');

// Definições de funções nativas para manipulação de cores
typedef SetBkColorNative = Uint32 Function(IntPtr hdc, Uint32 color);
typedef SetBkColorDart = int Function(int hdc, int color);
// Função para definir cor de fundo
final setBkColor = gdi32
    .lookup<NativeFunction<SetBkColorNative>>('SetBkColor')
    .asFunction<SetBkColorDart>();

typedef SetTextColorNative = Uint32 Function(IntPtr hdc, Uint32 color);
typedef SetTextColorDart = int Function(int hdc, int color);
// Função para definir cor do texto
final setTextColor = gdi32
    .lookup<NativeFunction<SetTextColorNative>>('SetTextColor')
    .asFunction<SetTextColorDart>();
// Obtém o contexto de dispositivo do controle
final getDC =
    user32.lookupFunction<IntPtr Function(IntPtr), int Function(int)>('GetDC');

typedef GetClassInfoExWNative = Int32 Function(
    IntPtr hInstance, Pointer<Utf16> lpszClass, Pointer<WNDCLASSEX> lpwcx);

typedef GetClassInfoExWDart = int Function(
    int hInstance, Pointer<Utf16> lpszClass, Pointer<WNDCLASSEX> lpwcx);

final getClassInfoEx =
    user32.lookupFunction<GetClassInfoExWNative, GetClassInfoExWDart>(
        'GetClassInfoExW');

typedef UnregisterClassWNative = Int32 Function(
    Pointer<Utf16> lpClassName, IntPtr hInstance);

typedef UnregisterClassWDart = int Function(
    Pointer<Utf16> lpClassName, int hInstance);

final unregisterClass =
    user32.lookupFunction<UnregisterClassWNative, UnregisterClassWDart>(
        'UnregisterClassW');

final sendMessageW = user32.lookupFunction<
    IntPtr Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam),
    int Function(int hWnd, int Msg, int wParam, int lParam)>('SendMessageW');
// Define a função CreateFont para manipular fontes
final createFont = gdi32.lookupFunction<
    IntPtr Function(
        Int32 nHeight,
        Int32 nWidth,
        Int32 nEscapement,
        Int32 nOrientation,
        Int32 fnWeight,
        Uint32 fdwItalic,
        Uint32 fdwUnderline,
        Uint32 fdwStrikeOut,
        Uint32 fdwCharSet,
        Uint32 fdwOutputPrecision,
        Uint32 fdwClipPrecision,
        Uint32 fdwQuality,
        Uint32 fdwPitchAndFamily,
        Pointer<Utf16> lpszFace),
    int Function(
        int nHeight,
        int nWidth,
        int nEscapement,
        int nOrientation,
        int fnWeight,
        int fdwItalic,
        int fdwUnderline,
        int fdwStrikeOut,
        int fdwCharSet,
        int fdwOutputPrecision,
        int fdwClipPrecision,
        int fdwQuality,
        int fdwPitchAndFamily,
        Pointer<Utf16> lpszFace)>('CreateFontW');

typedef SelectObjectNative = IntPtr Function(IntPtr hdc, IntPtr h);
typedef SelectObjectDart = int Function(int hdc, int h);
// Associa o pincel ao contexto de dispositivo
final selectObject = gdi32
    .lookup<NativeFunction<SelectObjectNative>>('SelectObject')
    .asFunction<SelectObjectDart>();

final deleteObject = gdi32.lookupFunction<Int32 Function(IntPtr hObject),
    int Function(int hObject)>('DeleteObject');

final getWindowText = user32.lookupFunction<
    Int32 Function(IntPtr hWnd, Pointer<Utf16> lpString, Int32 nMaxCount),
    int Function(
        int hWnd, Pointer<Utf16> lpString, int nMaxCount)>('GetWindowTextW');
// Definir alinhamento do texto
final drawText = user32.lookupFunction<
    Int32 Function(IntPtr hDC, Pointer<Utf16> lpchText, Int32 cchText,
        Pointer<RECT> lprc, Uint32 format),
    int Function(int hDC, Pointer<Utf16> lpchText, int cchText,
        Pointer<RECT> lprc, int format)>('DrawTextW');

final createCompatibleDC =
    gdi32.lookupFunction<IntPtr Function(IntPtr hdc), int Function(int hdc)>(
        'CreateCompatibleDC');

final createCompatibleBitmap = gdi32.lookupFunction<
    IntPtr Function(IntPtr hdc, Int32 width, Int32 height),
    int Function(int hdc, int width, int height)>('CreateCompatibleBitmap');

final createPatternBrush = gdi32.lookupFunction<IntPtr Function(IntPtr hBitmap),
    int Function(int hBitmap)>('CreatePatternBrush');

final deleteDC =
    gdi32.lookupFunction<Int32 Function(IntPtr hdc), int Function(int hdc)>(
        'DeleteDC');

int setBkMode(int hdc, int mode) => _setBkMode(hdc, mode);

final _setBkMode = gdi32.lookupFunction<Int32 Function(IntPtr hdc, Uint32 mode),
    int Function(int hdc, int mode)>('SetBkMode');

int rectangle(int hdc, int left, int top, int right, int bottom) =>
    _rectangle(hdc, left, top, right, bottom);

final _rectangle = gdi32.lookupFunction<
    Int32 Function(
        IntPtr hdc, Int32 left, Int32 top, Int32 right, Int32 bottom),
    int Function(
        int hdc, int left, int top, int right, int bottom)>('Rectangle');

final _winmm = DynamicLibrary.open('winmm.dll');

/// The mciSendString function sends a command string to an MCI device. The
/// device that the command is sent to is specified in the command string.
///
/// ```c
/// MCIERROR mciSendStringW(
///   LPCTSTR lpszCommand,
///   LPTSTR  lpszReturnString,
///   UINT    cchReturn,
///   HANDLE  hwndCallback
/// );
/// ```
/// {@category winmm}
int mciSendString(Pointer<Utf16> lpstrCommand, Pointer<Utf16> lpstrReturnString,
        int uReturnLength, int hwndCallback) =>
    _mciSendString(
        lpstrCommand, lpstrReturnString, uReturnLength, hwndCallback);

final _mciSendString = _winmm.lookupFunction<
    Uint32 Function(
        Pointer<Utf16> lpstrCommand,
        Pointer<Utf16> lpstrReturnString,
        Uint32 uReturnLength,
        IntPtr hwndCallback),
    int Function(Pointer<Utf16> lpstrCommand, Pointer<Utf16> lpstrReturnString,
        int uReturnLength, int hwndCallback)>('mciSendStringW');

/// Extrai o valor LOWORD de um DWORD
int LOWORD(int l) => l & 0xFFFF;

/// Extrai o valor HIWORD de um DWORD
int HIWORD(int l) => (l >> 16) & 0xFFFF;

final logicalDrives = kernel32.lookupFunction<
    Uint32 Function(Uint32, Pointer<Utf16>),
    int Function(int, Pointer<Utf16>)>('GetLogicalDrives');

final getDriveType = kernel32.lookupFunction<Uint32 Function(Pointer<Utf16>),
    int Function(Pointer<Utf16>)>('GetDriveTypeW');

/// BOOL GetDiskFreeSpaceExA(
///   [in, optional]  LPCSTR          lpDirectoryName,
///   [out, optional] PULARGE_INTEGER lpFreeBytesAvailableToCaller,
///   [out, optional] PULARGE_INTEGER lpTotalNumberOfBytes,
///   [out, optional] PULARGE_INTEGER lpTotalNumberOfFreeBytes
/// );
final getDiskFreeSpaceEx = kernel32.lookupFunction<
    Int32 Function(
        Pointer<Utf16>, Pointer<Uint64>, Pointer<Uint64>, Pointer<Uint64>),
    int Function(Pointer<Utf16>, Pointer<Uint64>, Pointer<Uint64>,
        Pointer<Uint64>)>('GetDiskFreeSpaceExW');

typedef CreateFileC = IntPtr Function(
    Pointer<Utf16> lpFileName,
    Uint32 dwDesiredAccess,
    Uint32 dwShareMode,
    Pointer<Void> lpSecurityAttributes,
    Uint32 dwCreationDisposition,
    Uint32 dwFlagsAndAttributes,
    IntPtr hTemplateFile);
typedef CreateFileDart = int Function(
    Pointer<Utf16> lpFileName,
    int dwDesiredAccess,
    int dwShareMode,
    Pointer<Void> lpSecurityAttributes,
    int dwCreationDisposition,
    int dwFlagsAndAttributes,
    int hTemplateFile);

final CreateFileDart createFile =
    kernel32.lookup<NativeFunction<CreateFileC>>('CreateFileW').asFunction();

// Definição para DeviceIoControl
typedef DeviceIoControl_C = Bool Function(
  IntPtr hDevice,
  Uint32 dwIoControlCode,
  Pointer<Void> lpInBuffer,
  Uint32 nInBufferSize,
  Pointer<Void> lpOutBuffer,
  Uint32 nOutBufferSize,
  Pointer<Uint32> lpBytesReturned,
  Pointer<Void> lpOverlapped,
);
typedef DeviceIoControl_Dart = bool Function(
  int hDevice,
  int dwIoControlCode,
  Pointer<Void> lpInBuffer,
  int nInBufferSize,
  Pointer<Void> lpOutBuffer,
  int nOutBufferSize,
  Pointer<Uint32> lpBytesReturned,
  Pointer<Void> lpOverlapped,
);

final DeviceIoControl_Dart deviceIoControl = kernel32
    .lookup<NativeFunction<DeviceIoControl_C>>('DeviceIoControl')
    .asFunction();

typedef CloseHandle_C = Bool Function(IntPtr hObject);
typedef CloseHandle_Dart = bool Function(int hObject);

final CloseHandle_Dart closeHandle =
    kernel32.lookup<NativeFunction<CloseHandle_C>>('CloseHandle').asFunction();

int peekMessage(Pointer<MSG> lpMsg, int hWnd, int wMsgFilterMin,
        int wMsgFilterMax, int wRemoveMsg) =>
    _PeekMessage(lpMsg, hWnd, wMsgFilterMin, wMsgFilterMax, wRemoveMsg);

final _PeekMessage = user32.lookupFunction<
    Int32 Function(Pointer<MSG> lpMsg, IntPtr hWnd, Uint32 wMsgFilterMin,
        Uint32 wMsgFilterMax, Uint32 wRemoveMsg),
    int Function(Pointer<MSG> lpMsg, int hWnd, int wMsgFilterMin,
        int wMsgFilterMax, int wRemoveMsg)>('PeekMessageW');

/// Moves the file pointer of the specified file.
///
/// ```c
/// BOOL SetFilePointerEx(
///   HANDLE         hFile,
///   LARGE_INTEGER  liDistanceToMove,
///   PLARGE_INTEGER lpNewFilePointer,
///   DWORD          dwMoveMethod
/// );
/// ```
/// {@category kernel32}
int setFilePointerEx(int hFile, int liDistanceToMove,
        Pointer<Int64> lpNewFilePointer, int dwMoveMethod) =>
    _SetFilePointerEx(hFile, liDistanceToMove, lpNewFilePointer, dwMoveMethod);

final _SetFilePointerEx = kernel32.lookupFunction<
    Int32 Function(IntPtr hFile, Int64 liDistanceToMove,
        Pointer<Int64> lpNewFilePointer, Uint32 dwMoveMethod),
    int Function(int hFile, int liDistanceToMove,
        Pointer<Int64> lpNewFilePointer, int dwMoveMethod)>('SetFilePointerEx');

/// Reads data from the specified file or input/output (I/O) device. Reads
/// occur at the position specified by the file pointer if supported by the
/// device.
///
/// ```c
/// BOOL ReadFile(
///   HANDLE       hFile,
///   LPVOID       lpBuffer,
///   DWORD        nNumberOfBytesToRead,
///   LPDWORD      lpNumberOfBytesRead,
///   LPOVERLAPPED lpOverlapped
/// );
/// ```
/// {@category kernel32}
int readFile(
        int hFile,
        Pointer<Uint8> lpBuffer,
        int nNumberOfBytesToRead,
        Pointer<Uint32> lpNumberOfBytesRead,
        Pointer<OVERLAPPED> lpOverlapped) =>
    _ReadFile(hFile, lpBuffer, nNumberOfBytesToRead, lpNumberOfBytesRead,
        lpOverlapped);

final _ReadFile = kernel32.lookupFunction<
    Int32 Function(
        IntPtr hFile,
        Pointer<Uint8> lpBuffer,
        Uint32 nNumberOfBytesToRead,
        Pointer<Uint32> lpNumberOfBytesRead,
        Pointer<OVERLAPPED> lpOverlapped),
    int Function(
        int hFile,
        Pointer<Uint8> lpBuffer,
        int nNumberOfBytesToRead,
        Pointer<Uint32> lpNumberOfBytesRead,
        Pointer<OVERLAPPED> lpOverlapped)>('ReadFile');

/// Writes data to the specified file or input/output (I/O) device.
///
/// ```c
/// BOOL WriteFile(
///   HANDLE       hFile,
///   LPCVOID      lpBuffer,
///   DWORD        nNumberOfBytesToWrite,
///   LPDWORD      lpNumberOfBytesWritten,
///   LPOVERLAPPED lpOverlapped
/// );
/// ```
/// {@category kernel32}
int writeFile(
        int hFile,
        Pointer<Uint8> lpBuffer,
        int nNumberOfBytesToWrite,
        Pointer<Uint32> lpNumberOfBytesWritten,
        Pointer<OVERLAPPED> lpOverlapped) =>
    _WriteFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten,
        lpOverlapped);

final _WriteFile = kernel32.lookupFunction<
    Int32 Function(
        IntPtr hFile,
        Pointer<Uint8> lpBuffer,
        Uint32 nNumberOfBytesToWrite,
        Pointer<Uint32> lpNumberOfBytesWritten,
        Pointer<OVERLAPPED> lpOverlapped),
    int Function(
        int hFile,
        Pointer<Uint8> lpBuffer,
        int nNumberOfBytesToWrite,
        Pointer<Uint32> lpNumberOfBytesWritten,
        Pointer<OVERLAPPED> lpOverlapped)>('WriteFile');

int findFirstFile(
        Pointer<Utf16> lpFileName, Pointer<WIN32_FIND_DATA> lpFindFileData) =>
    _FindFirstFile(lpFileName, lpFindFileData);

final _FindFirstFile = kernel32.lookupFunction<
    IntPtr Function(
        Pointer<Utf16> lpFileName, Pointer<WIN32_FIND_DATA> lpFindFileData),
    int Function(Pointer<Utf16> lpFileName,
        Pointer<WIN32_FIND_DATA> lpFindFileData)>('FindFirstFileW');

/// Creates a new directory. If the underlying file system supports security
/// on files and directories, the function applies a specified security
/// descriptor to the new directory.
///
/// ```c
/// BOOL CreateDirectoryW(
///   LPCWSTR               lpPathName,
///   LPSECURITY_ATTRIBUTES lpSecurityAttributes
/// );
/// ```
/// {@category kernel32}
int createDirectory(Pointer<Utf16> lpPathName,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes) =>
    _CreateDirectory(lpPathName, lpSecurityAttributes);

final _CreateDirectory = kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpPathName,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes),
    int Function(Pointer<Utf16> lpPathName,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes)>('CreateDirectoryW');

/// Continues a file search from a previous call to the FindFirstFile,
/// FindFirstFileEx, or FindFirstFileTransacted functions.
///
/// ```c
/// BOOL FindNextFileW(
///   HANDLE             hFindFile,
///   LPWIN32_FIND_DATAW lpFindFileData
/// );
/// ```
/// {@category kernel32}
int findNextFile(int hFindFile, Pointer<WIN32_FIND_DATA> lpFindFileData) =>
    _FindNextFile(hFindFile, lpFindFileData);

final _FindNextFile = kernel32.lookupFunction<
    Int32 Function(IntPtr hFindFile, Pointer<WIN32_FIND_DATA> lpFindFileData),
    int Function(int hFindFile,
        Pointer<WIN32_FIND_DATA> lpFindFileData)>('FindNextFileW');

// Definições de tipo para a função CopyFileW
typedef CopyFileWNative = Int32 Function(Pointer<Utf16> lpExistingFileName,
    Pointer<Utf16> lpNewFileName, Int32 bFailIfExists);

typedef CopyFileWDart = int Function(Pointer<Utf16> lpExistingFileName,
    Pointer<Utf16> lpNewFileName, int bFailIfExists);

// Localiza a função CopyFileW na DLL
final copyFile =
    kernel32.lookupFunction<CopyFileWNative, CopyFileWDart>('CopyFileW');

/// Closes a file search handle opened by the FindFirstFile,
/// FindFirstFileEx, FindFirstFileNameW, FindFirstFileNameTransactedW,
/// FindFirstFileTransacted, FindFirstStreamTransactedW, or FindFirstStreamW
/// functions.
///
/// ```c
/// BOOL FindClose(
///   HANDLE hFindFile
/// );
/// ```
/// {@category kernel32}
int findClose(int hFindFile) => _FindClose(hFindFile);

final _FindClose = kernel32.lookupFunction<Int32 Function(IntPtr hFindFile),
    int Function(int hFindFile)>('FindClose');

/// Retrieves information about the file system and volume associated with
/// the specified root directory.
///
/// ```c
/// BOOL GetVolumeInformationW(
///   LPCWSTR lpRootPathName,
///   LPWSTR  lpVolumeNameBuffer,
///   DWORD   nVolumeNameSize,
///   LPDWORD lpVolumeSerialNumber,
///   LPDWORD lpMaximumComponentLength,
///   LPDWORD lpFileSystemFlags,
///   LPWSTR  lpFileSystemNameBuffer,
///   DWORD   nFileSystemNameSize
/// );
/// ```
/// {@category kernel32}
int getVolumeInformation(
        Pointer<Utf16> lpRootPathName,
        Pointer<Utf16> lpVolumeNameBuffer,
        int nVolumeNameSize,
        Pointer<Uint32> lpVolumeSerialNumber,
        Pointer<Uint32> lpMaximumComponentLength,
        Pointer<Uint32> lpFileSystemFlags,
        Pointer<Utf16> lpFileSystemNameBuffer,
        int nFileSystemNameSize) =>
    _GetVolumeInformation(
        lpRootPathName,
        lpVolumeNameBuffer,
        nVolumeNameSize,
        lpVolumeSerialNumber,
        lpMaximumComponentLength,
        lpFileSystemFlags,
        lpFileSystemNameBuffer,
        nFileSystemNameSize);

final _GetVolumeInformation = kernel32.lookupFunction<
    Int32 Function(
        Pointer<Utf16> lpRootPathName,
        Pointer<Utf16> lpVolumeNameBuffer,
        Uint32 nVolumeNameSize,
        Pointer<Uint32> lpVolumeSerialNumber,
        Pointer<Uint32> lpMaximumComponentLength,
        Pointer<Uint32> lpFileSystemFlags,
        Pointer<Utf16> lpFileSystemNameBuffer,
        Uint32 nFileSystemNameSize),
    int Function(
        Pointer<Utf16> lpRootPathName,
        Pointer<Utf16> lpVolumeNameBuffer,
        int nVolumeNameSize,
        Pointer<Uint32> lpVolumeSerialNumber,
        Pointer<Uint32> lpMaximumComponentLength,
        Pointer<Uint32> lpFileSystemFlags,
        Pointer<Utf16> lpFileSystemNameBuffer,
        int nFileSystemNameSize)>('GetVolumeInformationW');
