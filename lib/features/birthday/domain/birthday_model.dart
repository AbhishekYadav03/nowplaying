import 'package:cloud_firestore/cloud_firestore.dart';

class BirthdayConfig {
  final bool enabled;
  final int year;

  const BirthdayConfig({
    required this.enabled,
    required this.year,
  });

  factory BirthdayConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BirthdayConfig(
      enabled: data['enabled'] ?? false,
      year: data['year'] ?? DateTime.now().year,
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'year': year,
      };
}

class BirthdayContent {
  final String opening;
  final String story;
  final List<BirthdayChapter> chapters;
  final String may8Title;
  final String may8Message;
  final List<String> ifICouldCards;
  final List<BirthdayMilestone> timeline;
  final String cakeMessage;
  final String finalLetter;

  const BirthdayContent({
    required this.opening,
    required this.story,
    required this.chapters,
    required this.may8Title,
    required this.may8Message,
    required this.ifICouldCards,
    required this.timeline,
    required this.cakeMessage,
    required this.finalLetter,
  });

  factory BirthdayContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BirthdayContent(
      opening: data['opening'] ?? '',
      story: data['story'] ?? '',
      chapters: (data['chapters'] as List? ?? [])
          .map((e) => BirthdayChapter.fromMap(e as Map<String, dynamic>))
          .toList(),
      may8Title: data['may8Title'] ?? '',
      may8Message: data['may8Message'] ?? '',
      ifICouldCards: List<String>.from(data['ifICouldCards'] ?? []),
      timeline: (data['timeline'] as List? ?? [])
          .map((e) => BirthdayMilestone.fromMap(e as Map<String, dynamic>))
          .toList(),
      cakeMessage: data['cakeMessage'] ?? '',
      finalLetter: data['finalLetter'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'opening': opening,
        'story': story,
        'chapters': chapters.map((e) => e.toMap()).toList(),
        'may8Title': may8Title,
        'may8Message': may8Message,
        'ifICouldCards': ifICouldCards,
        'timeline': timeline.map((e) => e.toMap()).toList(),
        'cakeMessage': cakeMessage,
        'finalLetter': finalLetter,
      };

  factory BirthdayContent.defaultContent() {
    return BirthdayContent(
      opening: "Happy Birthday ❤️\n\nToday isn't just another day.\n\nToday the world became a little brighter.\n\nBecause you were born.",
      story: "I could have sent you a message.\n\nI could have called.\n\nInstead...\n\nI wanted to build something\nyou could remember.",
      chapters: [
        const BirthdayChapter(title: "Chapter 1", subtitle: "The Beginning", content: "It all started with a simple hello..."),
        const BirthdayChapter(title: "Chapter 2", subtitle: "Late Night Conversations", content: "Those hours spent talking about everything and nothing..."),
        const BirthdayChapter(title: "Chapter 3", subtitle: "The Little Moments", content: "The way you smile, the way you laugh..."),
        const BirthdayChapter(title: "Chapter 4", subtitle: "Today", content: "And here we are, celebrating you."),
      ],
      may8Title: "8th May",
      may8Message: "I saw you.\n\nYou were surrounded by your family.\n\nWe couldn't talk.\n\nBut seeing you made my entire day.\n\nOne day there won't be a crowd between us.",
      ifICouldCards: [
        "I'd bring you flowers.",
        "I'd take you to your favorite place.",
        "I'd listen to every story.",
        "I'd make sure you smiled all day.",
      ],
      timeline: [
        const BirthdayMilestone(title: "Today", date: "❤️"),
        const BirthdayMilestone(title: "The Day We Meet", date: "🤝"),
        const BirthdayMilestone(title: "Wedding", date: "💍"),
        const BirthdayMilestone(title: "Forever", date: "🏡"),
      ],
      cakeMessage: "I hope every wish you made today comes true.",
      finalLetter: "Happy Birthday ❤️\n\nI couldn't celebrate beside you.\n\nBut I hope this little experience made you smile.\n\nOne day I won't need an app to wish you.\n\nI'll be standing right beside you.\n\nUntil then...\n\nI love you.",
    );
  }
}

class BirthdayChapter {
  final String title;
  final String subtitle;
  final String content;

  const BirthdayChapter({
    required this.title,
    required this.subtitle,
    required this.content,
  });

  factory BirthdayChapter.fromMap(Map<String, dynamic> map) {
    return BirthdayChapter(
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      content: map['content'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'content': content,
      };
}

class BirthdayMilestone {
  final String title;
  final String date;

  const BirthdayMilestone({
    required this.title,
    required this.date,
  });

  factory BirthdayMilestone.fromMap(Map<String, dynamic> map) {
    return BirthdayMilestone(
      title: map['title'] ?? '',
      date: map['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'date': date,
      };
}
