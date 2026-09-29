enum LegalDocumentType { terms, privacy }

class LegalSectionData {
  const LegalSectionData({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;
}

class LegalDocumentData {
  const LegalDocumentData({
    required this.type,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final LegalDocumentType type;
  final String title;
  final String lastUpdated;
  final List<LegalSectionData> sections;
}
