import 'dart:async';
import 'dart:ffi';
import 'package:cd_recovery/src/windows/gui2/win32_color.dart';
import 'package:ffi/ffi.dart';
import 'win32_api.dart';

class ResourceManager {
  static final finalizer = Finalizer<Win32Control>((control) {
    if (!control.isDisposed) {
      control.dispose();
    }
  });
}

Pointer<Utf16> toNativeString(String s) {
  return s.toNativeUtf16(allocator: malloc);
}

void freeNativeString(Pointer<Utf16> ptr) {
  malloc.free(ptr);
}

// Tabela global para mapear HWNDs para instâncias de Win32WindowBase
final Map<int, Win32WindowBase> windowMap = {};

// Função de callback global
int globalWindowProc(int hwnd, int uMsg, int wParam, int lParam) {
  final window = windowMap[hwnd];
  if (window != null) {
    return window.windowProc(hwnd, uMsg, wParam, lParam);
  }
  return defWindowProc(hwnd, uMsg, wParam, lParam);
}

// Enum para estado do controle
class ControlState {
  final int value;
  const ControlState(this.value);
  static const ControlState initialized = ControlState(0);
  static const ControlState created = ControlState(1);
  static const ControlState disposed = ControlState(2);
}

/// Classe base para qualquer controle Win32
abstract class Win32Control {
  static int idCount = 0;

  /// Creates a new [id] of a [Win32Window].
  static int newID() => ++idCount;

  int id;

  /// The [x] coordinate of this [Window] when created.
  int x = CW_USEDEFAULT;

  /// The [y] coordinate of this [Window] when created.
  int y = CW_USEDEFAULT;

  /// The [width] of this [Window] when created.
  int width = CW_USEDEFAULT;

  /// The [height] of this [Window] when created.
  int height = CW_USEDEFAULT;

  /// class name
  abstract String name;

  /// control Handle
  int hWnd = 0;
  int hInstance = 0;
  int parentHwnd = 0;

  ControlState state = ControlState.initialized;

  Win32Control({
    this.x = CW_USEDEFAULT,
    this.y = CW_USEDEFAULT,
    this.width = CW_USEDEFAULT,
    this.height = CW_USEDEFAULT,
  }) : id = newID();

  /// Cria o controle. Deve ser sobrescrito
  void create({required int parentHwnd, required int hInstance}) {}

  int onScrollMessage(int uMsg, int wParam, int lParam) {
    return 0;
  }

  int onCtlColorEditMessage(int uMsg, int wParam, int lParam) {
    return 0;
  }

  int onCtlColorStaticMessage(int uMsg, int wParam, int lParam) {
    return 0;
  }

  int onDrawItemMessage(int uMsg, int wParam, int lParam) {
    return 0;
  }

  int onCommandMessage(int uMsg, int wParam, int lParam) {
    return 0;
  }

  /// Destrói o controle e libera recursos
  void dispose() {
    if (state == ControlState.disposed) return;
    if (hWnd != 0) {
      // Destruir a janela do controle
      destroyWindow(hWnd);
      hWnd = 0;
    }
    state = ControlState.disposed;
    // Remove a associação do finalizer, evitando chamadas tardias.
    ResourceManager.finalizer.detach(this);
  }

  bool get isDisposed => state == ControlState.disposed;
}

class Button extends Win32Control {
  @override
  String name = 'BUTTON';

  String text;

  Win32Color bgColor;
  Win32Color bgColorSelected;
  Win32Color bgColorHotlight;
  Win32Color textColor;

  void Function() onPressed;

  Button({
    required this.text,
    super.x = 10,
    super.y = 10,
    super.width = 120,
    super.height = 30,
    required this.onPressed,
    this.bgColor = Win32Color.bgColor,
    this.bgColorSelected = Win32Color.bgColorSelected,
    this.bgColorHotlight = Win32Color.bgColorHotlight,
    this.textColor = Win32Color.textColorLight,
  });

