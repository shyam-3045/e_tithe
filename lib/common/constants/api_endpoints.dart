class ApiEndpoints {
  const ApiEndpoints._();

  static const String login = '/api/Auth/login';
  static const String donor = '/api/Donor';
  static String donorById(int donorId) => '/api/Donor/$donorId';
  static const String region = '/api/Region';
  static String userById(int userId) => '/api/User/$userId';
  static const String receipt = '/api/Receipt';
  static const String receiptByRepTypeRepIdAndReceiptDate =
      '/api/Receipt/ByRepTypeRepIdAndReceiptDate';
  static const String receiptGenerateNo = '/api/Receipt/GenerateReceiptNo';
  static const String company = '/api/Company';
  static const String paymentMode = '/api/PaymentMode';
  static const String fund = '/api/Fund';
  static const String area = '/api/Area';
}
