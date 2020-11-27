import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_automation_tools/all.dart';

export 'package:home_automation_tools/all.dart'
    show
        BitDemultiplexer,
        CloudBit,
        debouncer,
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

///Credentials go in this order:
///Line 1: authToken littlebits
///Lines 2 & 3: Sunpower username and password
///Line 4: Remy password
///Lines 5 and 6: Television username and password
List<String> _credentials;

Future<Null> init() async {
  _credentials = await rootBundle.loadStructuredData('credentials.cfg',
      (String value) async {
    return value.split('\n');
  });
  if (_credentials.length < 5)
    throw new Exception('credentials file incomplete or otherwise corrupted');
  _solar = new SunPowerMonitor(
    customerUsername: _credentials[1],
    customerPassword: _credentials[2],
    onLog: (dynamic error) {
      if (onError != null) onError('SunPower: $error');
    },
  );
  _cloud = new LittleBitsCloud(
    authToken: _credentials[0],
    onError: (dynamic error) async {
      if (onError != null) onError('CloudBits: $error');
    },
  );
  _television = new Television(
    username: _credentials[4],
    password: _credentials[5],
  );
}

Remy openRemy(NotificationHandler onNotification, UiUpdateHandler onUiUpdate) {
  assert(_credentials != null);
  return new Remy(
    username:
        'house-of-rooves app on ${Platform.localHostname} (${Platform.operatingSystem})',
    password: _credentials[3],
    onNotification: onNotification,
    onUiUpdate: onUiUpdate,
    onLog: (dynamic error) {
      if (onError != null) onError('Remy: $error');
    },
  );
}

void dispose() {
  _solar.dispose();
  _cloud.dispose();
}
