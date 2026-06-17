import 'package:flutter/material.dart';
import '../services/api_service.dart';



class ProdutosPage extends StatefulWidget {


const ProdutosPage({super.key});


@override
State<ProdutosPage> createState()=>_ProdutosPageState();

}



class _ProdutosPageState extends State<ProdutosPage>{


final api = ApiService();


List produtos=[];



@override
void initState(){

super.initState();

carregar();

}



void carregar() async{


final dados = await api.buscarProdutos();


setState((){

produtos=dados;

});


}



@override
Widget build(BuildContext context){


return Scaffold(


appBar: AppBar(

title: Text("Produtos"),

),



body: ListView.builder(


itemCount: produtos.length,


itemBuilder:(context,index){


return ListTile(


title: Text(

produtos[index]["nome"]

),


subtitle: Text(

"R\$ ${produtos[index]["preco"]}"

),


);


}

),


);


}



}