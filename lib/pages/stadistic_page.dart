import 'package:flutter/material.dart';
import 'package:dist_v2/pages/analysis_page.dart';
import 'package:dist_v2/pages/graphs_page.dart';

class StadisticPage extends StatefulWidget {
  const StadisticPage({Key? key}) : super(key: key);

  @override
  State<StadisticPage> createState() => _StadisticPageState();
}

class _StadisticPageState extends State<StadisticPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  int _tabIndex = 0;

  final List<BottomNavigationBarItem> _items = [
    const BottomNavigationBarItem(icon: Icon(Icons.data_object), label: 'Datos'),
    const BottomNavigationBarItem(icon: Icon(Icons.graphic_eq), label: 'Ventas'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: 2,
      initialIndex: 0,
      vsync: this,
    )..addListener(_viewSwitcher);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.grey,
          child: TabBarView(
            controller: _controller,
            children: const [
              AnalysisPage(),
              GraphsPage(),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: _items,
          backgroundColor: Colors.blueGrey,
          currentIndex: _tabIndex,
          elevation: 8,
          unselectedItemColor: Colors.white54,
          selectedItemColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          onTap: (int i) {
            _controller.animateTo(i);
            _viewSwitcher();
          },
        ),
      ),
    );
  }

  void _viewSwitcher() {
    _tabIndex = _controller.index;
    setState(() {});
  }
}
