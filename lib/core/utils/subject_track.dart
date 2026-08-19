enum MockSubjectTrack { science, art, commercial }

class MockSubjectTrackOption {
  const MockSubjectTrackOption({
    required this.track,
    required this.label,
    required this.description,
  });

  final MockSubjectTrack track;
  final String label;
  final String description;
}

const mockSubjectTrackOptions = [
  MockSubjectTrackOption(
    track: MockSubjectTrack.science,
    label: 'Science',
    description: 'English, Maths, Physics, Chemistry & Biology.',
  ),
  MockSubjectTrackOption(
    track: MockSubjectTrack.art,
    label: 'Art',
    description: 'English, Government, Economics & humanities.',
  ),
  MockSubjectTrackOption(
    track: MockSubjectTrack.commercial,
    label: 'Commercial',
    description: 'English, Maths, Economics, Commerce & Business.',
  ),
];

const _trackSubjectSlugs = <String, Map<MockSubjectTrack, List<String>>>{
  'jamb': {
    MockSubjectTrack.science: ['use-of-english', 'mathematics', 'physics', 'chemistry', 'biology'],
    MockSubjectTrack.art: ['use-of-english', 'government', 'economics', 'literature-in-english', 'crk'],
    MockSubjectTrack.commercial: ['use-of-english', 'mathematics', 'economics', 'commerce', 'government'],
  },
  'waec': {
    MockSubjectTrack.science: ['english-language', 'mathematics', 'physics', 'chemistry', 'biology'],
    MockSubjectTrack.art: ['english-language', 'government', 'economics', 'literature-in-english', 'crk'],
    MockSubjectTrack.commercial: ['english-language', 'mathematics', 'economics', 'commerce', 'government'],
  },
  'neco': {
    MockSubjectTrack.science: ['english-language', 'mathematics', 'physics', 'chemistry', 'biology'],
    MockSubjectTrack.art: ['english-language', 'government', 'economics'],
    MockSubjectTrack.commercial: ['english-language', 'mathematics', 'economics', 'government'],
  },
  'post-utme': {
    MockSubjectTrack.science: ['use-of-english', 'mathematics', 'physics', 'chemistry', 'biology'],
    MockSubjectTrack.art: ['use-of-english', 'government', 'economics'],
    MockSubjectTrack.commercial: ['use-of-english', 'mathematics', 'economics', 'government'],
  },
};

MockSubjectTrack? normalizeSubjectTrack(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return switch (value.trim().toUpperCase()) {
    'SCIENCE' => MockSubjectTrack.science,
    'ART' => MockSubjectTrack.art,
    'COMMERCIAL' => MockSubjectTrack.commercial,
    _ => null,
  };
}

String subjectTrackToApi(MockSubjectTrack track) => track.name.toUpperCase();

List<String> resolveSubjectIdsForTrack({
  required String examTypeSlug,
  required MockSubjectTrack track,
  required List<({String id, String slug})> subjects,
}) {
  final slugs = _trackSubjectSlugs[examTypeSlug]?[track] ?? const [];
  if (slugs.isEmpty || subjects.isEmpty) {
    return [];
  }
  final slugToId = {for (final s in subjects) s.slug.trim().toLowerCase(): s.id};
  final resolved = <String>[];
  for (final slug in slugs) {
    final id = slugToId[slug.toLowerCase()];
    if (id != null && !resolved.contains(id)) {
      resolved.add(id);
    }
  }
  return resolved;
}

List<int> prepYearOptions() {
  final current = DateTime.now().year;
  return List.generate(6, (index) => current + index);
}

List<int> paperYearOptions() {
  final current = DateTime.now().year;
  return List.generate(current - 1999, (index) => current - index);
}