  void create({required int parentHwnd, required int hInstance}) {
    if (isDisposed) {
      throw Exception('Tentando criar um controle já descartado.');
    }
    this.hInstance = hInstance;
    this.parentHwnd = parentHwnd;

    // BS_OWNERDRAW para desenho customizado ou  BS_PUSHBUTTON para estilo padrão
    final styleBtn = WS_VISIBLE | WS_CHILD | BS_OWNERDRAW;
    final classNamePtr = toNativeString(name);
    final textPtr = toNativeString(text);

    hWnd = createWindowEx(0, classNamePtr, textPtr, styleBtn, x, y, width,
        height, parentHwnd, id, hInstance, nullptr);

    freeNativeString(classNamePtr);
    freeNativeString(textPtr);

    if (hWnd == 0) {
      final errorCode = getLastError();
      throw Exception('Falha ao criar o botão. Erro: $errorCode');
    }
  }

  void draw(Pointer<DRAWITEMSTRUCT> pDIS) {
    final dis = pDIS.ref;
    final itemState = dis.itemState;
    late int corFundo;
    if ((itemState & ODS_SELECTED) != 0) {
      corFundo = bgColorSelected.color;
    } else if ((itemState & ODS_HOTLIGHT) != 0) {
      corFundo = bgColorHotlight.color;
    } else {
      corFundo = bgColor.color;
    }

    final hdc = dis.hDC;
    final rc = dis.rcItem;
    final rcPtr = calloc<RECT>();
    // Copia os valores de dis.rcItem para a memória recém-alocada
    rcPtr.ref.left = dis.rcItem.left;
    rcPtr.ref.top = dis.rcItem.top;
    rcPtr.ref.right = dis.rcItem.right;
    rcPtr.ref.bottom = dis.rcItem.bottom;

    final hbr = createSolidBrush(corFundo);
    fillRect(hdc, rcPtr, hbr);
    deleteObject(hbr); // Liberar o pincel após o uso

    final hPen = createPen(PS_SOLID, 3, Win32Color.rgb(0, 0, 0));
    final oldPen = selectObject(hdc, hPen);
    final oldBrush = selectObject(hdc, getStockObject(NULL_BRUSH));
    rectangle(hdc, rc.left, rc.top, rc.right, rc.bottom);
    selectObject(hdc, oldBrush);
    selectObject(hdc, oldPen);
    deleteObject(hPen); // Liberar a caneta após o uso

    setBkMode(hdc, TRANSPARENT);
    setTextColor(hdc, textColor.color);

    final textPrr = toNativeString(text);
    drawText(hdc, textPrr, -1, rcPtr, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
    free(rcPtr);
    freeNativeString(textPrr);
  }

  @override
  void dispose() {
    super.dispose();
    // Outros recursos GDI, se houver, devem ser liberados aqui
  }

  int onDrawItemMessage(int uMsg, int wParam, int lParam) {
    final drawItem = Pointer<DRAWITEMSTRUCT>.fromAddress(lParam);
    draw(drawItem);
    return 1;
  }

  int onCommandMessage(int uMsg, int wParam, int lParam) {
    //final commandId = wParam & 0xFFFF; // LOWORD
    onPressed();
    return 0;
  }
}

class DeviceChangeEventType {
  final int value;
  const DeviceChangeEventType(this.value);
  static const DeviceChangeEventType none = DeviceChangeEventType(0);
  static const DeviceChangeEventType arrival = DeviceChangeEventType(1);
  static const DeviceChangeEventType removed = DeviceChangeEventType(2);
}

class DeviceChangeEvent {
  DeviceType deviceType;
  DeviceChangeEventType eventType;
  dynamic value;
  DeviceChangeEvent(this.deviceType, this.eventType, this.value);
}

class DeviceType {
  final int value;
  const DeviceType(this.value);
  static const DeviceType none = DeviceType(-1);
  static const DeviceType volume = DeviceType(0);
  static const DeviceType interface = DeviceType(1);
  static const DeviceType net = DeviceType(2);
  static const DeviceType port = DeviceType(3);
}

class DeviceSubType {
  final int value;
  const DeviceSubType(this.value);
  static const DeviceType cd = DeviceType(0);
}

abstract class Win32WindowBase {
  static int idCount = 0;

  /// Creates a new [id] of a [Win32Window].
  static int newID() => ++idCount;

  // Mapa para armazenar os controles
  final Map<int, Win32Control> _children = {};

  static Set<String> _registeredClasses = {};

  StreamController<int> _streamControllerOnClose = StreamController.broadcast();
  Stream<int> get onClose => _streamControllerOnClose.stream;

