import 'dart:async';

import 'package:flutter/material.dart';

import 'backend.dart' as backend;
import 'cloudbits.dart';
import 'components/auto_fade.dart';
import 'doors.dart';
import 'remy.dart';
import 'solar.dart';
import 'television.dart';

// TODO(ianh): add dishwasher console
// TODO(ianh): add database console
// TODO(ianh): add uradmonitor console
// TODO(ianh): add tts console
// TODO(ianh): add thermostat console

enum HouseOfRoovesPage {
  cloudbits,
  doors,
  remy,
  solar,
  television,
}

class MainDrawer extends StatelessWidget {
  const MainDrawer({Key key, this.page, this.onPageChanged}) : super(key: key);

  final HouseOfRoovesPage page;
  final ValueChanged<HouseOfRoovesPage> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Theme(
            data: ThemeData.dark(),
            child: const DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: ExactAssetImage('images/drawer_header.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Text('House of Rooves'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Remy'),
            selected: page == HouseOfRoovesPage.remy,
            onTap: onPageChanged != null
                ? () {
                    onPageChanged(HouseOfRoovesPage.remy);
                    Navigator.pop(context);
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny),
            title: const Text('Solar'),
            selected: page == HouseOfRoovesPage.solar,
            onTap: onPageChanged != null
                ? () {
                    onPageChanged(HouseOfRoovesPage.solar);
                    Navigator.pop(context);
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Doors'),
            selected: page == HouseOfRoovesPage.doors,
            onTap: onPageChanged != null
                ? () {
                    onPageChanged(HouseOfRoovesPage.doors);
                    Navigator.pop(context);
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.tv),
            title: const Text('Television'),
            selected: page == HouseOfRoovesPage.television,
            onTap: onPageChanged != null
                ? () {
                    onPageChanged(HouseOfRoovesPage.television);
                    Navigator.pop(context);
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('CloudBits'),
            selected: page == HouseOfRoovesPage.cloudbits,
            onTap: onPageChanged != null
                ? () {
                    onPageChanged(HouseOfRoovesPage.cloudbits);
                    Navigator.pop(context);
                  }
                : null,
          ),

          // icons for future pages:
          // hot_tub
          // hotel (bed)
        ],
      ),
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading'),
      ),
      body: const Center(
        child: Text('Please Stand By...'),
      ),
    );
  }
}

class HouseOfRooves extends StatefulWidget {
  const HouseOfRooves({ Key key }) : super(key: key);
  @override
  _HouseOfRoovesState createState() => _HouseOfRoovesState();
}

class _HouseOfRoovesState extends State<HouseOfRooves> {
  @override
  void initState() {
    super.initState();
    backend.onError = (String message) {
      // add to an in-memory log that can be shown somewhere
      //assert(() { print(message); return true; });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    };
    backend.init().whenComplete(() {
      _handlePageChanged(HouseOfRoovesPage.remy);
    });
  }

  HouseOfRoovesPage _page;

  void _handlePageChanged(HouseOfRoovesPage page) {
    setState(() {
      _page = page;
    });
  }

  Widget _buildBody() {
    if (_page == null)
      return const LoadingPage();
    switch (_page) {
      case HouseOfRoovesPage.remy:
        return const RemyPage();
      case HouseOfRoovesPage.cloudbits:
        return const CloudBitsPage();
      case HouseOfRoovesPage.doors:
        return const DoorsPage();
      case HouseOfRoovesPage.solar:
        return const SolarPage();
      case HouseOfRoovesPage.television:
        return const TelevisionPage();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _page != null
          ? MainDrawer(page: _page, onPageChanged: _handlePageChanged)
          : null,
      body: AutoFade(
        duration: const Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
        token: _page,
        child: _buildBody(),
      ),
    );
  }
}

Future<void> main() async {
  runApp(
    MaterialApp(
      title: 'House of Rooves',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        accentColor: Colors.greenAccent[700],
        accentColorBrightness: Brightness.dark,
      ),
      home: const HouseOfRooves(),
    ),
  );
}
