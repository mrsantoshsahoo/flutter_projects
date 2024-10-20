import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package/resizer/resize_widgets.dart';

void main() => runApp(const NavigationRailExampleApp());

class NavigationRailExampleApp extends StatelessWidget {
  const NavigationRailExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NavRailExample(),
    );
  }
}

class NavRailExample extends StatefulWidget {
  const NavRailExample({super.key});

  @override
  State<NavRailExample> createState() => _NavRailExampleState();
}

class _NavRailExampleState extends State<NavRailExample> {
  int _selectedIndex = 0;
  NavigationRailLabelType labelType = NavigationRailLabelType.selected;
  bool showLeading = false;
  bool showTrailing = false;
  double groupAlignment = -1.0;

  void _printResizeInfo(List<WidgetSizeInfo> dataList) {
    // ignore: avoid_print
    print(dataList.map((x) => '(${x.size}, ${x.percentage}%)').join(", "));
  }

  double _containerWidth = 200.0; // Initial width of the container

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              width: size.width,
              height: 40,
              child: Container(color: Colors.grey),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  NavigationRail(
                    minWidth: 50,
                    selectedIndex: _selectedIndex,
                    // groupAlignment: groupAlignment,
                    onDestinationSelected: (int index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    trailing: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.settings),
                    ),
                    destinations: const <NavigationRailDestination>[
                      NavigationRailDestination(
                        icon: Icon(Icons.favorite_border),
                        selectedIcon: Icon(Icons.favorite),
                        label: Text('First'),
                      ),
                      NavigationRailDestination(
                        icon: Badge(child: Icon(Icons.bookmark_border)),
                        selectedIcon: Badge(child: Icon(Icons.book)),
                        label: Text('Second'),
                      ),
                      NavigationRailDestination(
                        icon: Badge(
                          label: Text('4'),
                          child: Icon(Icons.star_border),
                        ),
                        selectedIcon: Badge(
                          label: Text('4'),
                          child: Icon(Icons.star),
                        ),
                        label: Text('Third'),
                      ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: Row(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: _containerWidth,
                              color: Colors.black12,
                              child: const Column(
                                children: [],
                              ),
                            ),
                            GestureDetector(
                              child: const MouseRegion(
                                cursor: SystemMouseCursors.resizeColumn,
                                child: VerticalDivider(
                                  thickness: 5,
                                  width: 5,
                                  color: Colors.grey,
                                ),
                              ),
                              onPanUpdate: (details) {
                                setState(() {
                                  if (_containerWidth >= 200) {
                                    _containerWidth += details.delta.dx;
                                  } else {
                                    _containerWidth = 200;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const Expanded(child: UiBoard()),
                        const VerticalDivider(thickness: 1, width: 1,color: Colors.black,),
                        SizedBox(
                            width: 250,
                            child: Container(color: Colors.black26)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UiBoard extends StatefulWidget {
  const UiBoard({super.key});

  @override
  State<UiBoard> createState() => _UiBoardState();
}

class _UiBoardState extends State<UiBoard> {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return  Scaffold(
      backgroundColor: Colors.black54,
      body: InteractiveViewer(
        panEnabled: false,
        // boundaryMargin: EdgeInsets.all(100),
        // minScale: 0.0001,
        // maxScale: 10,
        child: Center(
          child: Container(
            height:844,
            width: 390,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

