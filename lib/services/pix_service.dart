import 'dart:convert';
import 'package:http/http.dart' as http;

class PixService {

  Future<Map<String,dynamic>> criarPix(double valor) async {

    final response = await http.post(
      Uri.parse("http://192.168.1.68/pix/criar"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "valor": valor,
        "email": "cliente@email.com"
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String,dynamic>> verificarPagamento(String id) async {

    final response = await http.get(
      Uri.parse("http://192.168.1.68/pix/status/$id"),
    );

    return jsonDecode(response.body);
  }
}