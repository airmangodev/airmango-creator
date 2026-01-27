import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/config/app_config.dart';

/// In-app WebView for OAuth login - doesn't require Chrome or external browser
class OAuthWebViewScreen extends StatefulWidget {
  final String provider; // 'google', 'apple', etc.

  const OAuthWebViewScreen({super.key, required this.provider});

  @override
  State<OAuthWebViewScreen> createState() => _OAuthWebViewScreenState();
}

class _OAuthWebViewScreenState extends State<OAuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Use a valid callback URL that Appwrite accepts
    final successUrl = '${AppConfig.appwriteEndpoint}/auth/oauth2/success';
    final failureUrl = '${AppConfig.appwriteEndpoint}/auth/oauth2/failure';
    
    // Build the OAuth URL for Appwrite
    final oauthUrl = Uri.parse(
      '${AppConfig.appwriteEndpoint}/account/sessions/oauth2/${widget.provider}'
      '?project=${AppConfig.appwriteProjectId}'
      '&success=${Uri.encodeComponent(successUrl)}'
      '&failure=${Uri.encodeComponent(failureUrl)}'
    );

    debugPrint('OAuth URL: $oauthUrl');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('WebView navigating to: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            debugPrint('WebView finished: $url');
            setState(() => _isLoading = false);
            
            // Check if we've reached a success or failure page
            if (url.contains('/auth/oauth2/success') || url.contains('success=true')) {
              // OAuth successful
              Navigator.of(context).pop(true);
            } else if (url.contains('/auth/oauth2/failure') || url.contains('error=')) {
              // OAuth failed
              Navigator.of(context).pop(false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            // Ignore minor errors
            if (error.errorType == WebResourceErrorType.unknown) return;
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            debugPrint('Navigation request: $url');
            
            // Let all navigation proceed - we check on page finish
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(oauthUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Text('Sign in with ${widget.provider.toUpperCase()}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _isLoading = true;
                        });
                        _initWebView();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: const Color(0xFF1A1A2E).withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              ),
            ),
        ],
      ),
    );
  }
}
