class Variable {
  static const String ip = "192.168.18.14";

  static String get baseUrl => "http://$ip:8000/api";
  static String get backendBaseUrl => "http://$ip:8000/";
  static String get storageBaseUrl => "http://$ip:8000/storage/";
}
