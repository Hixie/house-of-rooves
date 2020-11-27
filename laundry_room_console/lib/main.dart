import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laundry Room Console',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: Console(),
    );
  }
}

class Console extends StatefulWidget {
  Console({Key key}) : super(key: key);

  @override
  _ConsoleState createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      // private mode:
      //  - disable everything when private-mode message is on
      // laundry messages:
      //  - messages with class "console-laundry"
      //  - laundry-dirty-full
      //  - laundry-washer-full
      //  - laundry-washer-running
      //  - laundry-washer-clean
      //  - laundry-dryer-full
      //  - laundry-dryer-running
      //  - laundry-dryer-clean
      //  - laundry-clean-full
      // laundry buttons:
      //  - laundryNotMuchAnyMore: no more laundry to do
      //  - laundryAutomaticWasherFull: filled washer, not started
      //  - laundryAutomaticWasherStarted: started washer
      //  - laundryAutomaticDryerFull: filled dryer, not started
      //  - laundryWasherTransfer: moved from washer to dryer
      //  - laundryDryerEmpty: emptied dryer
      //  - laundryCleanDone: empty clean pile
      //  - maybe more from the list of laundry buttons
      // laundry dryer automatic button
      //  - laundryAutomaticDryerStarted: when the dryer starts
      //  - laundryAutomaticDryerClean: when the dryer ends reasonably
      //  - laundryAutomaticDryerFull: when the dryer ends early
      // cat door:
      //  - messages with class "console-cat-door"
      //  - status: status-cat-door-open, status-cat-door-shut
      //  - buttons:
      //    - catDoorShut: shut door
      //    - catDoorOpened: open door
      //    - catsNotInside: cats not inside
      //    - quarantineCats: set policy (closes)
      //    - wildLifeAtHome: set policy (closes)
      //    - openDoorPolicy: set policy (opens)
      // cat litter status and buttons
      //  - status: messages with class "console-cat-litter"
      //  - buttons (showing only visible ones):
      //    - scoopedCatLitterDownstairs
      //    - replacedCatLitterDownstairs
      //    - orderedCatLitterDownstairs
      //    - receivedCatLitterDownstairs
      //    - canceledCatLitterDownstairs
      //    - gotCatLitterDownstairs
      //    - resetCatLitterDownstairsSupply
      child: Material(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('$_counter'),
              SizedBox(height: 12.0),
              OutlinedButton(
                child: Text('Increment', style: Theme.of(context).textTheme.headline3),
                onPressed: () {
                  setState(() {
                    _counter += 1;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