  StreamController<DeviceChangeEvent> _stCtrlOnDeviceChange =
      StreamController.broadcast();
  Stream<DeviceChangeEvent> get onDeviceChange => _stCtrlOnDeviceChange.stream;

  StreamController<DeviceChangeEvent> _stCtrlOnCDArrival =
      StreamController.broadcast();

  Stream<DeviceChangeEvent> get onCDArrival => _stCtrlOnCDArrival.stream;

  final int id;
  String title;
  int width;
  int height;
  Win32Color bgColor;

  Win32WindowBase({
    this.title = 'window',
    this.width = 800,
    this.height = 600,
    this.bgColor = Win32Color.lightgray,
  }) : this.id = newID() {
    _create();
  }

  /// class name
  String name = 'SimpleWindowClass';

  /// control Handle
  int hWnd = 0;
  int hInstance = 0;
  ControlState state = ControlState.initialized;

  void _create();

  /// hInstance é o identificador de uma instância ou identificador para um módulo. O sistema operacional usa esse valor para identificar o executável ou EXE quando ele é carregado na memória
  int get getHInstance => getModuleHandle(nullptr);

  void addChild(Win32Control control) {
    if (hWnd == 0) {
      throw Exception(
          'você não pode adicionar controles antes de cria a janela');
    }
    control.create(parentHwnd: hWnd, hInstance: getHInstance);
    // Registra o finalizer depois de chamar o create, associando o handle da janela (hWnd)
    // ao objeto Dart. Se o objeto for GC, chamará finalizer.
    ResourceManager.finalizer.attach(control, control, detach: control);
    _children[control.hWnd] = control;
  }

  void addChildren(List<Win32Control> children) {
    for (final control in children) {
      addChild(control);
    }
  }

  /// Método auxiliar para registrar a classe de janela e retornar a estrutura WNDCLASSEX
  void _registerWindowClass(String className) {
    if (_registeredClasses.contains(className)) {
      // A classe já está registrada, verificar se está realmente registrada no sistema
      final classNamePtr = toNativeString(className);
      final wc = calloc<WNDCLASSEX>();
      final success = getClassInfoEx(getHInstance, classNamePtr, wc);
      if (success == 0) {
        final error = getLastError();
        freeNativeString(classNamePtr);
        calloc.free(wc);
        throw Exception(
            'Classe "$className" aparentemente registrada, mas GetClassInfoEx falhou. Erro: $error');
      }
      freeNativeString(classNamePtr);
      calloc.free(wc);
      return; // Já está registrada
    }

    final wc = calloc<WNDCLASSEX>();
    wc.ref.cbSize = sizeOf<WNDCLASSEX>();
    wc.ref.style = CS_HREDRAW | CS_VREDRAW;
    // TODO verificar qual opção é melhor NativeCallable ou fromFunction com statico
    // final nc = NativeCallable<WndProcDart>.isolateLocal(windowProc,
    //     exceptionalReturn: 0);
    // wc.ref.lpfnWndProc = nc.nativeFunction;
    wc.ref.lpfnWndProc = Pointer.fromFunction<WndProcDart>(globalWindowProc, 0);
    wc.ref.cbClsExtra = 0;
    wc.ref.cbWndExtra = 0;
    wc.ref.hInstance = getHInstance;
    final brushBgColor = createSolidBrush(bgColor.color);
    wc.ref.hbrBackground = brushBgColor; //getSysColorBrush(COLOR_WINDOW + 1);
    final wcClassNamePtr = toNativeString(className);
    wc.ref.lpszClassName = wcClassNamePtr;

    final atom = registerClassEx(wc);
    if (atom == 0) {
      final errorCode = getLastError();
      freeNativeString(wcClassNamePtr);
      calloc.free(wc);
      throw Exception(
          'Falha ao registrar a classe da janela "$className". Erro: $errorCode');
    } // Marcar a classe como registrada
    _registeredClasses.add(className);
    freeNativeString(wcClassNamePtr);
    calloc.free(wc);
  }

