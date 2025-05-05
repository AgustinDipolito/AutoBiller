import 'dart:convert';
import 'dart:io';

import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart';

class FileApi {
  static Future<File> saveDocument({required String name, required Document pdf}) async {
    final bytes = await pdf.save();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');

    await file.writeAsBytes(bytes);

    return file;
  }

  static Future<void> openFile(File file) async {
    final url = file.path;

    await OpenFile.open(url);
  }

  static Future<File?>? createCSV<T>(List<T> items, String name,
      {bool open = true}) async {
    try {
      final csv = items.map((e) => e.toString()).join('\n');
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/$name.csv',
      );

      await file.writeAsString(csv, encoding: Encoding.getByName('l1')!);
      if (open) await openFile(file);
      return file;
    } on Exception catch (e) {
      print(e);
      return null;
    }
  }
}
