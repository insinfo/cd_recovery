import 'dart:ffi';
import 'dart:io';

import 'package:cd_recovery/cd_recovery.dart';
import 'package:win32/win32.dart';

Future<void> main() async {
  // Your custom main Window class (declared bellow):
  var mainWindow = MainWindow(
    width: 640,
    height: 480,
  );

  // Create the window:
  await mainWindow.create();

  // Exit when the Window is closed and destroyed:
  // See `MainWindow.processClose` below:
  mainWindow.onDestroyed.listen((window) {
    print('-- Window Destroyed> $window');
    exit(0);
  });

  // Show the main Window:
  mainWindow.show();

  // Run the Win32 Window message loop.
  await Window.runMessageLoopAsync();
}

// A custom main Window:
class MainWindow extends Window {
  // Declare the main window custom class:
  static final mainWindowClass = WindowClass.custom(
    className: 'mainWindow',
    windowProc: Pointer.fromFunction<WNDPROC>(mainWindowProc, 0),
    bgColor: RGB(255, 255, 255),
    useDarkMode: true,
    titleColor: RGB(32, 32, 32),
  );

  // Redirect to default implementation [WindowClass.windowProcDefault].
  static int mainWindowProc(int hwnd, int uMsg, int wParam, int lParam) =>
      WindowClass.windowProcDefault(
          hwnd, uMsg, wParam, lParam, mainWindowClass);

  MainWindow({super.width, super.height})
      : super(
          defaultRepaint: false, // Tells that `repaint()` below will be used.
          windowName: 'Win32 GUI - Example', // The Window title.
          windowClass: mainWindowClass,
          windowStyles: WS_MINIMIZEBOX | WS_SYSMENU,
        );

  late final String imageDartLogoPath;
  late final String iconDartLogoPath;

  // Load resources (called by `create()`):
  @override
  Future<void> load() async {
    // imageDartLogoPath = await Window.resolveFilePath(
    //         'package:win32_gui/resources/dart-logo.bmp');
  }

  // Called when processing a `WM_CREATE` message (generated by `create()`):
  @override
  void build(int hwnd, int hdc) {
    super.build(hwnd, hdc);

    SetTextColor(hdc, RGB(255, 255, 255));
    SetBkColor(hdc, RGB(96, 96, 96));

    // Sets the Window icon:
    setIcon(iconDartLogoPath);
  }

  // Customize close operation:
  @override
  bool? processClose() {
    // Inform default close behavior (`destroy()` Window):
    return null;
  }

  // Custom repaint. Called when processing a `WM_PAINT` message and `this.defaultRepaint = false`:
  @override
  void repaint(int hwnd, int hdc) {
    // Loads a 24-bits Bitmap:
    // var hBitmap = loadImageCached(imageDartLogoPath);
    // // Get the Bitmap dimensions:
    // var imgDimension = getBitmapDimension(hBitmap);

    // // Valid Bitmap:
    // if (imgDimension != null) {
    //   var imgW = imgDimension.width;
    //   var imgH = imgDimension.height;

    //   // Center image horizontally:
    //   final x = (dimensionWidth - imgW) ~/ 2;
    //   final y = 10;

    //   // Draws the Bitmap copying its bytes to this Window.
    //   drawImage(hdc, hBitmap, x, y, imgW, imgH);
    // }
  }
}
