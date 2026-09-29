class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.statusCode,
    this.errors = const <String, List<String>>{},
  });

  final String message;
  final int statusCode;
  final Map<String, List<String>> errors;

  @override
  String toString() => message;
}
