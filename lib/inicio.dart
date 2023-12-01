import 'package:flutter/material.dart';
import 'package:juegos/cargar.dart';
import 'package:juegos/main.dart';


class HomeScreen extends StatelessWidget {
  final String username;

  HomeScreen({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF00563F),
        title: Text('Pagina de inicio ',
        style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
        centerTitle: true,
      ),
      drawer: Drawer(surfaceTintColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text("BIENVENIDO USUARIO",style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(username,style: TextStyle(fontSize: 15)), 
              ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud_upload),
              title: Text('Cargar base de dato'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoadScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Cerrar Sesión'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text('Contenido de la pantalla de inicio'),
      ),
    );
  }
}