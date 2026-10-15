import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String kHomeUrl = 'https://acorazacr.com/';
const String kHomeHost = 'acorazacr.com';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AcorazaApp());
}

class AcorazaApp extends StatelessWidget {
  const AcorazaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Acoraza CR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
      home: const WebShell(),
    );
  }
}

class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => setState(() => _hasError = false),
          onWebResourceError: (error) {
            // Solo mostramos la pantalla de error si falla la página principal,
            // no un recurso secundario (imagen, script de terceros, etc.).
            if (error.isForMainFrame ?? true) {
              setState(() => _hasError = true);
            }
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(Uri.parse(kHomeUrl));
  }

  /// Mantiene dentro de la app las URLs del sitio; abre fuera WhatsApp,
  /// teléfono, correo, mapas y dominios externos.
  Future<NavigationDecision> _handleNavigation(NavigationRequest request) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    final isWeb = uri.scheme == 'http' || uri.scheme == 'https';
    final isOwnSite = uri.host == kHomeHost || uri.host.endsWith('.$kHomeHost');

    // Iframes y recursos embebidos (pasarelas de pago, mapas) se cargan normal.
    if (isWeb && (isOwnSite || !request.isMainFrame)) {
      return NavigationDecision.navigate;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  }

  Future<void> _reload() async {
    setState(() => _hasError = false);
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_progress < 100 && !_hasError)
                LinearProgressIndicator(value: _progress / 100),
              if (_hasError) _ErrorView(onRetry: _reload),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: Colors.black45),
          const SizedBox(height: 16),
          const Text(
            'No se pudo cargar la página',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Revisa tu conexión a internet e inténtalo de nuevo.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
