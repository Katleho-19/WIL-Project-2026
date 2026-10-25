//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: form_fields.dart defines the reusable form inputs used by every form in the app:
// the field label, the rounded text field (with password show/hide), the dropdown and the
// date-of-birth field with a date picker.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

/// FieldLabel (class) - the bold label text shown above a form field; colour defaults to the dark text colour.
class FieldLabel extends StatelessWidget {
  /// Constructor - the text is a positional parameter; color is optional.
  const FieldLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  /// build() - the label text with 6 pixels of space below it.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: color ?? AppColors.textDark,
      ),
    ),
  );
}

/// AppTextField (class) - a rounded text field with its label above it. Options include hint text, an initial
/// value or a controller, a change callback, a validator, keyboard type, password mode (adds a
/// show/hide eye button), number of lines, read-only/enabled flags, a tap callback, a suffix icon, input
/// formatters and text capitalisation. It is a StatefulWidget because it remembers whether the password is hidden.
/// Rounded text field with its label above it (as in the design).
class AppTextField extends StatefulWidget {
  /// Constructor - only label is required; every other option has a sensible default.
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.labelColor,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  final int maxLines;
  final TextInputAction textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final Color? labelColor;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  /// createState() - creates the State object (_AppTextFieldState) that holds the password-hidden flag.
  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

/// _AppTextFieldState (class) - the changing state of AppTextField.
class _AppTextFieldState extends State<AppTextField> {
  /// _hidden - true while a password field is hiding its text.
  bool _hidden = true;

  /// build() - for password fields it creates the eye icon button that toggles _hidden; then it builds the label
  /// and a TextFormField with the supplied options (validation runs as the user interacts with the field).
  @override
  Widget build(BuildContext context) {
    Widget? suffix = widget.suffixIcon;
    if (widget.isPassword) {
      suffix = IconButton(
        tooltip: _hidden ? 'Show password' : 'Hide password',
        icon: Icon(
          _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: AppColors.textMuted,
        ),
        onPressed: () => setState(() => _hidden = !_hidden),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(widget.label, color: widget.labelColor),
          TextFormField(
            controller: widget.controller,
            initialValue: widget.controller == null
                ? widget.initialValue
                : null,
            onChanged: widget.onChanged,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            obscureText: widget.isPassword && _hidden,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            textInputAction: widget.textInputAction,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            onTap: widget.onTap,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            onFieldSubmitted: widget.onFieldSubmitted,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(fontSize: 14.5),
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixIcon: suffix,
            ),
          ),
        ],
      ),
    );
  }
}

/// AppDropdown (class) - a labelled dropdown list of text options with a hint, a selected value, a change callback and an optional validator.
class AppDropdown extends StatelessWidget {
  /// Constructor - label, hint, items and onChanged are required.
  const AppDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
  });

  final String label;
  final String hint;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  /// build() - only treats 'value' as selected if it is really in the list (otherwise shows the hint), then builds the
  /// label and a DropdownButtonFormField with rounded corners and one menu item per option.
  @override
  Widget build(BuildContext context) {
    final current = (value != null && items.contains(value)) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label),
          DropdownButtonFormField<String>(
            initialValue: current,
            isExpanded: true,
            hint: Text(
              hint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted,
            ),
            decoration: const InputDecoration(),
            borderRadius: BorderRadius.circular(14),
            items: items
                .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ],
      ),
    );
  }
}

/// AppDateField (class) - a read-only field that opens a date picker when tapped and shows the chosen date as
/// DD / MM / YYYY. value is the current date, onChanged receives the picked date.
/// Read-only field that opens a date picker (DD / MM / YYYY).
class AppDateField extends StatefulWidget {
  /// Constructor - label, value and onChanged are required; validator is optional.
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final FormFieldValidator<String>? validator;

  /// createState() - creates the State object (_AppDateFieldState).
  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

/// _AppDateFieldState (class) - holds the text controller that displays the chosen date.
class _AppDateFieldState extends State<AppDateField> {
  /// _ctrl - the controller whose text is the formatted date (empty if no date is selected yet).
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.value == null ? '' : Formatters.displayDate(widget.value!),
  );

  /// dispose() - releases the text controller when the widget is removed.
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// _pick() - opens the date picker (starting at 14 years ago if no date is set, from 30 years ago up to today,
  /// with brown theme colours). If a date is chosen it updates the displayed text and calls onChanged.
  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? DateTime(now.year - 14, 1, 1),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      helpText: 'Select date of birth',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: AppColors.brown),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _ctrl.text = Formatters.displayDate(picked);
      widget.onChanged(picked);
    }
  }

  /// build() - shows an AppTextField that is read-only, opens _pick when tapped and has a calendar icon.
  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hint: 'DD / MM / YYYY',
      controller: _ctrl,
      readOnly: true,
      onTap: _pick,
      validator: widget.validator,
      suffixIcon: const Icon(
        Icons.calendar_today_outlined,
        size: 18,
        color: AppColors.textMuted,
      ),
    );
  }
}
