import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/entry.dart';
import '../providers/app_state.dart';

class EntryFormScreen extends StatefulWidget {
  final Entry? entry;
  const EntryFormScreen({super.key, this.entry});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  String? _project;
  String? _technician;
  late TextEditingController _salary;
  late TextEditingController _down;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _date = e != null ? DateTime.tryParse(e.date) ?? DateTime.now() : DateTime.now();
    _project = e?.project;
    _technician = e?.technician;
    _salary = TextEditingController(text: e != null ? _fmt(e.salary) : '');
    _down = TextEditingController(text: e != null ? _fmt(e.downPayment) : '');
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _salary.dispose();
    _down.dispose();
    super.dispose();
  }

  double get _rest {
    final s = double.tryParse(_salary.text) ?? 0;
    final d = double.tryParse(_down.text) ?? 0;
    return s - d;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final df = DateFormat('yyyy-MM-dd');
    final nf = NumberFormat('#,##0.##');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? l.addEntry : l.editEntry),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l.date,
                  prefixIcon: const Icon(Icons.event),
                ),
                child: Text(df.format(_date)),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: state.projects.contains(_project) ? _project : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.project,
                prefixIcon: const Icon(Icons.apartment),
              ),
              items: state.projects
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              validator: (v) => (v == null || v.isEmpty) ? l.requiredField : null,
              onChanged: (v) => setState(() => _project = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: state.technicians.contains(_technician) ? _technician : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.technician,
                prefixIcon: const Icon(Icons.engineering),
              ),
              items: state.technicians
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              validator: (v) => (v == null || v.isEmpty) ? l.requiredField : null,
              onChanged: (v) => setState(() => _technician = v),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _salary,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.salary,
                prefixIcon: const Icon(Icons.payments),
              ),
              validator: _numValidator,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _down,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.downPayment,
                prefixIcon: const Icon(Icons.money_off),
              ),
              validator: _numValidator,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.rest, style: const TextStyle(fontSize: 16)),
                  Text(nf.format(_rest),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  String? _numValidator(String? v) {
    final l = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) return l.requiredField;
    if (double.tryParse(v.trim()) == null) return l.invalidNumber;
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final df = DateFormat('yyyy-MM-dd');
    final entry = Entry(
      id: widget.entry?.id,
      date: df.format(_date),
      project: _project!,
      technician: _technician!,
      salary: double.parse(_salary.text.trim()),
      downPayment: double.parse(_down.text.trim()),
    );
    final state = context.read<AppState>();
    if (widget.entry == null) {
      await state.addEntry(entry);
    } else {
      await state.updateEntry(entry);
    }
    if (mounted) Navigator.pop(context);
  }
}
