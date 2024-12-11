import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

//usando custom draw para botoes so funciona no c++ o gradiente

const int EXIT_FAILURE = 1;
const int EXIT_SUCCESS = 0;
const IDC_EXIT_BUTTON = 101;
const IDC_PUSHLIKE_BUTTON = 102;
const int NM_CUSTOMDRAW = -12;
const int CDRF_DODEFAULT = 0x00000000;
const int CDIS_SELECTED = 0x0001;
const int CDIS_HOT = 0x0002;
const BST_CHECKED = 1;

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

// Armazenaremos brushes criados globalmente (como no código C)
int? defaultbrush;
int? hotbrush;
int? selectbrush;
int? push_uncheckedbrush;
int? push_checkedbrush;
int? push_hotbrush1;
int? push_hotbrush2;

final gdi32 = DynamicLibrary.open('gdi32.dll');
final CreatePatternBrush =
    gdi32.lookupFunction<IntPtr Function(IntPtr hbmp), int Function(int hbmp)>(
        'CreatePatternBrush');

// Função para criar o gradient brush
int CreateGradientBrush(
    int topColor, int bottomColor, Pointer<NMCUSTOMDRAW> item) {
  final hdc = item.ref.hdc;
  final rect = item.ref.rc;
  final width = rect.right - rect.left;
  final height = rect.bottom - rect.top;

  final hdcmem = CreateCompatibleDC(hdc);
  final hbitmap = CreateCompatibleBitmap(hdc, width, height);
  SelectObject(hdcmem, hbitmap);

  final topR = GetRValue(topColor);
  final topG = GetGValue(topColor);
  final topB = GetBValue(topColor);

  final bottomR = GetRValue(bottomColor);
  final bottomG = GetGValue(bottomColor);
  final bottomB = GetBValue(bottomColor);

  for (var i = 0; i < height; i++) {
    final r = topR + ((bottomR - topR) * i ~/ height);
    final g = topG + ((bottomG - topG) * i ~/ height);
    final b = topB + ((bottomB - topB) * i ~/ height);

    final lineBrush = CreateSolidBrush(RGB(r, g, b));
    final pTempRect = calloc<RECT>();
    pTempRect.ref.left = 0;
    pTempRect.ref.top = i;
    pTempRect.ref.right = width;
    pTempRect.ref.bottom = i + 1;
    FillRect(hdcmem, pTempRect, lineBrush);
    DeleteObject(lineBrush);
  }

  final pattern = CreatePatternBrush(hbitmap);

  DeleteDC(hdcmem);
  DeleteObject(hbitmap);

  return pattern;
}

