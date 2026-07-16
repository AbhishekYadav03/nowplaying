import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/features/auth/domain/user_model.dart';
import 'package:nowplaying/features/birthday/domain/birthday_model.dart';
import 'package:nowplaying/features/birthday/presentation/birthday_experience_screen.dart';
import 'package:nowplaying/shared/data/firestore_service.dart';

class BirthdayAdminScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const BirthdayAdminScreen({super.key, required this.user});

  @override
  ConsumerState<BirthdayAdminScreen> createState() => _BirthdayAdminScreenState();
}

class _BirthdayAdminScreenState extends ConsumerState<BirthdayAdminScreen> {
  late TextEditingController _openingCtrl;
  late TextEditingController _storyCtrl;
  late TextEditingController _may8TitleCtrl;
  late TextEditingController _may8MsgCtrl;
  late TextEditingController _cakeMsgCtrl;
  late TextEditingController _finalLetterCtrl;

  @override
  void initState() {
    super.initState();
    _openingCtrl = TextEditingController();
    _storyCtrl = TextEditingController();
    _may8TitleCtrl = TextEditingController();
    _may8MsgCtrl = TextEditingController();
    _cakeMsgCtrl = TextEditingController();
    _finalLetterCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _openingCtrl.dispose();
    _storyCtrl.dispose();
    _may8TitleCtrl.dispose();
    _may8MsgCtrl.dispose();
    _cakeMsgCtrl.dispose();
    _finalLetterCtrl.dispose();
    super.dispose();
  }

  void _fillContent(BirthdayContent content) {
    if (_openingCtrl.text.isEmpty) _openingCtrl.text = content.opening;
    if (_storyCtrl.text.isEmpty) _storyCtrl.text = content.story;
    if (_may8TitleCtrl.text.isEmpty) _may8TitleCtrl.text = content.may8Title;
    if (_may8MsgCtrl.text.isEmpty) _may8MsgCtrl.text = content.may8Message;
    if (_cakeMsgCtrl.text.isEmpty) _cakeMsgCtrl.text = content.cakeMessage;
    if (_finalLetterCtrl.text.isEmpty) _finalLetterCtrl.text = content.finalLetter;
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.user.partnerBirthday ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      await ref.read(firestoreServiceProvider).updatePartnerBirthday(widget.user.uid, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userStreamProvider(widget.user.uid));
    final configAsync = ref.watch(birthdayConfigStreamProvider);
    final contentAsync = ref.watch(birthdayContentStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Birthday Admin'),
        actions: [
          contentAsync.when(
            data: (content) => TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BirthdayExperienceScreen(
                      content: content,
                      year: DateTime.now().year,
                    ),
                  ),
                );
              },
              child: const Text('Preview'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: 'CONFIGURATION',
                  child: configAsync.when(
                    data: (config) => Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Enable Experience'),
                          value: config.enabled,
                          onChanged: (val) {
                            ref.read(firestoreServiceProvider).updateBirthdayConfig(
                                  config.copyWith(enabled: val),
                                );
                          },
                        ),
                        ListTile(
                          title: const Text('Target Year'),
                          subtitle: Text('${config.year}'),
                          onTap: () async {
                            final year = await _showYearPicker(config.year);
                            if (year != null) {
                              ref.read(firestoreServiceProvider).updateBirthdayConfig(
                                    config.copyWith(year: year),
                                  );
                            }
                          },
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'PARTNER INFO',
                  child: ListTile(
                    title: const Text('Partner Birthday'),
                    subtitle: Text(
                      user.partnerBirthday != null
                          ? DateFormat('MMMM dd').format(user.partnerBirthday!)
                          : 'Not set',
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: _pickBirthday,
                  ),
                ),
                const SizedBox(height: 24),
                contentAsync.when(
                  data: (content) {
                    _fillContent(content);
                    return _buildSection(
                      title: 'CONTENT',
                      child: Column(
                        children: [
                          _buildTextField(_openingCtrl, 'Opening Message', maxLines: 5),
                          _buildTextField(_storyCtrl, 'Story Message', maxLines: 5),
                          _buildTextField(_may8TitleCtrl, '8th May Title'),
                          _buildTextField(_may8MsgCtrl, '8th May Message', maxLines: 5),
                          _buildTextField(_cakeMsgCtrl, 'Cake Message'),
                          _buildTextField(_finalLetterCtrl, 'Final Letter', maxLines: 10),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => _saveContent(content),
                            child: const Text('Save Content'),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textTertiary),
          border: const UnderlineInputBorder(),
        ),
      ),
    );
  }

  Future<int?> _showYearPicker(int currentYear) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        int selected = currentYear;
        return AlertDialog(
          title: const Text('Select Year'),
          content: StatefulBuilder(
            builder: (context, setState) => DropdownButton<int>(
              value: selected,
              items: [2024, 2025, 2026, 2027, 2028]
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                  .toList(),
              onChanged: (val) => setState(() => selected = val!),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, selected), child: const Text('OK')),
          ],
        );
      },
    );
  }

  void _saveContent(BirthdayContent existing) {
    final updated = BirthdayContent(
      opening: _openingCtrl.text,
      story: _storyCtrl.text,
      chapters: existing.chapters,
      may8Title: _may8TitleCtrl.text,
      may8Message: _may8MsgCtrl.text,
      ifICouldCards: existing.ifICouldCards,
      timeline: existing.timeline,
      cakeMessage: _cakeMsgCtrl.text,
      finalLetter: _finalLetterCtrl.text,
    );
    ref.read(firestoreServiceProvider).updateBirthdayContent(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content saved!'), backgroundColor: AppColors.primary),
    );
  }
}

// Providers for Birthday Config and Content
final birthdayConfigStreamProvider = StreamProvider<BirthdayConfig>((ref) {
  return ref.watch(firestoreServiceProvider).birthdayConfigStream();
});

final birthdayContentStreamProvider = StreamProvider<BirthdayContent>((ref) {
  return ref.watch(firestoreServiceProvider).birthdayContentStream();
});

// Helper for copyWith in BirthdayConfig
extension BirthdayConfigExt on BirthdayConfig {
  BirthdayConfig copyWith({bool? enabled, int? year}) {
    return BirthdayConfig(
      enabled: enabled ?? this.enabled,
      year: year ?? this.year,
    );
  }
}
