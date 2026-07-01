import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';

class ManageListsScreen extends StatelessWidget {
  const ManageListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: [
                Tab(text: l.projects),
                Tab(text: l.technicians),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ListManager(isProject: true),
                _ListManager(isProject: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListManager extends StatelessWidget {
  final bool isProject;
  const _ListManager({required this.isProject});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final items = isProject ? state.projects : state.technicians;

    return Scaffold(
      body: items.isEmpty
          ? Center(child: Text(l.noData))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final name = items[i];
                return ListTile(
                  leading: Icon(isProject ? Icons.apartment : Icons.engineering),
                  title: Text(name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: l.rename,
                        onPressed: () => _rename(context, name),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l.delete,
                        onPressed: () => _delete(context, name),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: Text(isProject ? l.addProject : l.addTechnician),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final name = await _prompt(context, isProject);
    if (name == null || name.trim().isEmpty) return;
    final state = context.read<AppState>();
    if (isProject) {
      await state.addProject(name);
    } else {
      await state.addTechnician(name);
    }
  }

  Future<void> _rename(BuildContext context, String old) async {
    final name = await _prompt(context, isProject, initial: old);
    if (name == null || name.trim().isEmpty || name == old) return;
    final state = context.read<AppState>();
    if (isProject) {
      await state.renameProject(old, name);
    } else {
      await state.renameTechnician(old, name);
    }
  }

  Future<void> _delete(BuildContext context, String name) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.confirmDelete),
        content: Text(name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: Text(l.no)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true), child: Text(l.yes)),
        ],
      ),
    );
    if (ok == true) {
      final state = context.read<AppState>();
      if (isProject) {
        await state.deleteProject(name);
      } else {
        await state.deleteTechnician(name);
      }
    }
  }

  Future<String?> _prompt(BuildContext context, bool isProject,
      {String? initial}) {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isProject ? l.addProject : l.addTechnician),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l.name),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l.save)),
        ],
      ),
    );
  }
}