// Função window procedure (callback)
int mainWindowProc(int hwnd, int uMsg, int wParam, int lParam) {
  switch (uMsg) {
    case WM_CREATE:
      {
        final exitButtonHwnd = CreateWindowEx(
            0,
            TEXT("BUTTON"),
            TEXT("EXIT"),
            WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON,
            50,
            50,
            100,
            100,
            hwnd,
            IDC_EXIT_BUTTON,
            GetModuleHandle(nullptr),
            nullptr);
        if (exitButtonHwnd == 0) {
          MessageBox(0, TEXT("Button Creation Failed!"), TEXT("Error!"),
              MB_ICONEXCLAMATION);
          exit(-1);
        }

        final pushlikeButtonHwnd = CreateWindowEx(
            0,
            TEXT("BUTTON"),
            TEXT("PUSH ME!"),
            WS_VISIBLE | WS_CHILD | BS_AUTOCHECKBOX | BS_PUSHLIKE,
            200,
            50,
            100,
            100,
            hwnd,
            IDC_PUSHLIKE_BUTTON,
            GetModuleHandle(nullptr),
            nullptr);
        if (pushlikeButtonHwnd == 0) {
          MessageBox(0, TEXT("Button Creation Failed!"), TEXT("Error!"),
              MB_ICONEXCLAMATION);
          exit(-1);
        }
      }
      break;

    case WM_COMMAND:
      {
        final id = LOWORD(wParam);
        if (id == IDC_EXIT_BUTTON) {
          SendMessage(hwnd, WM_CLOSE, 0, 0);
        }
      }
      break;

    case WM_NOTIFY:
      {
        print('WM_NOTIFY');
        final some_item = Pointer<NMHDR>.fromAddress(lParam);
        if (some_item.ref.idFrom == IDC_EXIT_BUTTON &&
            some_item.ref.code == NM_CUSTOMDRAW) {
          final item = Pointer<NMCUSTOMDRAW>.fromAddress(lParam);
          final state = item.ref.uItemState;

          if ((state & CDIS_SELECTED) != 0) {
            selectbrush ??=
                CreateGradientBrush(RGB(180, 0, 0), RGB(255, 180, 0), item);
            final pen = CreatePen(PS_INSIDEFRAME, 0, RGB(0, 0, 0));

            final oldPen = SelectObject(item.ref.hdc, pen);
            final oldBrush = SelectObject(item.ref.hdc, selectbrush!);
            RoundRect(item.ref.hdc, item.ref.rc.left, item.ref.rc.top,
                item.ref.rc.right, item.ref.rc.bottom, 5, 5);

            SelectObject(item.ref.hdc, oldPen);
            SelectObject(item.ref.hdc, oldBrush);
            DeleteObject(pen);

            return CDRF_DODEFAULT;
          } else {
            if ((state & CDIS_HOT) != 0) {
              hotbrush ??=
                  CreateGradientBrush(RGB(255, 230, 0), RGB(245, 0, 0), item);
              final pen = CreatePen(PS_INSIDEFRAME, 0, RGB(0, 0, 0));

              final oldPen = SelectObject(item.ref.hdc, pen);
              final oldBrush = SelectObject(item.ref.hdc, hotbrush!);
              RoundRect(item.ref.hdc, item.ref.rc.left, item.ref.rc.top,
                  item.ref.rc.right, item.ref.rc.bottom, 5, 5);

              SelectObject(item.ref.hdc, oldPen);
              SelectObject(item.ref.hdc, oldBrush);
              DeleteObject(pen);

              return CDRF_DODEFAULT;
            }

            defaultbrush ??=
                CreateGradientBrush(RGB(255, 180, 0), RGB(180, 0, 0), item);
            final pen = CreatePen(PS_INSIDEFRAME, 0, RGB(0, 0, 0));
            final oldPen = SelectObject(item.ref.hdc, pen);
            final oldBrush = SelectObject(item.ref.hdc, defaultbrush!);
            RoundRect(item.ref.hdc, item.ref.rc.left, item.ref.rc.top,
                item.ref.rc.right, item.ref.rc.bottom, 5, 5);

            SelectObject(item.ref.hdc, oldPen);
            SelectObject(item.ref.hdc, oldBrush);
            DeleteObject(pen);
            return CDRF_DODEFAULT;
          }
        } else if (some_item.ref.idFrom == IDC_PUSHLIKE_BUTTON &&
            some_item.ref.code == NM_CUSTOMDRAW) {
          final item = Pointer<NMCUSTOMDRAW>.fromAddress(lParam);
          final state = item.ref.uItemState;
          final checked =
              IsDlgButtonChecked(hwnd, some_item.ref.idFrom) == BST_CHECKED;

          if (checked) {
            if ((state & CDIS_HOT) != 0) {
              push_hotbrush1 ??=
                  CreateGradientBrush(RGB(0, 0, 245), RGB(0, 230, 255), item);
              final pen = CreatePen(PS_INSIDEFRAME, 0, RGB(0, 0, 0));
              final oldPen = SelectObject(item.ref.hdc, pen);
              final oldBrush = SelectObject(item.ref.hdc, push_hotbrush1!);
              RoundRect(item.ref.hdc, item.ref.rc.left, item.ref.rc.top,
                  item.ref.rc.right, item.ref.rc.bottom, 10, 10);

              SelectObject(item.ref.hdc, oldPen);
              SelectObject(item.ref.hdc, oldBrush);
              DeleteObject(pen);
              return CDRF_DODEFAULT;
            }

            push_checkedbrush ??=
                CreateGradientBrush(RGB(0, 0, 180), RGB(0, 222, 200), item);
            final pen = CreatePen(PS_INSIDEFRAME, 0, RGB(0, 0, 0));
            final oldPen = SelectObject(item.ref.hdc, pen);
            final oldBrush = SelectObject(item.ref.hdc, push_checkedbrush!);
            RoundRect(item.ref.hdc, item.ref.rc.left, item.ref.rc.top,
                item.ref.rc.right, item.ref.rc.bottom, 10, 10);
            SelectObject(item.ref.hdc, oldPen);
            SelectObject(item.ref.hdc, oldBrush);
            DeleteObject(pen);
            return CDRF_DODEFAULT;
          } else {
            if ((state & CDIS_HOT) != 0) {
              push_hotbrush2 ??=
                  CreateGradientBrush(RGB(255, 230, 0), RGB(245, 0, 0), item);
              final pen = CreatePen(PS_INSIDEFRAME, 0, RGB(0, 0, 0));
              final oldPen = SelectObject(item.ref.hdc, pen);
              final oldBrush = SelectObject(item.ref.hdc, push_hotbrush2!);
              RoundRect(item.ref.hdc, item.ref.rc.left, item.ref.rc.top,
                  item.ref.rc.right, item.ref.rc.bottom, 10, 10);
              SelectObject(item.ref.hdc, oldPen);
              SelectObject(item.ref.hdc, oldBrush);
              DeleteObject(pen);
              return CDRF_DODEFAULT;
            }

            push_uncheckedbrush ??=
                CreateGradientBrush(RGB(255, 180, 0), RGB(180, 0, 0), item);
            final pen = CreatePen(PS_INSIDEFRAME, 0, RGB(0, 0, 0));
            final oldPen = SelectObject(item.ref.hdc, pen);
            final oldBrush = SelectObject(item.ref.hdc, defaultbrush!);
            RoundRect(item.ref.hdc, item.ref.rc.left, item.ref.rc.top,
                item.ref.rc.right, item.ref.rc.bottom, 10, 10);
            SelectObject(item.ref.hdc, oldPen);
            SelectObject(item.ref.hdc, oldBrush);
            DeleteObject(pen);
            return CDRF_DODEFAULT;
          }
        }

        return CDRF_DODEFAULT;
      }

    case WM_CTLCOLORBTN:
      {
        // Retorna um brush da cor de fundo da janela (fundo invisível)
        return GetSysColorBrush(COLOR_WINDOW + 1);
      }

    case WM_CLOSE:
      {
        DestroyWindow(hwnd);
        return 0;
      }

    case WM_DESTROY:
      {
        if (defaultbrush != null) DeleteObject(defaultbrush!);
        if (selectbrush != null) DeleteObject(selectbrush!);
        if (hotbrush != null) DeleteObject(hotbrush!);
        if (push_checkedbrush != null) DeleteObject(push_checkedbrush!);
        if (push_hotbrush1 != null) DeleteObject(push_hotbrush1!);
        if (push_hotbrush2 != null) DeleteObject(push_hotbrush2!);
        if (push_uncheckedbrush != null) DeleteObject(push_uncheckedbrush!);

        PostQuitMessage(0);
        return 0;
      }

    default:
      return DefWindowProc(hwnd, uMsg, wParam, lParam);
  }
  return 0;
}

