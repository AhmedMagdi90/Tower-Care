import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tracker_provider.dart';
import 'actions_screen.dart';
import 'down_cells_screen.dart';
import 'down_sites_screen.dart';
import 'import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _screens = [
    DownSitesScreen(),
    DownCellsScreen(),
    ActionsScreen(),
    ImportScreen(),
  ];

  static const _titles = ['Down Sites', 'Down Cells', 'Actions', 'Import'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackerProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.watch<TrackerProvider>().isBusy;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          if (isBusy)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 16),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _index = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.cell_tower),
            label: 'Down Sites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.signal_cellular_off),
            label: 'Down Cells',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Actions'),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Import',
          ),
        ],
      ),
    );
  }
}
