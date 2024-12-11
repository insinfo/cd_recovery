import 'dart:ffi';

import 'package:cd_recovery/src/windows/gui2/win32_api.dart';
import 'package:cd_recovery/src/windows/gui2/window_simple.dart';

enum ScrollBarOrientation { horizontal, vertical }

class ScrollBar extends Win32Control {
  @override
  String name = 'SCROLLBAR';

  ScrollBarOrientation orientation;
  int min;
  int max;
  int pageSize;
  int position;

  /// Callback para eventos de rolagem
  void Function(int newPosition)? onScroll;

  ScrollBar({
    this.orientation = ScrollBarOrientation.vertical,
    this.min = 0,
    this.max = 100,
    this.pageSize = 10,
    this.position = 0,
    super.x = 0,
    super.y = 0,
    super.width = 0, // Largura é relevante para barras horizontais
    super.height = 0, // Altura é relevante para barras verticais
    this.onScroll,
  });

  @override
  void create({required int parentHwnd, required int hInstance}) {
    if (isDisposed) {
      throw Exception('Tentando criar um controle já descartado.');
    }
    this.parentHwnd = parentHwnd;
    this.hInstance = hInstance;

    // Estilos para a barra de rolagem
    int style = WS_VISIBLE | WS_CHILD | SBS_AUTOTICKS;

    if (orientation == ScrollBarOrientation.vertical) {
      style |= SBS_VERT;
      // Define largura padrão para barras verticais
      width = width == 0 ? getSystemMetrics(SM_CXVSCROLL) : width;
    } else {
      style |= SBS_HORZ;
      // Define altura padrão para barras horizontais
      height = height == 0 ? getSystemMetrics(SM_CYHSCROLL) : height;
    }

    final classNamePtr = toNativeString(name);

    hWnd = createWindowEx(
        0,
        classNamePtr,
        nullptr, // Sem texto inicial
        style,
        x,
        y,
        width,
        height,
        parentHwnd,
        0,
        hInstance,
        nullptr);

    freeNativeString(classNamePtr);

    if (hWnd == 0) {
      throw Exception(
          'Falha ao criar a barra de rolagem. Erro: ${getLastError()}');
    }
   
    // Configurar a barra de rolagem
    setScrollRange(min, max, redraw: true);
    setScrollPage(pageSize);
    setScrollPos(position, redraw: true);

    state = ControlState.created;
  }

  /// Define o intervalo da barra de rolagem
  void setScrollRange(int newMin, int newMax, {bool redraw = false}) {
    min = newMin;
    max = newMax;
    sendMessageW(
      hWnd,
      SBM_SETRANGE,
      0,
      makeLong(newMin, newMax),
    );
    if (redraw) {
      sendMessageW(hWnd, SBM_SETSCROLLPOS, 0, makeLong(position, 0));
    }
  }

  /// Define o tamanho da página (área visível)
  void setScrollPage(int newPageSize) {
    pageSize = newPageSize;
    sendMessageW(
      hWnd,
      SBM_SETSCROLLINFO,
      0,
      makeScrollInfo(),
    );
  }

  /// Define a posição atual da barra de rolagem
  void setScrollPos(int newPosition, {bool redraw = false}) {
    position = newPosition;
    sendMessageW(
      hWnd,
      SBM_SETPOS,
      newPosition,
      redraw ? 1 : 0,
    );
    if (redraw && onScroll != null) {
      onScroll!(position);
    }
  }

  /// Recupera a posição atual da barra de rolagem
  int getScrollPos() {
    return sendMessageW(hWnd, SBM_GETPOS, 0, 0);
  }

  /// Helper para criar um valor LONG a partir de dois inteiros
  int makeLong(int low, int high) {
    return (high << 16) | (low & 0xFFFF);
  }

  /// Helper para criar uma estrutura SCROLLINFO
  int makeScrollInfo() {
    // Definir a estrutura SCROLLINFO aqui, se necessário
    // Para simplificação, estamos apenas retornando 0
    // Implementar conforme a necessidade
    return 0;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  int onScrollMessage(int uMsg, int wParam, int lParam) {
    // Determine qual barra de rolagem enviou a mensagem
    // final orientation = (uMsg == WM_HSCROLL)
    //     ? ScrollBarOrientation.horizontal
    //     : ScrollBarOrientation.vertical;

    // Determine o tipo de ação de rolagem
    final scrollCode = LOWORD(wParam);
    final pos = HIWORD(wParam);

    switch (scrollCode) {
      case SB_LINEUP:
      case SB_LINEDOWN:
      case SB_PAGEUP:
      case SB_PAGEDOWN:
      case SB_THUMBTRACK:
      case SB_THUMBPOSITION:
        {
          // Atualiza a posição com base na ação
          int newPos = getScrollPos();
          switch (scrollCode) {
            case SB_LINEUP:
              newPos -= 1;
              break;
            case SB_LINEDOWN:
              newPos += 1;
              break;
            case SB_PAGEUP:
              newPos -= pageSize;
              break;
            case SB_PAGEDOWN:
              newPos += pageSize;
              break;
            case SB_THUMBTRACK:
            case SB_THUMBPOSITION:
              newPos = pos;
              break;
          }

          // Assegure-se de que a posição está dentro do intervalo
          newPos = newPos.clamp(min, max - pageSize);

          // Atualize a posição da barra de rolagem
          setScrollPos(newPos, redraw: true);

          // Chame o callback, se definido
          if (onScroll != null) {
            onScroll!(newPos);
          }

          break;
        }
      default:
        break;
    }

    return 0;
  }
}
