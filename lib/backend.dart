import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_automation_tools/all.dart';

export 'package:home_automation_tools/all.dart' show
  BitDemultiplexer,
  CloudBit,
  Remy,
  RemyNotification,
  RemyUi,
  RemyMessage,
  RemyButton,
  RemyToDo,
  TelevisionRemote,
  TelevisionChannel,
  TelevisionSource,
  TelevisionOffTimer;

SunPowerMonitor get solar => _solar;
SunPowerMonitor _solar;

LittleBitsCloud get cloud => _cloud;
LittleBitsCloud _cloud;

Television get television => _television;
Television _television;

const String houseSensorsId = '243c201de435';
const String laundryId = '00e04c02bd93';
const String solarDisplayId = '243c201ddaf1';
const String cloudBitTest1Id = '243c201dc805';
const String cloudBitTest2Id = '243c201dcdfd';
const String thermostatId = '00e04c0355d0';

typedef void ErrorReporter(String message);

ErrorReporter onError;

List<String> _credentials;

Future<Null> init() async {
  _credentials = await rootBundle.loadStructuredData('credentials.cfg', (String value) {
    return value.split('\n');
  });
  if (_credentials.length < 5)
    throw new Exception('credentials file incomplete or otherwise corrupted');
  _solar = new SunPowerMonitor(
    customerId: _credentials[1],
    onError: (dynamic error) {
      if (onError != null)
        onError('SunPower: $error');
    },
  );
  _cloud = new LittleBitsCloud(
    authToken: _credentials[0],
    onError: (dynamic error) {
      if (onError != null)
        onError('CloudBits: $error');
    },
  );
  _television = new Television(
    username: _credentials[3],
    password: _credentials[4],
  );
}

Remy openRemy(NotificationHandler onNotification, UiUpdateHandler onUiUpdate) {
  assert(_credentials != null);
  return new Remy(
    username: 'house-of-rooves app on ${Platform.localHostname} (${Platform.operatingSystem})',
    password: _credentials[2],
    onNotification: onNotification,
    onUiUpdate: onUiUpdate,
    onError: (dynamic error) {
      if (onError != null)
        onError('Remy: $error');
    },
  );
}

void dispose() {
  _solar.dispose();
  _cloud.dispose();
}
