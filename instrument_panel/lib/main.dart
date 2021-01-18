import 'dart:async';

import 'package:flutter/material.dart';

import 'backend.dart' as backend;
import 'cloudbits.dart';
import 'doors.dart';
import 'laundry.dart';
import 'remy.dart';
import 'solar.dart';
import 'television.dart';
import 'components/auto_fade.dart';

enum HouseOfRoovesPage {
  cloudbits,
  doors,
  laundry,
  remy,
  solar,
  television,
}

class MainDrawer extends StatelessWidget {
  MainDrawer({Key key, this.page, this.onPageChanged}) : super(key: key);

  final HouseOfRoovesPage page;
  final ValueChanged<HouseOfRoovesPage> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: new ListView(
        children: <Widget>[
          new Theme(
            data: new ThemeData.dark(),
            child: new DrawerHeader(
              decoration: new BoxDecoration(
                image: new DecorationImage(
                  image: new ExactAssetImage('images/drawer_header.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: new Text('House of Rooves'),
            ),
          ),
          new ListTile(
            leading: new Icon(Icons.assignment),
            title: new Text('Remy'),
            selected: page == HouseOfRoovesPage.remy,
            onTap: onPageChanged != null
                ? () {
                    onPageChanged(HouseOfRoovesPage.remy);
                    Navigator.pop(context);
                  }
                : null,
          ),
          new ListTile(
            leading: new Icon(Icons.wb_sunny),
            title: new Text('Solar'),
            selected: page == HouseOfRoovesPage.solar,
            onTap: onPageChanged != null
                ? () {
                    onPageChanged(HouseOfRoovesPage.solar);
                    Navigator.pop(context);
                  }
                : null,
          ),
          new ListTile(
            leading: new Icon(Icons.store),
            title: new Text('Doors'),
            selected: page == HouseOfRoovesPage.doors,
            onTap: onPageChanged != null
                ? () {
                    onPageChanged(HouseOfRoovesPage.doors);
                    Navigator.pop(context);
                  }
                : null,
          ),
          new ListTile(
            leading: new Icon(Icons.tv),
            title: new Text('Television'),
            selected: page == HouseOfRoovesPage.television,
            onTap: onPageChanged != null
                ? () {
                    onPageChanged(HouseOfRoovesPage.television);
                    Navigator.pop(context);
                  }
                : null,
          ),
          new ListTile(
            leading: new Icon(Icons.local_laundry_service),
            title: new Text('Laundry'),
            selected: page == HouseOfRoovesPage.laundry,
            onTap: onPageChanged != null
                ? () {
                    onPageChanged(HouseOfRoovesPage.laundry);
                    Navigator.pop(context);
                  }
                : null,
          ),
          new ListTile(
            leading: new Icon(Icons.memory),
            title: new Text('CloudBits'),
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
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Loading'),
      ),
      body: new Center(
        child: new Text('Please Stand By...'),
      ),
    );
  }
}

class HouseOfRooves extends StatefulWidget {
  @override
  _HouseOfRoovesState createState() => new _HouseOfRoovesState();
}

class _HouseOfRoovesState extends State<HouseOfRooves> {
  void initState() {
    super.initState();
    backend.onError = (String message) {
      // add to an in-memory log that can be shown somewhere
      //assert(() { print(message); return true; });
      ScaffoldMessenger.of(context)
          .showSnackBar(new SnackBar(content: new Text(message)));
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
    if (_page == null) return new LoadingPage();
    switch (_page) {
      case HouseOfRoovesPage.remy:
        return new RemyPage();
      case HouseOfRoovesPage.cloudbits:
        return new CloudBitsPage();
      case HouseOfRoovesPage.doors:
        return new DoorsPage();
      case HouseOfRoovesPage.laundry:
        return new LaundryPage();
      case HouseOfRoovesPage.solar:
        return new SolarPage();
      case HouseOfRoovesPage.television:
        return new TelevisionPage();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          drawer: _page != null
              ? new MainDrawer(page: _page, onPageChanged: _handlePageChanged)
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

Future<Null> main() async {
  runApp(
    MaterialApp(
      title: 'House of Rooves',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        accentColor: Colors.greenAccent[700],
        accentColorBrightness: Brightness.dark,
      ),
      home: HouseOfRooves(),
    ),
  );
}
