import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/produto.dart';



class ApiService{


final Dio dio = Dio();


final String url =
"http://10.0.2.2:8000";




Future<List<Produto>> buscarProdutos() async{


final prefs =
await SharedPreferences.getInstance();



final token =
prefs.getString(
"token"
);



final response =
await dio.get(


"$url/produtos",



options:Options(


headers:{


"Authorization":
"Bearer $token"


}


)


);



List data=response.data;



return data
.map(
(json)=>Produto.fromJson(json)
)
.toList();



}


}