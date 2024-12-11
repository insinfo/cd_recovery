import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const IDC_MYBUTTON = 1001;

// Definição manual das constantes ausentes:
const ODS_SELECTED = 0x0001;
const ODS_HOTLIGHT = 0x0040;
const BN_CLICKED = 0;

base class DRAWITEMSTRUCT extends Struct {
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

  @IntPtr() // HWND é um handle (ponteiro)
  external int hwndItem;

  @IntPtr() // HDC também é um handle (ponteiro)
  external int hDC;

  external RECT rcItem;

  @IntPtr() // ULONG_PTR depende da arquitetura; usar IntPtr garante tamanho correto.
  external int itemData;
}

int WndProc(int hwnd, int uMsg, int wParam, int lParam) {
  switch (uMsg) {
    case WM_CREATE:
      {
        // Cria o botão com estilo BS_OWNERDRAW
        CreateWindowEx(
            0,
            TEXT("BUTTON"),
            TEXT("Botão Custom"),
            WS_VISIBLE | WS_CHILD | BS_OWNERDRAW,
            50,
            50,
            100,
            40,
            hwnd,
            IDC_MYBUTTON,
            GetWindowLongPtr(hwnd, GWLP_HINSTANCE),
            nullptr);
      }
    case WM_DRAWITEM:
      print('WM_DRAWITEM');
      final pdis = Pointer<DRAWITEMSTRUCT>.fromAddress(lParam);
      final dis = pdis.ref;
      if (dis.CtlID == IDC_MYBUTTON) {
        final itemState = dis.itemState;

        late int corFundo;

        if ((itemState & ODS_SELECTED) != 0) {
          corFundo = RGB(255, 100, 100);
        } else if ((itemState & ODS_HOTLIGHT) != 0) {
          corFundo = RGB(255, 200, 0);
        } else {
          corFundo = RGB(0, 70, 140);
        }

        final hdc = dis.hDC;
        final rc = dis.rcItem;
        final rcPtr = calloc<RECT>();
        // Copia os valores de dis.rcItem para a memória recém-alocada
        rcPtr.ref.left = dis.rcItem.left;
        rcPtr.ref.top = dis.rcItem.top;
        rcPtr.ref.right = dis.rcItem.right;
        rcPtr.ref.bottom = dis.rcItem.bottom;

        final hbr = CreateSolidBrush(corFundo);
        FillRect(hdc, rcPtr, hbr);
        DeleteObject(hbr);

        final hPen = CreatePen(PS_SOLID, 1, RGB(0, 0, 0));
        final oldPen = SelectObject(hdc, hPen);
        final oldBrush = SelectObject(hdc, GetStockObject(NULL_BRUSH));
        Rectangle(hdc, rc.left, rc.top, rc.right, rc.bottom);
        SelectObject(hdc, oldBrush);
        SelectObject(hdc, oldPen);
        DeleteObject(hPen);

        SetBkMode(hdc, TRANSPARENT);
        SetTextColor(hdc, RGB(255, 255, 255));
        final text = "Botão Custom".toNativeUtf16();
        DrawText(hdc, text, -1, rcPtr, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        free(text);

        return TRUE;
      }
      break;

    case WM_COMMAND:
      final id = LOWORD(wParam);
      final code = HIWORD(wParam);
      if (id == IDC_MYBUTTON && code == BN_CLICKED) {
        MessageBox(hwnd, TEXT("Botão pressionado!"), TEXT("Info"), MB_OK);
      }
      break;
  }

  return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

void main() {
  // Inicializa a COM (opcional, caso precise)
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  final className = TEXT("JanelaPrincipal");
  final hInstance = GetModuleHandle(nullptr);

  final wc = calloc<WNDCLASSEX>();
  wc.ref.cbSize = sizeOf<WNDCLASSEX>();
  wc.ref.style = CS_HREDRAW | CS_VREDRAW;
  wc.ref.lpfnWndProc = Pointer.fromFunction<WindowProc>(WndProc, 0);
  wc.ref.cbClsExtra = 0;
  wc.ref.cbWndExtra = 0;
  wc.ref.hInstance = hInstance;
  wc.ref.hbrBackground = GetSysColorBrush(COLOR_WINDOW + 1);
  wc.ref.lpszClassName = className;

  RegisterClassEx(wc);

  final hwnd = CreateWindowEx(
    0,
    className,
    TEXT("Exemplo Owner-Draw Button"),
    WS_OVERLAPPEDWINDOW,
    CW_USEDEFAULT,
    CW_USEDEFAULT,
    300,
    200,
    0,
    0,
    hInstance,
    nullptr,
  );

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
  CoUninitialize();
}