void main() {
  // Initialize COM libraries
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  final icc = calloc<INITCOMMONCONTROLSEX>();
  icc.ref.dwSize = sizeOf<INITCOMMONCONTROLSEX>();
  icc.ref.dwICC = ICC_STANDARD_CLASSES;
  InitCommonControlsEx(icc);
  free(icc);

  final className = TEXT("Main_Window");
  final hInstance = GetModuleHandle(nullptr);

  final wc = calloc<WNDCLASSEX>()
    ..ref.cbSize = sizeOf<WNDCLASSEX>()
    ..ref.style = 0
    ..ref.lpfnWndProc = Pointer.fromFunction<WindowProc>(mainWindowProc, 0)
    ..ref.cbClsExtra = 0
    ..ref.cbWndExtra = 0
    ..ref.hInstance = hInstance
    ..ref.hIcon = LoadIcon(0, IDI_APPLICATION)
    ..ref.hCursor = LoadCursor(0, IDC_ARROW)
    ..ref.hbrBackground = GetSysColorBrush(COLOR_WINDOW + 1)
    ..ref.lpszMenuName = nullptr
    ..ref.lpszClassName = className
    ..ref.hIconSm = LoadIcon(0, IDI_APPLICATION);

  if (RegisterClassEx(wc) == 0) {
    MessageBox(0, TEXT("Window Registration Failed!"), TEXT("Error"),
        MB_ICONEXCLAMATION | MB_OK);
    exit(-1);
  }

  final hwnd = CreateWindowEx(
      WS_EX_CLIENTEDGE,
      className,
      TEXT("Window"),
      WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      368,
      248,
      0,
      0,
      hInstance,
      nullptr);

  if (hwnd == 0) {
    MessageBox(0, TEXT("Window Creation Failed!"), TEXT("Error!"),
        MB_ICONEXCLAMATION | MB_OK);
    exit(-1);
  }

  ShowWindow(hwnd, SW_SHOW);
  UpdateWindow(hwnd);

  final msg = calloc<MSG>();
  while (GetMessage(msg, 0, 0, 0) > 0) {
    TranslateMessage(msg);
    DispatchMessage(msg);
  }

  free(msg);
  free(className);
  free(wc);
}
