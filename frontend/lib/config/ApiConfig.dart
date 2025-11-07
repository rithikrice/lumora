// lib/config/Apiconfig.dart

class ApiConfig {
  // ====== Base URLs ======
  static const String baseUrl =
      "https://analystai-backend-752741439479.us-central1.run.app";

  static const String healthCheck = "$baseUrl/health";
  static const String videoUpload = "$baseUrl/v1/video/upload ";
}