  /// Método auxiliar para desregistrar a classe de janela
  void _unregisterWindowClass(String className) {
    if (!_registeredClasses.contains(className)) {
      // A classe não estava registrada pelo nosso aplicativo
      return;
    }

    final classNamePtr = toNativeString(className);
    final success = unregisterClass(classNamePtr, getHInstance);
    if (success == 0) {
      final errorCode = getLastError();
      freeNativeString(classNamePtr);
      throw Exception(
          'Falha ao desregistrar a classe da janela "$className". Erro: $errorCode');
    }
    // Remover do conjunto de classes registradas
    _registeredClasses.remove(className);
    freeNativeString(classNamePtr);
  }

  String _firstDriveFromMask(int unitmask) {
    for (var i = 0; i < 26; i++) {
      if ((unitmask & 0x1) != 0) {
        return String.fromCharCode(65 + i); // 'A' + i
      }
      unitmask >>= 1;
    }
    return '?';
  }

  /// [wParam] HDC (handle do contexto de dispositivo)
  /// [lParam] handle da janela (HWND)
  int windowProc(int phwnd, int uMsg, int wParam, int lParam) {
    switch (uMsg) {
      case WM_DEVICECHANGE:
        final lpdb = Pointer<DEV_BROADCAST_HDR>.fromAddress(lParam);
        if (wParam == DBT_DEVICEREMOVECOMPLETE) {
          final event = DeviceChangeEvent(
              DeviceType.none, DeviceChangeEventType.removed, null);

          if (lpdb.ref.dbch_devicetype == DBT_DEVTYP_VOLUME) {
            //final lpdbv = Pointer<DEV_BROADCAST_VOLUME>.fromAddress(lpdb.address);
            final lpdbv = lpdb.cast<DEV_BROADCAST_VOLUME>();
            event.deviceType = DeviceType.volume;
            if (lpdbv.ref.dbcv_flags & DBTF_MEDIA != 0) {
              final driverLetter = _firstDriveFromMask(lpdbv.ref.dbcv_unitmask);
              event.value = driverLetter;
            }
          }
          _stCtrlOnDeviceChange.add(event);
        }
        if (wParam == DBT_DEVICEARRIVAL) {
          final event = DeviceChangeEvent(
              DeviceType.none, DeviceChangeEventType.arrival, null);
          print('DBT_DEVICEARRIVAL ');
          if (lpdb.ref.dbch_devicetype == DBT_DEVTYP_VOLUME) {
            final lpdbv = lpdb.cast<DEV_BROADCAST_VOLUME>();
            event.deviceType = DeviceType.volume;
            if (lpdbv.ref.dbcv_flags & DBTF_MEDIA != 0) {
              final driverLetter = _firstDriveFromMask(lpdbv.ref.dbcv_unitmask);
              event.value = driverLetter;
              print('DBT_DEVICEARRIVAL _stCtrlOnCDArrival');
              _stCtrlOnCDArrival.add(event);
            }
          }

          _stCtrlOnDeviceChange.add(event);
        }
        return 0;
      case WM_HSCROLL:
      case WM_VSCROLL:
        final controlHandle = lParam;
        final control = _children.containsKey(controlHandle)
            ? _children[controlHandle]
            : null;
        if (control is Win32Control) {
          return control.onScrollMessage(uMsg, wParam, lParam);
        }
        return 0;
      case WM_CTLCOLOREDIT:
        final controlHandle = lParam;
        final control = _children.containsKey(controlHandle)
            ? _children[controlHandle]
            : null;
        if (control is TextInput) {
          return control.onCtlColorEditMessage(uMsg, wParam, lParam);
        }
        return 0;
      case WM_CTLCOLORSTATIC:
        //final hdc = wParam;
        final controlHandle = lParam;
        final control = _children.containsKey(controlHandle)
            ? _children[controlHandle]
            : null;
        if (control is Label) {
          return control.onCtlColorStaticMessage(uMsg, wParam, lParam);
        }
        return defWindowProc(phwnd, uMsg, wParam, lParam);
      case WM_DRAWITEM:
        final pDrawItem = Pointer<DRAWITEMSTRUCT>.fromAddress(lParam);
        final controlHandle = pDrawItem.ref.hwndItem;
        final control = _children.containsKey(controlHandle)
            ? _children[controlHandle]
            : null;
        if (control is Button) {
          return control.onDrawItemMessage(uMsg, wParam, lParam);
        }
        return 1;
      case WM_COMMAND:
        if (lParam != 0) {
          final controlHandle = lParam;
          final control = _children[controlHandle];
          if (control != null) {
            return control.onCommandMessage(uMsg, wParam, lParam);
          }
        } else {
          // Trate comandos de menu ou outras fontes aqui, se necessário
        }
        return 0;
      case WM_DESTROY:
        windowMap.remove(phwnd);
        dispose();
        return 0;
      case WM_CLOSE:
        close();
        windowMap.remove(phwnd);
        dispose();
        return 0;
      default:
        return defWindowProc(phwnd, uMsg, wParam, lParam);
    }
  }

