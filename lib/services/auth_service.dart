import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class AuthService {


  final String url = "http://localhost:8000";



  Future<String?> getToken() async {


    final prefs = await SharedPreferences.getInstance();


    return prefs.getString("token");


  }




Future<void> register(
String nome,
String email,
String senha

) async {


final response = await http.post(

Uri.parse("$url/cadastro"),


headers:{
"Content-Type":"application/json"
},


body: jsonEncode({

"nome":nome,

"email":email,

"senha":senha

})


);



if(response.statusCode != 200){

throw Exception("Erro cadastro");

}


}



  Future<void> login(
    String email,
    String senha

  ) async {



    final response = await http.post(

      Uri.parse("$url/login"),


      headers: {

        "Content-Type":"application/json"

      },


      body: jsonEncode({

        "email":email,

        "senha":senha

      }),

    );



    print(response.body);



    if(response.statusCode == 200){


      final data = jsonDecode(response.body);



      final prefs =
      await SharedPreferences.getInstance();



      await prefs.setString(

        "token",

        data["access_token"]

      );



    }else{


      throw Exception("Login inválido");


    }



  }



}