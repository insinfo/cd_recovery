// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:io';
import 'package:cd_recovery/src/utils/cd_drive_controller.dart';

import 'package:cd_recovery/src/windows/gui2/win32_message_loop.dart';
import 'package:cd_recovery/src/windows/utils/utils.dart';
import 'package:cd_recovery/src/windows/gui2/window_simple.dart';
import 'package:path/path.dart' as p;

Future<bool> checkCdCopied(int cdSize, String cdName, String folderPath) async {
  final folder = Directory('$folderPath/$cdName');
  final folderSize = await getDirectorySize(folder);
  return folderSize == cdSize;
}

void main() {
  final cdDrivers = listCDDrives();

  var driverCdSelecionado = '';
  var stringMessage = '';

  final diretoriosIgnorados = ['CDs que deram problema'];
  // Caminho da pasta com os CDs copiados
  const folderPath = r'D:\Acervo_de_Processo_A';

  final logFile = File(p.join(folderPath, 'copy_log.txt'));
  final logSink = logFile.openWrite(mode: FileMode.append);
  logSink.writeln('----- Início da Sessão de Cópia em ${DateTime.now()} -----');

  // lista de CDs que foram copiados
  // final copiedCds = Directory(folderPath)
  //     .listSync(recursive: false)
  //     .where((e) => e is Directory)
  //     .map((e) => p.basenameWithoutExtension(e.path))
  //     .where((dirName) => !diretoriosIgnorados.contains(dirName))
  //     .toList();

  final copiedCds = List.generate(149, (index) => (index + 1).toString());
  final window =
      Win32Window(title: 'Verificação de CDs', width: 600, height: 450);

  final comboCdDrivers = ComboBox(
    items: cdDrivers,
    x: 10,
    y: 10,
    width: 120,
    height: 200,
    onItemSelected: (selectedItem) {
      driverCdSelecionado = selectedItem;
    },
  );

  // Mensagem de status
  final statusMessage = TextInput(
    x: 170,
    y: 10,
    width: 350,
    height: 100,
    isMultline: true,
    initialText: 'Clique em "Próximo CD" para começar.',
  );

  final progressBar =
      ProgressBar(x: 10, y: 250, width: 350, height: 30, position: 0);

  int currentIndex = 0;

  void checkNextCd() async {
    if (currentIndex >= copiedCds.length) {
      stringMessage = 'Todos os CDs foram verificados.';
      statusMessage.text = stringMessage;
      logSink.writeln(stringMessage);
      return;
    }

    final cdName = copiedCds[currentIndex];
    stringMessage = 'Insira o CD "$cdName" e feche a bandeja.';
    statusMessage.text = stringMessage;

    if (driverCdSelecionado.isEmpty) {
      stringMessage = 'Selecione a unidade de CD';
      statusMessage.text = stringMessage;
      print(stringMessage);
      return;
    }

    CDDriveController.eject(driverCdSelecionado);
    //aguarda o CD ser introduzido na bandeja
    window.onCDArrival.listen((event) async {
      await Future.delayed(Duration(seconds: 3));

      final currentVolume = getVolumeName(driverCdSelecionado);

      // if (currentVolume != cdName) {
      //   stringMessage = 'CD tem nome diferente';
      //   statusMessage.text = stringMessage;
      //   return;
      // }

      final cdSize = CDDriveController.getDiscSize(driverCdSelecionado);
      stringMessage = 'Tamanho do CD "$cdName": $cdSize bytes';
      statusMessage.text = stringMessage;
      logSink.writeln(stringMessage);
      print(stringMessage);

      final isCopied = await checkCdCopied(cdSize, cdName, folderPath);

      if (isCopied) {
        stringMessage = 'O CD "$cdName" já foi copiado completamente.';
        statusMessage.text = stringMessage;
        logSink.writeln(stringMessage);
        print(stringMessage);
      } else {
        stringMessage = '''O CD "$cdName" não foi copiado ou está incompleto. 
      Iniciando a cópia do CD "$cdName"...''';
        statusMessage.text = stringMessage;
        print(stringMessage);
        logSink.writeln(stringMessage);

        // Calcula o número total de setores
        final totalSectors = (cdSize / CDDriveController.sectorSizeRaw).ceil();

        // Reseta a ProgressBar
        progressBar.position = 0;
        progressBar.max = totalSectors;
        final pathDestino = p.join(folderPath, cdName, '$cdName.bin');
        await Future.delayed(Duration(seconds: 1));
        // Inicia a cópia de forma assíncrona
        await CDDriveController.copyCDRaw(
          driverCdSelecionado,
          pathDestino,
          onProgress: (currentSector, total) {
            // Atualiza o progresso na ProgressBar
            progressBar.position = currentSector;
            // Atualiza a mensagem de status
            statusMessage.text =
                'Copiando CD "$cdName": $currentSector de $total setores.';
            // Opcional: Atualiza a interface gráfica
            window.update();
          },
        );

        // Verifica novamente após a cópia
        final isCopiedAfter = await checkCdCopied(cdSize, cdName, folderPath);

        if (isCopiedAfter) {
          statusMessage.text = 'CD "$cdName" copiado com sucesso.';
          logSink.writeln('CD "$cdName" copiado com sucesso.');
        } else {
          statusMessage.text =
              'Erro ao copiar o CD "$cdName". Tente novamente.';
          logSink.writeln('Erro ao copiar o CD "$cdName".');
        }
      }

      currentIndex++;
    });
  }

  // Botão "Próximo CD"
  final nextCdButton = Button(
    text: 'Próximo CD',
    x: 50,
    y: 150,
    width: 120,
    height: 40,
    onPressed: () {
      checkNextCd();
    },
  );

  final closeBtn = Button(
    text: 'Encerrar',
    x: 200,
    y: 150,
    width: 120,
    height: 40,
    onPressed: () {
      logSink.writeln('Aplicação encerrada.');
      logSink.close();
      exit(0);
    },
  );

  // Adiciona os componentes à janela
  window.addChildren(
      [statusMessage, comboCdDrivers, nextCdButton, closeBtn, progressBar]);
  window.onClose.listen((e) {
    exit(0);
  });

  window.show();

  Win32MessageLoop.runLoopAsync();
}
