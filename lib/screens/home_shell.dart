import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import 'entries_screen.dart';
import 'import_export_screen.dart';
import 'manage_lists_screen.dart';
import 'reports_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();

    final pages = const [
      EntriesScreen(),
      ReportsScreen(),
      ManageListsScreen(),
      ImportExportScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const _LogoBadge(),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.companyName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(l.appSubtitle,
                    style: const TextStyle(fontSize: 11, height: 1)),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: l.language,
            initialValue: state.locale.languageCode,
            onSelected: (code) => context.read<AppState>().setLocale(code),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'ar', child: Text(l.arabic)),
              PopupMenuItem(value: 'en', child: Text(l.english)),
            ],
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.list_alt), label: l.entries),
          NavigationDestination(
              icon: const Icon(Icons.bar_chart), label: l.reports),
          NavigationDestination(
              icon: const Icon(Icons.people_alt), label: l.manageLists),
          NavigationDestination(
              icon: const Icon(Icons.swap_vert), label: l.importExport),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Q',
        style: TextStyle(
          color: Color(0xFF0D47A1),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }
}
