import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

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
                Tab(text: l.technicianReport),
                Tab(text: l.projectReport),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _TechReport(),
                _ProjectReport(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechReport extends StatelessWidget {
  const _TechReport();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final nf = NumberFormat('#,##0.##');
    final rows = state.technicianReport;

    return Column(
      children: [
        _TotalsHeader(
          left: '${l.total}: ${nf.format(state.grandTotalSalary)}',
          right: '${l.totalRest}: ${nf.format(state.grandTotalRest)}',
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text(l.noData))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(l.technician)),
                        DataColumn(label: Text(l.total), numeric: true),
                        DataColumn(label: Text(l.rest), numeric: true),
                      ],
                      rows: rows
                          .map((r) => DataRow(cells: [
                                DataCell(Text(r.name)),
                                DataCell(Text(nf.format(r.total))),
                                DataCell(Text(nf.format(r.rest))),
                              ]))
                          .toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ProjectReport extends StatelessWidget {
  const _ProjectReport();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final nf = NumberFormat('#,##0.##');
    final rows = state.projectReport;

    return Column(
      children: [
        _TotalsHeader(
          left: '${l.grandTotal}: ${nf.format(state.grandTotalSalary)}',
          right: '',
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text(l.noData))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(l.project)),
                        DataColumn(label: Text(l.total), numeric: true),
                      ],
                      rows: rows
                          .map((r) => DataRow(cells: [
                                DataCell(Text(r.name)),
                                DataCell(Text(nf.format(r.total))),
                              ]))
                          .toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _TotalsHeader extends StatelessWidget {
  final String left;
  final String right;
  const _TotalsHeader({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (right.isNotEmpty)
            Text(right,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
