import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reportes Yopal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WebViewPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getLocationPermission();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) {
          print('Página empezó a cargar: $url');
        },
        onPageFinished: (String url) {
          print('Página terminó de cargar: $url');
        },
        onWebResourceError: (WebResourceError error) {
          print('Error cargando la página: $error');
        },
      ))
      ..loadRequest(Uri.parse('https://app.sicotys.com'));
  }

  // Método para solicitar permisos y obtener la ubicación
  Future<void> _getLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si el servicio no está habilitado, no podemos continuar
      print('El servicio de ubicación está deshabilitado.');
      return;
    }

    // Verifica si se tiene permiso para la ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permiso denegado, no podemos continuar
        print('Permiso de ubicación denegado.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Los permisos han sido denegados permanentemente, no podemos solicitar permisos
      print('Los permisos de ubicación han sido denegados permanentemente.');
      return;
    }

    // Si llegamos aquí, tenemos permiso para acceder a la ubicación
    _getCurrentLocation();
  }

  // Método para obtener la ubicación actual
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      print('Ubicación obtenida: ${position.latitude}, ${position.longitude}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Yopal'),
        backgroundColor: Colors.blue,
      ),
      body: _currentPosition == null
          ? const Center(
              child:
                  CircularProgressIndicator()) // Muestra un indicador de carga mientras se obtiene la ubicación
          : WebViewWidget(controller: _controller),
    );
  }
}
