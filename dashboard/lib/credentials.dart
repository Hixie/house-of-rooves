import 'dart:io';

class Credentials {
  Credentials(String filename) : this._lines = new File(filename).readAsLinesSync() {
    if (_lines.length < _requiredCount)
      throw new Exception('credentials file incomplete or otherwise corrupted');
  }
  final List<String> _lines;

  String get databaseHost => _lines[0];
  int get databasePort => int.parse(_lines[1], radix: 10);
  String get certificatePath => _lines[2];

  int get _requiredCount => 3;
}
