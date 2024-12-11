import 'dart:io';
import 'package:cd_recovery/src/windows/gui2/window_simple.dart';

void main() {
  final window = Win32Window();
  window.onClose.listen((e) {
    exit(0);
  });
  window.addChildren([
    Button(
        text: 'botão 10',
        x: 50,
        y: 50,
        onPressed: () {
          print('clicou janela pai');
          final childWin = Win32ChildWindow();
          childWin.addChild(
            TextInput(
              x: 10,
              y: 10,
              width: 300,
              height: 200,
              isMultline: true,
              onTextChanged: (text) {
                print('Texto janela filha: $text');
              },
            ),
          );
          childWin.show();
        }),
    TextInput(
      x: 50,
      y: 100,
      width: 200,
      height: 30,
      onTextChanged: (text) {
        print('Texto janela pai: $text');
      },
    ),
    ComboBox(
      items: ['Opção 1', 'Opção 2', 'Opção 3'],
      x: 50,
      y: 140,
      width: 150,
      height: 200,
      onItemSelected: (selectedItem) {
        print('Item selecionado: $selectedItem');
      },
    ),
    ProgressBar(x: 50, y: 180, width: 300, height: 30, position: 20),
    Label('teste Label', x: 50, y: 250)
  ]);
  window.show();
  runApp();
}