  void show() {
    if (hWnd == 0) {
      throw Exception('você não pode exibir antes de cria a janela');
    }
    showWindow(hWnd, 5);
  }

  void update() {
    if (hWnd == 0) {
      throw Exception('você não pode atualizar antes de cria a janela');
    }
    updateWindow(hWnd);
  }

  void dispose() {
    if (hWnd == 0) {
      throw Exception('você não pode liberar recursos antes de cria a janela');
    }
    for (final child in _children.values) {
      child.dispose();
    }
    destroyWindow(hWnd);
    _streamControllerOnClose.close();
  }

  void close() {
    if (hWnd == 0) {
      throw Exception('você não fechar antes de cria a janela');
    }
    _streamControllerOnClose.add(0);
    // Envia uma mensagem WM_QUIT para a fila de mensagens, com código de saída 0
    if (name == 'SimpleWindowClass') {
      postQuitMessage(0);
    }
  }
}

class Win32Window extends Win32WindowBase {
  @override
  String name = 'SimpleWindowClass';

  Win32Window({
    super.title = 'Window',
    super.width = 800,
    super.height = 600,
    super.bgColor = Win32Color.lightgray,
  });

  @override
  void _create() {
    // Registrar a classe se ainda não estiver registrada
    _registerWindowClass(name);

    final classNamePtr = toNativeString(name);
    final titlePtr = toNativeString(title);

    hWnd = createWindowEx(
        0,
        classNamePtr,
        titlePtr,
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        width,
        height,
        0,
        0,
        getHInstance,
        nullptr);

    freeNativeString(classNamePtr);
    freeNativeString(titlePtr);

    if (hWnd == 0) {
      final errorCode = getLastError();
      throw Exception('Falha ao criar a janela. Erro: $errorCode');
    }
    windowMap[hWnd] = this;
  }

  @override
  void dispose() {
    super.dispose();
    // Desregistrar a classe quando a janela principal for destruída
    _unregisterWindowClass(name);
  }
}

class Win32ChildWindow extends Win32WindowBase {
  @override
  String name = 'ChildWindowClass';
  int parentHwnd;

  Win32ChildWindow({
    this.parentHwnd = 0,
    super.title = 'Janela Filha',
    super.width = 400,
    super.height = 300,
  });

  void _create() {
    _registerWindowClass(name);

    final classNamePtr = toNativeString(name);
    final titlePtr = toNativeString(title);

    hWnd = createWindowEx(
        0,
        classNamePtr,
        titlePtr,
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        width,
        height,
        parentHwnd,
        0,
        getHInstance,
        nullptr);

    if (hWnd == 0) {
      final errorCode = getLastError();
      throw Exception('Falha ao criar a janela filha. Erro: $errorCode');
    }
    windowMap[hWnd] = this;

    freeNativeString(classNamePtr);
    freeNativeString(titlePtr);
  }

  @override
  void dispose() {
    super.dispose();
    _unregisterWindowClass(name);
  }
}

/// Iniciar o loop de mensagens
void runApp() {
  final msg = calloc<MSG>();
  try {
    while (getMessage(msg, 0, 0, 0) != 0) {
      translateMessage(msg);
      dispatchMessage(msg);
    }
    print('loop de mensagens exit');
  } finally {
    calloc.free(msg);
  }
}

class ProgressBar extends Win32Control {
  @override
  String name = 'msctls_progress32';

  // Estilos adicionais para a barra de progresso
  int style = PBS_SMOOTH;

  // Valores de mínimo e máximo da barra de progresso
  int min = 0;
  int max = 100;

  // Valor atual da barra de progresso
  int position = 0;

