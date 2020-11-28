import 'dart:io';

import 'package:flutter/services.dart';

class Credentials {
  static Future<Credentials> load() async {
    return Credentials._(
      await rootBundle.loadStructuredData('credentials.cfg', (String value) async {
        return value.split('\n');
      }),
      SecurityContext()
        ..setTrustedCertificatesBytes((await rootBundle.load('ca.cert.pem')).buffer.asUint8List()),
    );
  }

  Credentials._(this._lines, this._securityContext) {
    if (_lines.length < _requiredCount)
      throw new Exception('credentials file incomplete or otherwise corrupted');
  }
  final List<String> _lines;

  String get remyPassword => _lines[0];

  SecurityContext get securityContext => _securityContext;
  SecurityContext _securityContext;

  int get _requiredCount => 2;
}
