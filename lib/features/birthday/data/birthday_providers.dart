import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nowplaying/features/birthday/domain/birthday_model.dart';
import 'package:nowplaying/shared/data/firestore_service.dart';

final birthdayConfigProvider = StreamProvider.family<BirthdayConfig, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).birthdayConfigStream(uid);
});

final birthdayContentProvider = StreamProvider.family<BirthdayContent, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).birthdayContentStream(uid);
});

final globalBirthdayConfigProvider = StreamProvider<BirthdayConfig>((ref) {
  return ref.watch(firestoreServiceProvider).globalBirthdayConfigStream();
});

class BirthdayTriggerState {
  final bool shouldShow;
  final BirthdayContent? content;
  final int? year;

  BirthdayTriggerState({required this.shouldShow, this.content, this.year});
}

final birthdayTriggerProvider = StreamProvider<BirthdayTriggerState>((ref) async* {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    yield BirthdayTriggerState(shouldShow: false);
    return;
  }

  final user = await ref.watch(userStreamProvider(uid).future);
  if (user == null || user.partnerId == null) {
    yield BirthdayTriggerState(shouldShow: false);
    return;
  }

  // Check if today is user's birthday (set by partner)
  final partner = await ref.watch(userStreamProvider(user.partnerId!).future);
  if (partner == null || partner.partnerBirthday == null) {
    yield BirthdayTriggerState(shouldShow: false);
    return;
  }

  final now = DateTime.now();
  final isBirthday = partner.partnerBirthday!.month == now.month &&
      partner.partnerBirthday!.day == now.day;

  if (!isBirthday) {
    yield BirthdayTriggerState(shouldShow: false);
    return;
  }

  // Fast check using flags in user document
  if (!partner.isBirthdayEnabled || partner.birthdayYear == null) {
    yield BirthdayTriggerState(shouldShow: false);
    return;
  }

  // Already completed this year
  if (user.birthdayCompleted == partner.birthdayYear) {
    yield BirthdayTriggerState(shouldShow: false);
    return;
  }

  // Fetch content from partner's document
  final content = await ref.watch(birthdayContentProvider(user.partnerId!).future);

  yield BirthdayTriggerState(
    shouldShow: true,
    content: content,
    year: partner.birthdayYear,
  );
});