  ProgressBar({
    this.min = 0,
    this.max = 100,
    this.position = 0,
    super.x = 10,
    super.y = 50,
    super.width = 300,
    super.height = 30,
    this.style = PBS_SMOOTH,
  });

  @override
  void create({required int parentHwnd, required int hInstance}) {
    if (isDisposed) {
      throw Exception('Tentando criar um controle já descartado.');
    }
    this.hInstance = hInstance;
    this.parentHwnd = parentHwnd;
    // Estilos para a barra de progresso
    final styleProgress = WS_VISIBLE | WS_CHILD | style;
    final classNamePtr = toNativeString(name);
    // Barra de progresso não necessita de texto
    final textPtr = nullptr;

    hWnd = createWindowEx(
      0,
      classNamePtr,
      textPtr,
      styleProgress,
      x,
      y,
      width,
      height,
      parentHwnd,
      id,
      hInstance,
      nullptr,
    );

    freeNativeString(classNamePtr);
    if (hWnd == 0) {
      final errorCode = getLastError();
      throw Exception('Falha ao criar a Barra de Progresso. Erro: $errorCode');
    }
    // Configura o intervalo da barra de progresso
    sendMessageW(hWnd, PBM_SETRANGE, 0, MAKELPARAM(min, max));
    // Define a posição inicial
    sendMessageW(hWnd, PBM_SETPOS, position, 0);
    state = ControlState.created;
  }

  /// Método para definir a posição da barra de progresso
  void setPosition(int newPosition) {
    if (isDisposed) {
      throw Exception(
          'Tentando atualizar a posição de um controle descartado.');
    }
    if (hWnd == 0) {
      throw Exception(
          'Tentando atualizar a posição antes do controle ser criado.');
    }
    position = newPosition.clamp(min, max);
    sendMessageW(hWnd, PBM_SETPOS, position, 0);
  }

  /// Método para incrementar a posição da barra de progresso
  void incrementPosition([int increment = 1]) {
    setPosition(position + increment);
  }

  /// Método para definir o intervalo da barra de progresso
  void setRange(int newMin, int newMax) {
    if (isDisposed) {
      throw Exception(
          'Tentando atualizar o intervalo de um controle descartado.');
    }
    if (hWnd == 0) {
      throw Exception(
          'Tentando atualizar o intervalo antes do controle ser criado.');
    }
    min = newMin;
    max = newMax;
    sendMessageW(hWnd, PBM_SETRANGE, 0, MAKELPARAM(min, max));
    // Resetar a posição para o mínimo
    setPosition(min);
  }

  @override
  void dispose() {
    super.dispose();
    // Não há recursos adicionais para liberar neste controle
  }
}

class Label extends Win32Control {
  @override
  String name = 'STATIC';

  String text;
  Win32Color textColor;
  Win32Color bgColor;

  Label(
    this.text, {
    super.x = 10,
    super.y = 150,
    super.width = 200,
    super.height = 20,
    this.textColor = Win32Color.blue,
    this.bgColor = Win32Color.transparent,
    //this.bgColor = Win32Color.red,
  });

  @override
  void create({required int parentHwnd, required int hInstance}) {
    if (isDisposed) {
      throw Exception('Tentando criar um controle já descartado.');
    }
    this.hInstance = hInstance;
    this.parentHwnd = parentHwnd;

    // Estilos para o Label
    final styleLabel = WS_VISIBLE | WS_CHILD | SS_LEFT;

    final classNamePtr = toNativeString(name);
    final textPtr = toNativeString(text);

    hWnd = createWindowEx(
      0,
      classNamePtr,
      textPtr,
      styleLabel,
      x,
      y,
      width,
      height,
      parentHwnd,
      id,
      hInstance,
      nullptr,
    );

    freeNativeString(classNamePtr);
    freeNativeString(textPtr);

    if (hWnd == 0) {
      final errorCode = getLastError();
      throw Exception('Falha ao criar o Label. Erro: $errorCode');
    }

    state = ControlState.created;
  }

