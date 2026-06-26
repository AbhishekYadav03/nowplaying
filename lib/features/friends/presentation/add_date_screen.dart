import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/shared/data/firestore_service.dart';
import 'package:nowplaying/shared/domain/relationship_date_model.dart';

class AddDateScreen extends ConsumerStatefulWidget {
  final String friendId;
  final RelationshipDateModel? initialDate;

  const AddDateScreen({super.key, required this.friendId, this.initialDate});

  @override
  ConsumerState<AddDateScreen> createState() => _AddDateScreenState();
}

class _AddDateScreenState extends ConsumerState<AddDateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  late bool _isRecursive;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialDate?.title ?? '');
    _descController = TextEditingController(text: widget.initialDate?.description ?? '');
    _selectedDate = widget.initialDate?.date ?? DateTime.now();
    _isRecursive = widget.initialDate?.isRecursive ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceHigh,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final dateModel = RelationshipDateModel(
      id: widget.initialDate?.id ?? '',
      friendId: widget.friendId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      date: _selectedDate,
      isRecursive: _isRecursive,
      createdAt: widget.initialDate?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.initialDate == null) {
        await ref.read(firestoreServiceProvider).addDate(uid, dateModel);
      } else {
        await ref.read(firestoreServiceProvider).updateDate(uid, dateModel);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialDate == null ? 'Add Milestone' : 'Edit Milestone')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'What is this milestone?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. First Meet, Anniversary'),
              validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            const Text(
              'A short description (optional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(hintText: 'Add some details...'),
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            const Text(
              'When did it happen?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(_selectedDate),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text(
                'Repeat Yearly',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Anniversaries, birthdays, etc.',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
              value: _isRecursive,
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _isRecursive = v),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(widget.initialDate == null ? 'Create Milestone' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}


