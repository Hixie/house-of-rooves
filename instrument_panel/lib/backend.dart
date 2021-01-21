import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_automation_tools/all.dart';

export 'package:home_automation_tools/all.dart'
    show
        BitDemultiplexer,
        Localbit,
        LedColor,
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

LittleBitsLocalServer get cloud => _cloud;
LittleBitsLocalServer _cloud;

final List<Localbit> cloudBits = <Localbit>[];

Television get television => _television;
Television _television;

const String cloudBitTestId = '00e04c02bd93';
const String houseSensorsId = '243c201de435';
const String solarDisplayId = '243c201ddaf1';
const String showerDayId = '00e04c0355d0';

typedef ErrorReporter = void Function(String message);

ErrorReporter onError;

/// Credentials go in this order:
///   0. Littlebits authToken
///   1. Sunpower username
///   2. Sunpower password
///   3. Remy password
///   4. Television username
///   5. Television password
List<String> _credentials;
SecurityContext _securityContext;

Future<void> init() async {
  _credentials = await rootBundle.loadStructuredData('credentials.cfg', (String value) async {
    return value.split('\n');
  });
  if (_credentials.length < 5)
    throw Exception('credentials file incomplete or otherwise corrupted');
  _solar = SunPowerMonitor(
    customerUsername: _credentials[1],
    customerPassword: _credentials[2],
    onLog: (Object error) {
      if (onError != null)
        onError('SunPower: $error');
    },
  );
  _cloud = LittleBitsLocalServer(
    onIdentify: (String deviceId) {
      if (deviceId == cloudBitTestId)
        return const LocalCloudBitDeviceDescription('cloudbit test device', 'cloudbit-test.rooves.house');
      if (deviceId == houseSensorsId)
        return const LocalCloudBitDeviceDescription('house sensors', 'cloudbit-housesensors.rooves.house');
      if (deviceId == solarDisplayId)
        return const LocalCloudBitDeviceDescription('solar display', 'cloudbit-solar.rooves.house');
      if (deviceId == showerDayId)
        return const LocalCloudBitDeviceDescription('shower day display', 'cloudbit-shower.rooves.house');
      throw Exception('Unknown cloudbit device ID: $deviceId');
    },
    onError: (Object error) async {
      if (onError != null)
        onError('CloudBits: $error');
    },
  );
  cloudBits
    ..add(_cloud.getDeviceSync(cloudBitTestId))
    ..add(_cloud.getDeviceSync(houseSensorsId))
    ..add(_cloud.getDeviceSync(solarDisplayId))
    ..add(_cloud.getDeviceSync(showerDayId));
  _television = Television(
    username: _credentials[4],
    password: _credentials[5],
  );
  _securityContext = SecurityContext()
    ..setTrustedCertificatesBytes((await rootBundle.load('ca.cert.pem')).buffer.asUint8List());
}

Remy openRemy(NotificationHandler onNotification, UiUpdateHandler onUiUpdate) {
  assert(_credentials != null);
  return Remy(
    username: 'house-of-rooves app on ${Platform.localHostname} (${Platform.operatingSystem})',
    password: _credentials[3],
    securityContext: _securityContext,
    onNotification: onNotification,
    onUiUpdate: onUiUpdate,
    onLog: (Object error) {
      if (onError != null)
        onError('Remy: $error');
    },
  );
}

void dispose() {
  _solar.dispose();
  _cloud.dispose();
}
