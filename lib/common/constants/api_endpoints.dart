class ApiEndpoints {
  const ApiEndpoints._();

  static const String login = '/api/Auth/login';
  static const String donor = '/api/Donor';
  static String donorById(int donorId) => '/api/Donor/$donorId';
  static String userById(int userId) => '/api/User/$userId';
  static const String receipt = '/api/Receipt';
  static const String company = '/api/Company';
}
