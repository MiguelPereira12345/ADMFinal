import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../app/session_scope.dart';
import '../widgets/request_consulta/labeled_field.dart';
import '../widgets/request_consulta/select_field.dart';
import '../widgets/request_consulta/request_consulta_card.dart';
import '../utils/app_formatters.dart';

class RequestConsultaPage extends StatefulWidget {
  final bool embedded;
  final ScrollController? scrollController;

  const RequestConsultaPage({
    super.key,
    this.embedded = false,
    this.scrollController,
  });

  @override
  State<RequestConsultaPage> createState() => _RequestConsultaPageState();
}

class _RequestConsultaPageState extends State<RequestConsultaPage> {
  static const _minAdvance = Duration(hours: 48);

  static const _bg = Color(0xFFFAF7F4);
  static const _fieldFill = Color(0xFFF1F3F5);
  static const _fieldBorder = Color(0xFFE5E7EB);

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  int? _selectedDependentId; // null => paciente
  int? _selectedDoctorId; // opcional
  int? _selectedTreatmentPlanId; // opcional
  int _selectedDurationMinutes = 30;

  late final TextEditingController _reasonController;
  late final TextEditingController _internalNotesController;

  bool _submitting = false;
  String? _error;

  Future<List<_DependentOption>>? _dependentsFuture;
  Future<List<_PlanOption>>? _plansFuture;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _internalNotesController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dependentsFuture ??= _loadDependents();
    _plansFuture ??= _loadPlans();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _internalNotesController.dispose();
    super.dispose();
  }

  Future<List<_DependentOption>> _loadDependents() async {
    final session = SessionScope.of(context);
    final userId = session.patientId;
    if (userId == null) return const <_DependentOption>[];

    final json = await session.patientApi.listDependents(userId);
    final items = _extractList(
      json,
      keys: const ['dependents', 'dependentes', 'items', 'data'],
    );

    final out = <_DependentOption>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final m = raw.cast<String, dynamic>();
      final id = _asInt(m['id'] ?? m['dependent_id'] ?? m['id_dependente']);
      if (id == null) continue;
      final name =
          (m['nome'] ?? m['name'] ?? m['paciente_nome'] ?? 'Dependente')
              .toString();
      out.add(_DependentOption(id: id, name: name));
    }

    return out;
  }

  Future<List<_PlanOption>> _loadPlans() async {
    final session = SessionScope.of(context);
    final userId = session.patientId;
    if (userId == null) return const <_PlanOption>[];

    final json = await session.patientApi.listPlanos(userId);
    final items = _extractList(
      json,
      keys: const [
        'planos',
        'plans',
        'tratamentos',
        'treatments',
        'items',
        'data',
      ],
    );

    final out = <_PlanOption>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final m = raw.cast<String, dynamic>();
      final id = _asInt(
        m['id'] ?? m['plano_id'] ?? m['id_plano'] ?? m['id_tratamento'],
      );
      if (id == null) continue;

      final name =
          (m['titulo'] ??
                  m['nome'] ??
                  m['name'] ??
                  m['descricao'] ??
                  m['designacao'])
              ?.toString()
              .trim();
      out.add(
        _PlanOption(
          id: id,
          name: (name == null || name.isEmpty) ? 'Tratamento #$id' : name,
        ),
      );
    }

    return out;
  }

  DateTime? get _requestedAt {
    final d = _selectedDate;
    final t = _selectedTime;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  bool get _meetsMinAdvanceTime {
    final at = _requestedAt;
    if (at == null) return false;
    return !at.isBefore(DateTime.now().add(_minAdvance));
  }



  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      // No portal, a hora depende da data; ao mudar data, limpamos hora.
      _selectedTime = null;
      _error = null;
    });
  }

  Future<void> _pickTime() async {
    if (_selectedDate == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 30),
    );
    if (picked == null) return;
    setState(() {
      _selectedTime = picked;
      _error = null;
    });
  }

  Future<void> _pickDoctorId() async {
    if (_submitting) return;
    final controller = TextEditingController(
      text: _selectedDoctorId?.toString() ?? '',
    );

    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Profissional (opcional)'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ID do profissional',
              hintText: 'Ex: 12',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, -1),
              child: const Text('Limpar'),
            ),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(controller.text.trim());
                Navigator.pop(ctx, v);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (result == null) return;
    setState(() {
      _selectedDoctorId = (result == -1) ? null : result;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final session = SessionScope.of(context);
    final userId = session.patientId;
    if (userId == null) {
      setState(() => _error = 'Sessão inválida.');
      return;
    }

    final d = _selectedDate;
    final t = _selectedTime;
    if (d == null || t == null) {
      setState(() => _error = 'Selecione data e hora.');
      return;
    }

    final at = _requestedAt;
    if (at == null) {
      setState(() => _error = 'Selecione data e hora.');
      return;
    }

    if (!_meetsMinAdvanceTime) {
      setState(
        () => _error = 'Tem de pedir com pelo menos 48h de antecedência.',
      );
      return;
    }

    final payload = <String, dynamic>{
      'data_consulta': formatDateTime(d),
      'hora': formatTimeOfDay(t),
    };

    final reason = _reasonController.text.trim();
    if (reason.isNotEmpty) payload['razao_consulta'] = reason;

    if (_selectedDependentId != null) {
      payload['id_dependente'] = _selectedDependentId;
    }

    if (_selectedDurationMinutes > 0) {
      payload['duracao'] = _selectedDurationMinutes;
    }

    if (_selectedDoctorId != null) {
      payload['id_medico'] = _selectedDoctorId;
    }

    if (_selectedTreatmentPlanId != null) {
      payload['id_tratamento'] = _selectedTreatmentPlanId;
    }

    final notas = _internalNotesController.text.trim();
    if (notas.isNotEmpty) payload['notas_internas'] = notas;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await session.patientApi.requestConsulta(userId, payload);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Pedido criado.')));
      navigator.pop(true);
    } catch (e) {
      final status = (e is ApiException) ? e.status : null;
      if (status == 401 || status == 403) {
        await session.logout();
        if (!mounted) return;
        navigator.pushNamedAndRemoveUntil('/login', (r) => false);
        return;
      }
      if (!mounted) return;
      setState(() => _error = 'Erro ao criar pedido: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    final dateLabel = _selectedDate == null
        ? 'Selecionar'
        : formatDateTime(_selectedDate!);
    final timeLabel = _selectedTime == null
        ? 'Selecionar'
        : formatTimeOfDay(_selectedTime!);

    final pacienteLabel = session.user?.nome.trim().isNotEmpty == true
        ? session.user!.nome
        : 'Paciente';

    final content = SafeArea(
      top: !widget.embedded,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          RequestConsultaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Dados da Consulta',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Preenche a informação conforme o processo clínico.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;

                    Widget pair(Widget left, Widget right) {
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: left),
                            const SizedBox(width: 14),
                            Expanded(child: right),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [left, const SizedBox(height: 12), right],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        pair(
                          LabeledField(
                            label: 'Paciente',
                            child: FutureBuilder<List<_DependentOption>>(
                              future: _dependentsFuture,
                              builder: (context, snapshot) {
                                final dependents =
                                    snapshot.data ?? const <_DependentOption>[];
                                final items = <DropdownMenuItem<int?>>[
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text(pacienteLabel),
                                  ),
                                  ...dependents.map(
                                    (d) => DropdownMenuItem<int?>(
                                      value: d.id,
                                      child: Text(d.name),
                                    ),
                                  ),
                                ];

                                return DropdownButtonFormField<int?>(
                                  initialValue: _selectedDependentId,
                                  items: items,
                                  onChanged: _submitting
                                      ? null
                                      : (v) => setState(() {
                                          _selectedDependentId = v;
                                          _error = null;
                                        }),
                                  decoration: _fieldDecoration(
                                    hint: 'Selecione',
                                  ),
                                );
                              },
                            ),
                          ),
                          LabeledField(
                            label: 'Tratamentos (opcional)',
                            child: FutureBuilder<List<_PlanOption>>(
                              future: _plansFuture,
                              builder: (context, snapshot) {
                                final plans =
                                    snapshot.data ?? const <_PlanOption>[];
                                final items = <DropdownMenuItem<int?>>[
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('-- Sem tratamento --'),
                                  ),
                                  ...plans.map(
                                    (p) => DropdownMenuItem<int?>(
                                      value: p.id,
                                      child: Text(p.name),
                                    ),
                                  ),
                                ];

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    DropdownButtonFormField<int?>(
                                      initialValue: _selectedTreatmentPlanId,
                                      items: items,
                                      onChanged: _submitting
                                          ? null
                                          : (v) => setState(() {
                                              _selectedTreatmentPlanId = v;
                                              _error = null;
                                            }),
                                      decoration: _fieldDecoration(
                                        hint: '-- Sem tratamento --',
                                      ),
                                    ),
                                    if (plans.isEmpty) ...[
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Sem tratamentos para esta seleção.',
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        pair(
                          LabeledField(
                            label: 'Profissional',
                            child: SelectField(
                              enabled: !_submitting,
                              value: _selectedDoctorId == null
                                  ? 'Selecione'
                                  : 'ID ${_selectedDoctorId!}',
                              onTap: _pickDoctorId,
                              decoration: _fieldDecoration(hint: 'Selecione'),
                            ),
                          ),
                          LabeledField(
                            label: 'Especialidade',
                            child: SelectField(
                              enabled: false,
                              value: 'Clínica Geral',
                              onTap: null,
                              decoration: _fieldDecoration(hint: ''),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        pair(
                          LabeledField(
                            label: 'Data',
                            child: SelectField(
                              enabled: !_submitting,
                              value: dateLabel,
                              onTap: _pickDate,
                              decoration: _fieldDecoration(
                                hint: 'Selecione',
                                icon: Icons.calendar_today_outlined,
                              ),
                            ),
                          ),
                          LabeledField(
                            label: 'Hora',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SelectField(
                                  enabled:
                                      !_submitting && _selectedDate != null,
                                  value: timeLabel,
                                  onTap: (_submitting || _selectedDate == null)
                                      ? null
                                      : _pickTime,
                                  decoration: _fieldDecoration(
                                    hint: 'Selecione',
                                    icon: Icons.access_time_outlined,
                                  ),
                                ),
                                if (_selectedDate == null) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Seleciona primeiro a data.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        LabeledField(
                          label: 'Tipo de marcação',
                          child: SelectField(
                            enabled: false,
                            value: 'Vaga',
                            onTap: null,
                            decoration: _fieldDecoration(hint: ''),
                          ),
                        ),

                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'Razão da consulta',
                          child: TextField(
                            controller: _reasonController,
                            enabled: !_submitting,
                            decoration: _fieldDecoration(hint: ''),
                            minLines: 2,
                            maxLines: 4,
                          ),
                        ),

                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'Notas internas',
                          child: TextField(
                            controller: _internalNotesController,
                            enabled: !_submitting,
                            decoration: _fieldDecoration(hint: ''),
                            minLines: 2,
                            maxLines: 4,
                          ),
                        ),

                        const SizedBox(height: 12),
                        if (_selectedDate != null && _selectedTime != null) ...[
                          Text(
                            _meetsMinAdvanceTime
                                ? 'OK: cumpre a regra das 48h.'
                                : 'Atenção: tem de ser pelo menos 48h no futuro.',
                            style: TextStyle(
                              color: _meetsMinAdvanceTime
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'O pedido tem de ser para pelo menos 48h no futuro.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFA87B05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: _fieldBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFA87B05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Enviar pedido'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return Material(color: _bg, child: content);
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Marcar consulta'),
        backgroundColor: _bg,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: content,
    );
  }

  static InputDecoration _fieldDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      filled: true,
      fillColor: _fieldFill,
      prefixIcon: icon == null ? null : Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  static List<dynamic> _extractList(
    Map<String, dynamic> json, {
    required List<String> keys,
  }) {
    for (final k in keys) {
      final v = json[k];
      if (v is List) return v;
    }
    return const [];
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }
}

class _DependentOption {
  final int id;
  final String name;
  const _DependentOption({required this.id, required this.name});
}

class _PlanOption {
  final int id;
  final String name;
  const _PlanOption({required this.id, required this.name});
}
