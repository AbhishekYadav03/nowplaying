# Birthday Experience Module Implementation Plan

Implement a full-screen, immersive birthday experience for a partner, as specified in `BIRTHDAY_MODULE.md`. This includes data models, Firestore integration, an interactive UI with animations, and an admin screen for content management.

## User Review Required

- **Partner Birthday Storage**: I plan to store the `partnerBirthday` in the current user's document for ease of management from the admin screen.
- **Dependencies**: I will add `confetti` and `typewritertext` (or similar) to `pubspec.yaml` to achieve the requested effects.
- **Navigation**: The birthday experience will trigger on `FeedScreen` launch if conditions are met.

## Proposed Changes

### Core & Models

#### [NEW] [birthday_model.dart](file:///D:/Abhishek/Projects/Learn/nowplaying_flutter_app/nowplaying/lib/features/birthday/domain/birthday_model.dart)
- Define `BirthdayConfig`, `BirthdayContent`, `BirthdayChapter`, `BirthdayMilestone` models.
- Include `fromFirestore` and `toMap` methods.

#### [user_model.dart](file:///D:/Abhishek/Projects/Learn/nowplaying_flutter_app/nowplaying/lib/features/auth/domain/user_model.dart)
- Add `birthdayCompleted` (int?) and `partnerBirthday` (DateTime?) fields.

---

### Data Layer

#### [firestore_service.dart](file:///D:/Abhishek/Projects/Learn/nowplaying_flutter_app/nowplaying/lib/shared/data/firestore_service.dart)
- Add methods to fetch/update `BirthdayConfig` and `BirthdayContent`.
- Add method to update `birthdayCompleted` for a user.
- Add method to update `partnerBirthday` for a user.

---

### Presentation - Birthday Experience

#### [NEW] [birthday_experience_screen.dart](file:///D:/Abhishek/Projects/Learn/nowplaying_flutter_app/nowplaying/lib/features/birthday/presentation/birthday_experience_screen.dart)
- Main entry for the birthday journey.
- Uses `PageView` or a custom state machine to navigate through the 9 steps.
- Implements background star animations and glassmorphism.

#### [NEW] [birthday_steps_widgets.dart](file:///D:/Abhishek/Projects/Learn/nowplaying_flutter_app/nowplaying/lib/features/birthday/presentation/widgets/birthday_steps_widgets.dart)
- Individual widgets for each screen (Opening, Story, Chapters, etc.).
- `BirthdayWish` widget with interactive cake and confetti/fireworks.
- `FutureTimeline` widget for the relationship roadmap.

---

### Presentation - Admin & Trigger

#### [NEW] [birthday_admin_screen.dart](file:///D:/Abhishek/Projects/Learn/nowplaying_flutter_app/nowplaying/lib/features/birthday/presentation/birthday_admin_screen.dart)
- Screen to toggle the experience, set partner's birthday, and edit all text content.

#### [feed_screen.dart](file:///D:/Abhishek/Projects/Learn/nowplaying_flutter_app/nowplaying/lib/features/feed/presentation/feed_screen.dart)
- Add logic in `initState` or via a provider listener to trigger the `BirthdayExperienceScreen`.

#### [profile_screen.dart](file:///D:/Abhishek/Projects/Learn/nowplaying_flutter_app/nowplaying/lib/features/profile/presentation/profile_screen.dart)
- Add a link to the Birthday Admin screen (maybe restricted or hidden).

---

## Verification Plan

### Automated Tests
- N/A for UI animations, but I can add unit tests for the `BirthdayContent` model serialization.

### Manual Verification
1. **Admin Setup**: Open the Birthday Admin screen, set the partner birthday to today, enable the experience, and fill in sample content.
2. **Trigger Test**: Restart the app and verify that the `BirthdayExperienceScreen` appears automatically.
3. **Journey Flow**: Complete the entire birthday journey, verifying animations, typewriter text, and interactive elements (cake tap, swiping cards).
4. **Completion State**: Verify that after finishing, the `birthdayCompleted` year is updated in Firestore and the screen doesn't show up again on next launch.
5. **Replay Test**: Verify that the experience can be replayed (I'll add a "Memories" or "Replay" button in the Profile screen).
