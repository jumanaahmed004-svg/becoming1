import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/gradient_button.dart';

/// Add / Edit form. Interactive widgets used here:
/// TextFormField, DropdownButtonFormField, Radio, DatePicker, Slider,
/// Checkbox (CheckboxListTile), ElevatedButton (GradientButton) and AlertDialog.
class AchievementSheet extends StatefulWidget {
  const AchievementSheet({super.key, required this.service, this.existing});
  final AchievementService service;
  final Achievement? existing;

  @override
  State<AchievementSheet> createState() => _AchievementSheetState();
}

class _AchievementSheetState extends State<AchievementSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _reflection;
  late String _category;
  late String _status;
  late DateTime _date;
  late double _impact;
  late bool _featured;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    final now = DateTime.now();
    _title = TextEditingController(text: a?.title ?? '');
    _reflection = TextEditingController(text: a?.reflection ?? '');
    _category = a?.category ?? kCategories.first;
    if (!kCategories.contains(_category)) _category = kCategories.first;
    _status = a?.status ?? kStatuses.first;
    if (!kStatuses.contains(_status)) _status = kStatuses.first;
    _date = a?.date ?? DateTime(now.year, now.month, now.day);
    _impact = (a?.impact ?? 3).toDouble();
    _featured = a?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _reflection.dispose();
    super.dispose();
  }

  String? _dateError() {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (_status == 'Completed' && _date.isAfter(endOfToday)) {
      return "A completed achievement can't be in the future";
    }
    return null;
  }

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Achievement date',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.lilac,
                onPrimary: AppColors.bgDeep,
                surface: AppColors.surfaceHigh,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = picked);
      field.didChange(picked);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final item = Achievement(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      category: _category,
      status: _status,
      date: _date,
      reflection: _reflection.text.trim(),
      impact: _impact.round(),
      isFeatured: _featured,
    );
    try {
      if (_isEdit) {
        await widget.service.update(item); // UPDATE
      } else {
        await widget.service.create(item); // CREATE
      }
      navigator.pop();
      showAppSnack(messenger, _isEdit ? 'Changes saved' : 'Added to your journey ✨');
    } on FirebaseException catch (e) {
      showAppSnack(messenger, 'Could not save: ${e.message ?? e.code}', error: true);
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteFromSheet() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await confirmAction(
      context,
      title: 'Delete achievement?',
      message: '"${widget.existing!.title}" will be removed from your journey.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      danger: true,
    );
    if (!ok) return;
    try {
      await widget.service.delete(widget.existing!.id); // DELETE
      navigator.pop();
      showAppSnack(messenger, 'Achievement deleted');
    } on FirebaseException catch (e) {
      showAppSnack(messenger, 'Could not delete: ${e.message ?? e.code}', error: true);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final style = categoryStyle(_category);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: style.color.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Icon(style.icon, key: ValueKey(_category), color: style.color),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_isEdit ? 'Edit achievement' : 'New achievement', style: AppText.display(24)),
                            const Text('Capture what you did and what it taught you.',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Title
                  TextFormField(
                    controller: _title,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Completed my first Flutter app',
                      prefixIcon: Icon(Icons.flag_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Title is required';
                      if (v.trim().length < 3) return 'Use at least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Category (Dropdown)
                  DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(16),
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: kCategories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(children: [
                                Icon(categoryStyle(c).icon, size: 18, color: categoryStyle(c).color),
                                const SizedBox(width: 10),
                                Text(c),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v ?? _category),
                  ),
                  const SizedBox(height: 18),

                  // Status (Radio)
                  _label('Status'),
                  Row(
                    children: [
                      for (final s in kStatuses)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: s == kStatuses.first ? 10 : 0),
                            child: _StatusOption(
                              label: s,
                              selected: _status == s,
                              color: s == 'Completed' ? AppColors.mint : AppColors.gold,
                              radio: Radio<String>(
                                value: s,
                                groupValue: _status,
                                activeColor: s == 'Completed' ? AppColors.mint : AppColors.gold,
                                onChanged: (v) => setState(() => _status = v ?? _status),
                              ),
                              onTap: () => setState(() => _status = s),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Date (Date Picker) with validation
                  FormField<DateTime>(
                    initialValue: _date,
                    validator: (_) => _dateError(),
                    builder: (field) => InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _pickDate(field),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Achievement date',
                          prefixIcon: const Icon(Icons.event_rounded),
                          suffixIcon: const Icon(Icons.expand_more_rounded),
                          errorText: field.errorText,
                        ),
                        child: Text(formatDate(_date), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Impact (Slider)
                  Row(
                    children: [
                      _label('Impact'),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          kImpactLabels[_impact.round() - 1],
                          key: ValueKey(_impact.round()),
                          style: const TextStyle(color: AppColors.peach, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  Slider(
                    value: _impact,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '${_impact.round()} / 5',
                    onChanged: (v) => setState(() => _impact = v),
                  ),
                  const SizedBox(height: 8),

                  // Reflection
                  TextFormField(
                    controller: _reflection,
                    maxLines: 4,
                    minLines: 3,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Reflection (optional)',
                      hintText: 'What did I learn? How did it feel?',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Highlight (Checkbox)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: _featured ? AppColors.gold.withOpacity(0.1) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _featured ? AppColors.gold.withOpacity(0.6) : AppColors.stroke),
                    ),
                    child: CheckboxListTile(
                      value: _featured,
                      onChanged: (v) => setState(() => _featured = v ?? false),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      secondary: Icon(
                        _featured ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.gold,
                      ),
                      title: const Text('Mark as a highlight', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Highlights glow gold on your dashboard',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 22),

                  GradientButton(
                    label: _isEdit ? 'Save changes' : 'Add to my journey',
                    icon: _isEdit ? Icons.check_rounded : Icons.add_rounded,
                    loading: _saving,
                    onPressed: _save,
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _saving ? null : _deleteFromSheet,
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete this achievement'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.radio,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final Widget radio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.14) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : AppColors.stroke),
          ),
          child: Row(
            children: [
              radio,
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.text : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
