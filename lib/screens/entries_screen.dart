import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/entry.dart';
import '../providers/app_state.dart';
import 'entry_form_screen.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final nf = NumberFormat('#,##0.##');

    var entries = state.filteredEntries;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      entries = entries
          .where((e) =>
              e.project.toLowerCase().contains(q) ||
              e.technician.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      body: Column(
        children: [
          _FilterBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.search,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          _SummaryStrip(salary: state.grandTotalSalary, rest: state.grandTotalRest),
          Expanded(
            child: entries.isEmpty
                ? Center(child: Text(l.noData))
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return ListTile(
                        title: Text('${e.project}  •  ${e.technician}'),
                        subtitle: Text(
                            '${l.date}: ${e.date}   ${l.salary}: ${nf.format(e.salary)}   ${l.downPayment}: ${nf.format(e.downPayment)}'),
                        trailing: Text(
                          nf.format(e.rest),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        onTap: () => _openForm(context, e),
                        onLongPress: () => _confirmDelete(context, e),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add),
        label: Text(l.addEntry),
      ),
    );
  }

  void _openForm(BuildContext context, Entry? entry) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EntryFormScreen(entry: entry),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, Entry e) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.confirmDelete),
        content: Text(l.confirmDeleteEntry),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.no)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true), child: Text(l.yes)),
        ],
      ),
    );
    if (ok == true && e.id != null) {
      await context.read<AppState>().deleteEntry(e.id!);
    }
  }
}

class _FilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final df = DateFormat('yyyy-MM-dd');
    final hasFilter = state.fromDate != null || state.toDate != null;

    String label() {
      if (!hasFilter) return l.allDates;
      final from = state.fromDate != null ? df.format(state.fromDate!) : '…';
      final to = state.toDate != null ? df.format(state.toDate!) : '…';
      return '$from  →  $to';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, size: 20),
          const SizedBox(width: 6),
          Expanded(child: Text(label())),
          TextButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 5),
                initialDateRange: state.fromDate != null && state.toDate != null
                    ? DateTimeRange(start: state.fromDate!, end: state.toDate!)
                    : null,
              );
              if (range != null) {
                context.read<AppState>().setDateRange(range.start, range.end);
              }
            },
            icon: const Icon(Icons.event),
            label: Text(l.filterByDate),
          ),
          if (hasFilter)
            IconButton(
              tooltip: l.clearFilter,
              icon: const Icon(Icons.clear),
              onPressed: () => context.read<AppState>().clearDateRange(),
            ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final double salary;
  final double rest;
  const _SummaryStrip({required this.salary, required this.rest});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final nf = NumberFormat('#,##0.##');
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat(context, l.total, nf.format(salary)),
          _stat(context, l.rest, nf.format(rest)),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