  /// Método para atualizar o texto do Label
  void setText(String newText) {
    if (isDisposed) {
      throw Exception('Tentando atualizar o texto de um controle descartado.');
    }
    if (hWnd == 0) {
      throw Exception(
          'Tentando atualizar o texto antes do controle ser criado.');
    }
    final newTextPtr = toNativeString(newText);
    final result = sendMessageW(hWnd, WM_SETTEXT, 0, newTextPtr.address);
    freeNativeString(newTextPtr);
    if (result == 0) {
      throw Exception(
          'Falha ao definir o texto do Label. Erro: ${getLastError()}');
    }
    text = newText;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  int onCtlColorStaticMessage(int uMsg, int wParam, int lParam) {
    final hdc = wParam;
    final staticControl = lParam;
    if (staticControl == hWnd) {
      // Define a cor do texto
      setTextColor(hdc, textColor.color);

      if (bgColor.isTransparent) {
        setBkMode(hdc, TRANSPARENT);
        // Verifica se é transparente
        // Retorna o handle do pincel nulo para transparência
        return getStockObject(NULL_BRUSH);
      } else {
        // Define a cor de fundo
        setBkColor(hdc, bgColor.color);
        // Retorna o handle de um pincel para a cor de fundo
        final hBrush = createSolidBrush(bgColor.color);
        return hBrush;
      }
    }
    return 0;
  }
}

class TextInput extends Win32Control {
  @override
  String name = 'EDIT';

  String initialText;

  void Function(String)? onTextChanged;
  int fontSize;
  String fontName;

  int hFont = 0;

  Win32Color bgColor = Win32Color.fromRgb(0, 0, 0);
  Win32Color textColor = Win32Color.fromRgb(255, 255, 255);
  bool isMultline = false;

  TextInput({
    this.initialText = '',
    this.isMultline = false,
    super.x = 20,
    super.y = 20,
    super.width = 200,
    super.height = 25,
    this.onTextChanged,
    this.fontSize = 16,
    this.fontName = 'Arial',
    this.bgColor = Win32Color.bgColor,
    this.textColor = Win32Color.textColorLight,
  });

  /// Método para atualizar o texto do TextInput
  set text(String newText) {
    if (isDisposed) {
      throw Exception('Tentando atualizar o texto de um controle descartado.');
    }
    if (hWnd == 0) {
      throw Exception(
          'Tentando atualizar o texto antes do controle ser criado.');
    }
    final newTextPtr = toNativeString(newText);
    final result = sendMessageW(hWnd, WM_SETTEXT, 0, newTextPtr.address);
    freeNativeString(newTextPtr);
    if (result == 0) {
      throw Exception(
          'Falha ao definir o texto do TextInput. Erro: ${getLastError()}');
    }
    initialText = newText;
  }

  @override
  void create({required int parentHwnd, required int hInstance}) {
    if (isDisposed) {
      throw Exception('Tentando criar um controle já descartado.');
    }
    this.parentHwnd = parentHwnd;
    this.hInstance = hInstance;

    var styleEdit = WS_VISIBLE | WS_CHILD | WS_BORDER;

    if (isMultline) {
      styleEdit = WS_VISIBLE |
          WS_CHILD |
          WS_BORDER |
          ES_MULTILINE |
          WS_VSCROLL |
          WS_HSCROLL |
          ES_AUTOVSCROLL |
          ES_AUTOHSCROLL;
    }

    final classNamePtr = toNativeString(name);
    final textPtr = toNativeString(initialText);

    hWnd = createWindowEx(
      0,
      classNamePtr,
      textPtr,
      styleEdit,
      x,
      y,
      width,
      height,
      parentHwnd,
      0,
      hInstance,
      nullptr,
    );

    freeNativeString(classNamePtr);
    freeNativeString(textPtr);

    if (hWnd == 0) {
      throw Exception(
          'Falha ao criar o campo de texto. Erro: ${getLastError()}');
    }

    // Cria a fonte
    final fontHeight = -fontSize;
    final fontNamePtr = toNativeString(fontName);
    // Criar a fonte com o tamanho especificado
    // Altura da fonte em lógica (negativo para pontos)
    final hFont = createFont(
      fontHeight, // Altura da fonte
      0, // Largura
      0, // Inclinação
      0, // Orientação
      400, // Peso (400 = Regular, 700 = Negrito)
      0, // Itálico
      0, // Sublinhado
      0, // Tachado
      1, // Conjunto de caracteres (1 = ANSI_CHARSET)
      0, // Precisão de saída
      0, // Precisão do recorte
      0, // Qualidade (0 = DEFAULT_QUALITY)
      0, // Pitch e família
      fontNamePtr, // Nome da fonte
    );
    freeNativeString(fontNamePtr);

    if (hFont == 0) {
      throw Exception('Falha ao criar a fonte.');
    }

    // Associa a fonte ao controle EDIT
    sendMessageW(
      hWnd,
      WM_SETFONT,
      hFont,
      1, // Redesenhar o controle
    );

    state = ControlState.created;
  }

