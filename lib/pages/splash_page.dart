import 'package:flutter/material.dart';
import '../services/auth_service.dart';


class SplashPage extends StatefulWidget {

const SplashPage({super.key});


@override
State<SplashPage> createState()
=> _SplashPageState();

}



class _SplashPageState extends State<SplashPage>{


final auth = AuthService();



@override
void initState(){

super.initState();

verificar();

}



void verificar() async {


await Future.delayed(
const Duration(seconds:1)
);



final token = await auth.getToken();



if(!mounted) return;



if(token != null){


Navigator.pushReplacementNamed(
context,
"/produtos"
);


}else{


Navigator.pushReplacementNamed(
context,
"/login"
);


}



}



@override
Widget build(BuildContext context){


return const Scaffold(


body: Center(

child:CircularProgressIndicator(),

),


);


}


}