import 'package:cd_recovery/src/utils/cd_drive_controller.dart';
import 'package:cd_recovery/src/windows/utils/utils.dart';

void main(List<String> args) {
  final cdDrive = 'E';
  final outputFile = 'output.bin';
  CDDriveController.copyCDRaw(cdDrive, outputFile);
}

// void main() {
//   final drive = 'E';
//   final virtual = CDDriveController.isVirtualDrive(drive);
//   print('A unidade $drive é virtual? $virtual');
// }

// void main() {
//   try {
//     final volumeName = getVolumeName('E');
//     print('Nome do volume da unidade D: $volumeName');
//   } catch (e) {
//     print('Erro: $e');
//   }
// }