  /// [hdc] Contexto de dispositivo do controle
  int repaint(int hdc) {
    // Define a cor do texto
    setTextColor(hdc, textColor.color);
    // Define a cor de fundo
    setBkColor(hdc, bgColor.color);
    // Retorna um pincel com a cor de fundo
    final brush = createSolidBrush(bgColor.color);
    return brush;
  }

  @override
  int onCtlColorEditMessage(int uMsg, int wParam, int lParam) {
    final hdc = wParam;
    return repaint(hdc);
  }

  int onCommandMessage(int uMsg, int wParam, int lParam) {
    final controlHandle = lParam;
    //final commandId = wParam & 0xFFFF; // LOWORD
    if (onTextChanged != null) {
      final textLength = getWindowTextLengthW(controlHandle);
      final buffer = calloc<Uint16>(textLength + 1);
      getWindowText(controlHandle, buffer.cast<Utf16>(), textLength + 1);
      final updatedText = buffer.cast<Utf16>().toDartString();
      calloc.free(buffer);
      onTextChanged!(updatedText);
    }
    return 0;
  }

  @override
  void dispose() {
    super.dispose();
    // Liberar a fonte caso tenha sido criada
    if (hFont != 0) {
      deleteObject(hFont);
      hFont = 0;
    }
  }
}

class ComboBox extends Win32Control {
  @override
  String name = 'COMBOBOX';

  List<String> items;

  void Function(String)? onItemSelected;

  ComboBox({
    required this.items,
    super.x,
    super.y,
    super.width,
    super.height,
    this.onItemSelected,
  });

  @override
  void create({required int parentHwnd, required int hInstance}) {
    if (isDisposed) {
      throw Exception('Tentando criar um controle já descartado.');
    }
    this.hInstance = hInstance;
    this.parentHwnd = parentHwnd;
    // Estilo padrão para ComboBox
    const styleComboBox = WS_VISIBLE | WS_CHILD | CBS_DROPDOWNLIST;
    final classNamePtr = toNativeString(name);
    // Criação do ComboBox
    hWnd = createWindowEx(
      0,
      classNamePtr,
      nullptr, // Sem texto inicial
      styleComboBox,
      x,
      y,
      width,
      height,
      parentHwnd, // Janela pai
      id, // Use um ID único aqui mas ID (não necessário para ComboBox)
      hInstance,
      nullptr,
    );

    freeNativeString(classNamePtr);

    if (hWnd == 0) {
      final errorCode = getLastError();
      throw Exception('Falha ao criar o ComboBox. Erro: $errorCode');
    }

    // Adiciona itens
    for (final item in items) {
      final pItemText = toNativeString(item);
      sendMessageW(hWnd, CB_ADDSTRING, 0, pItemText.address);
      freeNativeString(pItemText);
    }
    state = ControlState.created;
  }

  int onCommandMessage(int uMsg, int wParam, int lParam) {
    final notificationCode = (wParam >> 16) & 0xFFFF; // HIWORD
    final controlHandle = lParam;

    if (onItemSelected != null) {
      // Verifica se a notificação é CBN_SELCHANGE (valor 1)
      if (notificationCode == 1) {
        final selectedIndex = sendMessageW(controlHandle, CB_GETCURSEL, 0, 0);
        if (selectedIndex != -1) {
          // Aloca um buffer para o texto
          final buffer = calloc<Uint16>(256);
          sendMessageW(
            controlHandle,
            CB_GETLBTEXT,
            selectedIndex,
            buffer.address,
          );
          final selectedItem = buffer.cast<Utf16>().toDartString();
          free(buffer);
          // Chama o callback com o item selecionado
          onItemSelected!(selectedItem);
        }
      }
    }

    return 0;
  }

  @override
  void dispose() {
    super.dispose();
    // Aqui, se criássemos fontes ou pincéis para o ComboBox, os liberaríamos.
  }
}
