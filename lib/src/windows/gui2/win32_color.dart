import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'win32_api.dart';

class Win32Color {
  final int color;
  final isTransparent;

  const Win32Color([this.color = 0x00FF0000, this.isTransparent = false]);

  static const white = Win32Color(0x00FFFFFF);
  static const red = Win32Color(0x000000FF);
  static const blue = Win32Color(0x00FF0000);
  static const green = Win32Color(0x0000FF00);
  static const lightgray = Win32Color(0x00EAEAEA);

  /// Cor RGB(0, 70, 140)
  static const bgColor = Win32Color(0x008C4600);

  /// Cor RGB(255, 100, 100)
  static const bgColorSelected = Win32Color(0x006464FF);

  /// Cor RGB(255, 200, 0)
  static const bgColorHotlight = Win32Color(0x0000C8FF);

  /// Cor RGB(255, 255, 255)
  static const textColorLight = Win32Color(0x00FFFFFF);

  static const transparent = Win32Color(0, true);

  static Win32Color fromRgb(int red, int green, int blue) {
    return Win32Color(rgb(red, green, blue));
  }

  // Função para converter valores RGB para um inteiro de cor Windows
  /// Converte cores RGB para COLORREF
  static int rgb(int red, int green, int blue) {
    // Garante que os valores estão no intervalo 0-255
    red = red.clamp(0, 255);
    green = green.clamp(0, 255);
    blue = blue.clamp(0, 255);
    // Converte para o formato de cor Windows (BGR)
    return (blue << 16) | (green << 8) | red;
  }

  // Método para alterar cor de fundo de um controle
  static int setControlBackgroundColor(int hWnd, int color) {
    // Obtém o contexto de dispositivo do controle
    final hdc = getDC(hWnd);
    // Cria um pincel com a cor especificada
    final hBrush = createSolidBrush(color);
    // Associa o pincel ao contexto de dispositivo
    selectObject(hdc, hBrush);
    // Define a cor de fundo
    setBkColor(hdc, color);
    return hdc;
  }

  // Método para alterar cor do texto de um controle
  static void setControlTextColor(int hWnd, int color) {
    final hdc = getDC(hWnd);
    setTextColor(hdc, color);
  }

  /// Criação de gradiente
  static int createGradientBrush(
      int topColor, int bottomColor, Pointer<NMCUSTOMDRAW> item) {
    final hdcMem = createCompatibleDC(item.ref.hdc);
    final hBitmap = createCompatibleBitmap(
        item.ref.hdc,
        item.ref.rc.right - item.ref.rc.left,
        item.ref.rc.bottom - item.ref.rc.top);

    selectObject(hdcMem, hBitmap);

    final r1 = (topColor & 0xFF0000) >> 16;
    final g1 = (topColor & 0x00FF00) >> 8;
    final b1 = (topColor & 0x0000FF);

    final r2 = (bottomColor & 0xFF0000) >> 16;
    final g2 = (bottomColor & 0x00FF00) >> 8;
    final b2 = (bottomColor & 0x0000FF);

    for (int i = 0; i < (item.ref.rc.bottom - item.ref.rc.top); i++) {
      final r = r1 + ((r2 - r1) * i) ~/ (item.ref.rc.bottom - item.ref.rc.top);
      final g = g1 + ((g2 - g1) * i) ~/ (item.ref.rc.bottom - item.ref.rc.top);
      final b = b1 + ((b2 - b1) * i) ~/ (item.ref.rc.bottom - item.ref.rc.top);

      final tempRect = calloc<RECT>();
      tempRect.ref
        ..left = 0
        ..top = i
        ..right = item.ref.rc.right - item.ref.rc.left
        ..bottom = i + 1;

      final brush = createSolidBrush(rgb(r, g, b));
      fillRect(hdcMem, tempRect, brush);
      deleteObject(brush);
      calloc.free(tempRect);
    }

    final patternBrush = createPatternBrush(hBitmap);

    deleteDC(hdcMem);
    deleteObject(hBitmap);

    return patternBrush;
  }
}
