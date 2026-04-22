class ApiEndpoints {
  const ApiEndpoints._();

  static const String login = '/api/Auth/login';
  static const String donor = '/api/Donor';
  static String donorById(int donorId) => '/api/Donor/$donorId';
  static const String receipt = '/api/Receipt';

  // Add upcoming endpoints here as you integrate them.
  // static const String receipts = '/api/Receipt';
  // static const String areas = '/api/Area';
}
