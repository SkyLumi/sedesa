import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<String?> getToken() async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: 'jwt_token');
}

void ngasiToken(String token) async {
  final storage = FlutterSecureStorage();
  await storage.write(key: 'jwt_token', value: token);
}