import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Importa las clases específicas de Android
import 'package:webview_flutter_android/webview_flutter_android.dart';

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
    _initializeWebView();
  }

  // Método para inicializar el WebViewController y cargar la página
  void _initializeWebView() {
    final PlatformWebViewControllerCreationParams params =
        const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(params);

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Página empezó a cargar: $url');
          },
          onPageFinished: (String url) {
            print('Página terminó de cargar: $url');
            if (_currentPosition != null) {
              _sendLocationToWebView();
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('Error cargando la página: $error');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://app.sicotys.com'));

    // Solo habilitar la depuración para Android
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
    }
  }

  // Método para solicitar permisos y obtener la ubicación
  Future<void> _getLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('El servicio de ubicación está deshabilitado.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permiso de ubicación denegado.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Permisos de ubicación denegados permanentemente.');
      return;
    }

    _getCurrentLocation();
  }

  // Método para obtener la ubicación actual
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        print(
            'Ubicación obtenida: ${position.latitude}, ${position.longitude}');
        _sendLocationToWebView();
      });
    } catch (e) {
      print('Error al obtener la ubicación: $e');
    }
  }

  // Enviar la ubicación al WebView mediante JavaScript
  void _sendLocationToWebView() {
    if (_controller != null && _currentPosition != null) {
      String lat = _currentPosition!.latitude.toString();
      String lng = _currentPosition!.longitude.toString();
      String script = "window.flutterLocationReceived($lat, $lng);";
      _controller.runJavaScript(script);
      print('Ubicación enviada al WebView: $lat, $lng');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Yopal'),
        backgroundColor: Colors.blue,
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}
