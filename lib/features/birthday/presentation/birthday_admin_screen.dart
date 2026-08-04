import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nowplaying/core/theme/theme.dart';
import 'package:nowplaying/features/auth/domain/user_model.dart';
import 'package:nowplaying/features/birthday/data/birthday_providers.dart';
import 'package:nowplaying/features/birthday/domain/birthday_model.dart';
import 'package:nowplaying/features/birthday/presentation/birthday_experience_screen.dart';
import 'package:nowplaying/shared/data/firestore_service.dart';

class PartnerBirthdaySurpriseScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const PartnerBirthdaySurpriseScreen({super.key, required this.user});

  @override
  ConsumerState<PartnerBirthdaySurpriseScreen> createState() => _PartnerBirthdaySurpriseScreenState();
}

class _PartnerBirthdaySurpriseScreenState extends ConsumerState<PartnerBirthdaySurpriseScreen> {
  late TextEditingController _openingCtrl;
  late TextEditingController _storyCtrl;
  late TextEditingController _specialDayTitleCtrl;
  late TextEditingController _specialDayMsgCtrl;
  late TextEditingController _cakeMsgCtrl;
  late TextEditingController _finalLetterCtrl;

  @override
  void initState() {
    super.initState();
    _openingCtrl = TextEditingController();
    _storyCtrl = TextEditingController();
    _specialDayTitleCtrl = TextEditingController();
    _specialDayMsgCtrl = TextEditingController();
    _cakeMsgCtrl = TextEditingController();
    _finalLetterCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _openingCtrl.dispose();
    _storyCtrl.dispose();
    _specialDayTitleCtrl.dispose();
    _specialDayMsgCtrl.dispose();
    _cakeMsgCtrl.dispose();
    _finalLetterCtrl.dispose();
    super.dispose();
  }

  void _fillContent(BirthdayContent content) {
    if (_openingCtrl.text.isEmpty) _openingCtrl.text = content.opening;
    if (_storyCtrl.text.isEmpty) _storyCtrl.text = content.story;
    if (_specialDayTitleCtrl.text.isEmpty) _specialDayTitleCtrl.text = content.specialDayTitle;
    if (_specialDayMsgCtrl.text.isEmpty) _specialDayMsgCtrl.text = content.specialDayMessage;
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
    final configAsync = ref.watch(birthdayConfigProvider(widget.user.uid));
    final contentAsync = ref.watch(birthdayContentProvider(widget.user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Partner\'s Birthday Surprise'),
        actions: [
          contentAsync.when(
            data: (content) => TextButton(
              onPressed: () {
                context.push(
                  '/birthday-experience',
                  extra: {
                    'content': content,
                    'year': DateTime.now().year,
                  },
                );
              },
              child: const Text('Preview'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
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
                          title: const Text('Enable Birthday Surprise'),
                          subtitle: const Text('When enabled, your partner will see this experience on their birthday.'),
                          value: config.enabled,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) {
                            ref.read(firestoreServiceProvider).updateBirthdayConfig(
                                  widget.user.uid,
                                  config.copyWith(enabled: val),
                                );
                          },
                        ),
                        ListTile(
                          title: const Text('Experience Year'),
                          subtitle: Text('${config.year}'),
                          onTap: () async {
                            final year = await _showYearPicker(config.year);
                            if (year != null) {
                              ref.read(firestoreServiceProvider).updateBirthdayConfig(
                                    widget.user.uid,
                                    config.copyWith(year: year),
                                  );
                            }
                          },
                        ),
                      ],
                    ),
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'PARTNER INFO',
                  child: ListTile(
                    title: const Text('Partner\'s Birthday'),
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
                      title: 'SETUP SURPRISE CONTENT',
                      child: Column(
                        children: [
                          _buildTextField(_openingCtrl, 'Opening Message', maxLines: 5),
                          _buildTextField(_storyCtrl, 'Story Message', maxLines: 5),
                          _buildTextField(_specialDayTitleCtrl, 'Special Memory Title', hint: 'e.g. 8th May'),
                          _buildTextField(_specialDayMsgCtrl, 'Special Memory Message', maxLines: 5),
                          _buildTextField(_cakeMsgCtrl, 'Cake Message'),
                          _buildTextField(_finalLetterCtrl, 'Final Letter', maxLines: 10),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton(
                              onPressed: () => _saveContent(content),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: const Text('Save Surprise Content'),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )),
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

  Widget _buildTextField(TextEditingController ctrl, String label, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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
      specialDayTitle: _specialDayTitleCtrl.text,
      specialDayMessage: _specialDayMsgCtrl.text,
      ifICouldCards: existing.ifICouldCards,
      timeline: existing.timeline,
      cakeMessage: _cakeMsgCtrl.text,
      finalLetter: _finalLetterCtrl.text,
    );
    ref.read(firestoreServiceProvider).updateBirthdayContent(widget.user.uid, updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Surprise content saved!'), backgroundColor: AppColors.primary),
    );
  }
}

// Helper for copyWith in BirthdayConfig
extension BirthdayConfigExt on BirthdayConfig {
  BirthdayConfig copyWith({bool? enabled, int? year}) {
    return BirthdayConfig(
      enabled: enabled ?? this.enabled,
      year: year ?? this.year,
    );
  }
}
