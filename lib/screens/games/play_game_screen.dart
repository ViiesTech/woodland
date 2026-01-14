import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/utils/three_dot_loader.dart';

class PlayGameScreen extends StatefulWidget {
  final String gameUrl;
  final String gameTitle;

  const PlayGameScreen({
    super.key,
    required this.gameUrl,
    required this.gameTitle,
  });

  @override
  State<PlayGameScreen> createState() => _PlayGameScreenState();
}

class _PlayGameScreenState extends State<PlayGameScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasContent = false;
  bool _showExternalBrowserOption = false;
  double _progress = 0;
  static const Duration _contentCheckDelay = Duration(seconds: 15);
  static const Duration _maxLoadingDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    final isIOS = !kIsWeb && Platform.isIOS;
    
    // On iOS, automatically open in external browser due to WebKit networking issues
    if (isIOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openInExternalBrowser();
        // Close this screen after opening external browser
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      });
      return;
    }
    
    // For Android and other platforms, use in-app WebView
    // Start timeout fallback and content detection
    _startContentDetection();
    _startLoadingTimeout();
    // Load game after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGame();
    });
  }

  void _startContentDetection() {
    // Check if content actually loaded after delay
    Future.delayed(_contentCheckDelay, () {
      if (mounted && !_hasContent && !_hasError) {
        _checkForContent();
      }
    });
  }

  void _startLoadingTimeout() {
    // Fallback: hide loading after max duration and offer external browser
    Future.delayed(_maxLoadingDuration, () {
      if (mounted && _isLoading) {
        print('Loading timeout reached after ${_maxLoadingDuration.inSeconds}s');
        _checkForContent();
        setState(() {
          _isLoading = false;
          if (!_hasContent && !_hasError) {
            _showExternalBrowserOption = true;
          }
        });
      }
    });
  }

  Future<void> _checkForContent() async {
    if (_webViewController == null || !mounted) return;

    try {
      // Check if page has actual content (not just white screen)
      final hasContent = await _webViewController!.evaluateJavascript(source: '''
        (function() {
          const body = document.body;
          if (!body) return false;
          
          // Check if iframe exists and has loaded
          const iframe = document.getElementById('game-iframe');
          if (iframe) {
            // Check if iframe has src and try to detect content
            const iframeSrc = iframe.src;
            if (iframeSrc && iframeSrc !== 'about:blank') {
              // Try to detect if iframe loaded (may fail due to CORS)
              try {
                const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                if (iframeDoc && iframeDoc.body) {
                  const hasCanvas = iframeDoc.querySelector('canvas') !== null;
                  const hasUnity = typeof iframe.contentWindow.Unity !== 'undefined';
                  if (hasCanvas || hasUnity || iframeDoc.body.children.length > 0) {
                    return true;
                  }
                }
              } catch (e) {
                // CORS - can't access, but iframe src is set so assume loading
                return true;
              }
            }
          }
          
          // Check body content
          const bodyText = body.innerText || body.textContent || '';
          const bodyChildren = body.children.length;
          
          // If body has children or text, assume content exists
          return bodyChildren > 1 || bodyText.trim().length > 10;
        })();
      ''');

      print('Content check result: $hasContent');
      
      if (mounted) {
        setState(() {
          _hasContent = hasContent == true;
          if (!_hasContent && !_isLoading && !_hasError) {
            _showExternalBrowserOption = true;
          }
        });
      }
    } catch (e) {
      print('Error checking content: $e');
      if (mounted && !_isLoading && !_hasError) {
        setState(() {
          _showExternalBrowserOption = true;
        });
      }
    }
  }

  void _loadGame() {
    if (_webViewController != null) {
      final isIOS = !kIsWeb && Platform.isIOS;
      
      if (isIOS) {
        // On iOS, load URL directly (like external browser) to avoid WebKit networking issues
        print('iOS detected: Loading URL directly instead of iframe');
        _webViewController!.loadUrl(
          urlRequest: URLRequest(
            url: WebUri(widget.gameUrl),
          ),
        );
      } else {
        // On Android, use iframe wrapper for better Unity WASM/GPU control
        _webViewController!.loadData(
          data: _buildIframeHtml(),
          baseUrl: WebUri(widget.gameUrl),
          mimeType: 'text/html',
          encoding: 'utf-8',
        );
      }
    }
  }

  InAppWebViewSettings _buildWebViewSettings() {
    final isIOS = !kIsWeb && Platform.isIOS;
    final isAndroid = !kIsWeb && Platform.isAndroid;
    
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      domStorageEnabled: true,
      cacheEnabled: true,
      cacheMode: CacheMode.LOAD_DEFAULT,
      clearCache: false,
      mediaPlaybackRequiresUserGesture: false,
      // Platform-specific settings - useHybridComposition is Android-only
      useHybridComposition: isAndroid,
      useShouldOverrideUrlLoading: true,
      allowsInlineMediaPlayback: true,
      supportZoom: false,
      transparentBackground: false,
      // iOS-specific user agent for better compatibility
      userAgent: isIOS
          ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
          : 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      // Unity WebGL specific settings
      allowsLinkPreview: false,
      disableHorizontalScroll: false,
      disableVerticalScroll: false,
      // Better WASM support
      useOnDownloadStart: false,
      useOnLoadResource: false,
    );
  }

  String _buildIframeHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Unity Game</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        html, body {
            width: 100%;
            height: 100vh;
            overflow: hidden;
            background-color: #000;
            position: fixed;
            top: 0;
            left: 0;
        }
        #game-container {
            width: 100%;
            height: 100vh;
            position: relative;
            overflow: hidden;
            background-color: #000;
        }
        #game-iframe {
            width: 100%;
            height: 100%;
            border: none;
            display: block;
            position: absolute;
            top: 0;
            left: 0;
        }
        .loading {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: white;
            font-family: Arial, sans-serif;
            z-index: 1;
        }
    </style>
</head>
<body>
    <div id="game-container">
        <div class="loading" id="loading">Loading game...</div>
        <iframe 
            id="game-iframe"
            src="${widget.gameUrl}"
            allow="autoplay; fullscreen; gamepad; microphone; camera; xr-spatial-tracking"
            allowfullscreen
            webkitallowfullscreen
            mozallowfullscreen
            msallowfullscreen
            style="width:100%; height:100%; border:none;"
        ></iframe>
    </div>
    <script>
        (function() {
            const iframe = document.getElementById('game-iframe');
            const loading = document.getElementById('loading');
            let hasNotifiedFlutter = false;
            
            function notifyFlutterLoaded(success, hasUnity) {
                if (hasNotifiedFlutter) return;
                hasNotifiedFlutter = true;
                
                // Notify Flutter that iframe loaded
                try {
                    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                        window.flutter_inappwebview.callHandler('iframeLoaded', {
                            success: success,
                            hasUnity: hasUnity || false
                        });
                        console.log('Notified Flutter: iframe loaded');
                    }
                } catch (e) {
                    console.log('Cannot call Flutter handler:', e);
                }
            }
            
            function hideLoading() {
                if (loading) {
                    loading.style.display = 'none';
                }
            }
            
            // Hide loading after iframe loads
            if (iframe) {
                iframe.addEventListener('load', function() {
                    console.log('Unity game iframe loaded event fired');
                    
                    // Wait for Unity to initialize inside the iframe
                    setTimeout(function() {
                        let hasUnity = false;
                        try {
                            // Try to access iframe content (might fail due to CORS)
                            const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                            const hasCanvas = iframeDoc.querySelector('canvas') !== null;
                            hasUnity = typeof iframe.contentWindow.Unity !== 'undefined' || 
                                       typeof iframe.contentWindow.unityInstance !== 'undefined';
                            
                            console.log('Unity check inside iframe - hasCanvas:', hasCanvas, 'hasUnity:', hasUnity);
                            
                            if (hasCanvas || hasUnity) {
                                console.log('Unity game detected inside iframe');
                                hideLoading();
                            } else {
                                // Even if Unity not detected, hide loading after a delay
                                console.log('Unity not detected but hiding loading anyway');
                                setTimeout(hideLoading, 3000);
                            }
                        } catch (e) {
                            // CORS might block access to iframe content
                            console.log('Cannot access iframe content (CORS):', e);
                            // Hide loading anyway after delay
                            setTimeout(hideLoading, 5000);
                        }
                        
                        // Notify Flutter
                        notifyFlutterLoaded(true, hasUnity);
                    }, 2000); // Wait 2 seconds for Unity to start loading
                });
                
                // Handle errors
                iframe.addEventListener('error', function(e) {
                    console.error('Iframe load error:', e);
                    if (loading) {
                        loading.textContent = 'Failed to load game. Please try again.';
                    }
                    notifyFlutterLoaded(false, false);
                });
            }
            
            // Fallback: If iframe doesn't fire load event within 8 seconds, assume it loaded
            setTimeout(function() {
                if (!hasNotifiedFlutter && iframe) {
                    console.log('Iframe load timeout - assuming loaded (fallback)');
                    hideLoading();
                    notifyFlutterLoaded(true, false);
                }
            }, 8000);
            
            // Listen for messages from Unity
            window.addEventListener('message', function(event) {
                console.log('Received message from Unity:', event.data);
                
                // If we receive a message, the game is likely loaded
                if (!hasNotifiedFlutter) {
                    notifyFlutterLoaded(true, true);
                }
                
                // Forward messages if needed
                if (window.parent !== window) {
                    try {
                        window.parent.postMessage(event.data, '*');
                    } catch (e) {
                        console.log('Cannot forward message:', e);
                    }
                }
            });
            
            console.log('Unity game iframe container initialized');
        })();
    </script>
</body>
</html>
    ''';
  }

  Future<void> _onLoadStart(
    InAppWebViewController controller,
    WebUri? url,
  ) async {
    final urlString = url?.toString() ?? '';
    print('Load started: $urlString');
    
    // Ignore about:blank loads (iOS initialization)
    if (urlString == 'about:blank') {
      print('Ignoring about:blank load (iOS WebView initialization)');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _progress = 0;
    });
  }

  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    // Listen for iframe loaded event from JavaScript (Android only)
    controller.addJavaScriptHandler(
      handlerName: 'iframeLoaded',
      callback: (args) {
        print('Iframe loaded callback received: $args');
        if (mounted) {
          final success = args.isNotEmpty && args[0] is Map 
              ? (args[0] as Map)['success'] == true 
              : false;
          setState(() {
            _isLoading = false;
            _hasContent = success;
            if (!success) {
              _showExternalBrowserOption = true;
            }
          });
          
          // Verify content after a delay
          if (success) {
            Future.delayed(Duration(seconds: 2), () {
              _checkForContent();
            });
          }
        }
      },
    );
    
    // Listen for Unity game loaded messages
    controller.addJavaScriptHandler(
      handlerName: 'unityGameLoaded',
      callback: (args) {
        print('Unity game loaded via iframe');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasContent = true;
          });
        }
      },
    );
  }

  Future<void> _onLoadStopDirect(
    InAppWebViewController controller,
    WebUri? url,
  ) async {
    final urlString = url?.toString() ?? '';
    print('Page loaded (direct): $urlString');
    
    // Ignore about:blank (iOS initialization)
    if (urlString == 'about:blank') {
      print('Ignoring about:blank load stop (iOS WebView initialization)');
      return;
    }
    
    if (!mounted) return;

    // For direct URL loading (iOS), check if content loaded
    await Future.delayed(Duration(milliseconds: 1000));

    try {
      // Check if Unity game elements exist
      final hasUnityContent = await controller.evaluateJavascript(source: '''
        (function() {
          // Check for Unity WebGL canvas
          const canvas = document.querySelector('canvas');
          const hasCanvas = canvas !== null;
          
          // Check for Unity instance
          const hasUnity = typeof window.Unity !== 'undefined' || 
                          typeof window.unityInstance !== 'undefined' ||
                          typeof window.Module !== 'undefined';
          
          // Check for Unity loader script
          const hasUnityScript = document.querySelector('script[src*="unity"], script[src*="loader"], script[src*=".wasm"]') !== null;
          
          return hasCanvas || hasUnity || hasUnityScript || document.body.children.length > 0;
        })();
      ''');

      print('Unity content check: $hasUnityContent');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasContent = hasUnityContent == true;
          if (!_hasContent) {
            // Check again after delay
            Future.delayed(Duration(seconds: 3), () {
              _checkForContent();
            });
          }
        });
      }
    } catch (e) {
      print('Error checking Unity content: $e');
      // Hide loading anyway after delay
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
          _checkForContent();
        }
      });
    }
  }

  Future<void> _onLoadStop(
    InAppWebViewController controller,
    WebUri? url,
  ) async {
    print('Page loaded: ${url?.toString()}');
    
    if (!mounted) return;

    // Wait a bit for the HTML to parse and iframe to start loading
    await Future.delayed(Duration(milliseconds: 500));

    // Verify the page loaded correctly
    try {
      final bodyExists = await controller.evaluateJavascript(
        source: 'document.body !== null;',
      );
      print('Body exists: $bodyExists');

      if (bodyExists == true) {
        // Check if iframe element exists
        final iframeExists = await controller.evaluateJavascript(
          source: 'document.getElementById("game-iframe") !== null;',
        );
        print('Iframe element exists: $iframeExists');

        // Inject JavaScript to notify when iframe loads
        await controller.evaluateJavascript(source: '''
          (function() {
            const iframe = document.getElementById('game-iframe');
            if (iframe) {
              iframe.addEventListener('load', function() {
                console.log('Iframe loaded successfully');
                window.flutter_inappwebview.callHandler('iframeLoaded', {
                  success: true
                });
              });
              
              iframe.addEventListener('error', function() {
                console.log('Iframe load error');
                window.flutter_inappwebview.callHandler('iframeLoaded', {
                  success: false,
                  error: 'Iframe failed to load'
                });
              });
              
              // Fallback: if iframe doesn't fire load event after 5 seconds, consider it loaded
              setTimeout(function() {
                console.log('Iframe load timeout - assuming loaded');
                window.flutter_inappwebview.callHandler('iframeLoaded', {
                  success: true,
                  timeout: true
                });
              }, 5000);
            }
          })();
        ''');

        // Hide loading after a shorter delay for iOS
        final isIOS = !kIsWeb && Platform.isIOS;
        final delay = isIOS ? Duration(seconds: 3) : Duration(seconds: 5);
        
        Future.delayed(delay, () {
          if (mounted && _isLoading) {
            print('Auto-hiding loader after delay');
            setState(() {
              _isLoading = false;
            });
            // Check for content after hiding loader
            _checkForContent();
          }
        });
      }
    } catch (e) {
      print('Error in onLoadStop: $e');
      // Even if there's an error, hide loading after delay
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _onProgressChanged(InAppWebViewController controller, int progress) {
    if (!mounted) return;
    
    setState(() {
      _progress = progress / 100;
    });
    
    // On iOS, when loading HTML data, progress might reach 100% quickly
    // but we still need to wait for the iframe inside to load
    if (progress == 100) {
      // Don't hide immediately - wait for iframe to load
      // The onLoadStop or JavaScript handler will handle hiding
      print('Progress reached 100%, but waiting for iframe to load...');
    }
  }

  bool _onConsoleMessage(
    InAppWebViewController controller,
    ConsoleMessage consoleMessage,
  ) {
    print('Console: ${consoleMessage.message}');
    return true;
  }

  void _onReceivedError(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceError error,
  ) {
    // Don't show error for cache failures or minor resource failures
    // Unity games often have warnings that shouldn't be treated as fatal errors
    final url = request.url.toString();
    final isWasm = url.endsWith('.wasm') || url.contains('.wasm');
    final isCacheError =
        error.description.contains('ERR_CACHE_WRITE_FAILURE') ||
        error.description.contains('ERR_CACHE_MISS') ||
        error.description.contains('cache');

    if (error.type == WebResourceErrorType.HOST_LOOKUP ||
        error.type == WebResourceErrorType.UNKNOWN ||
        isCacheError ||
        isWasm) {
      print('WebView resource error (non-critical): ${error.description}');
      // Don't set error state for these - let the game try to load anyway
      return;
    }

    // Only show error for critical failures that are not WASM or cache related
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
    print('WebView error: ${error.description}');
  }

  // Intercept requests to fix WASM MIME types
  Future<WebResourceResponse?> _shouldInterceptRequest(
    InAppWebViewController controller,
    WebResourceRequest request,
  ) async {
    final url = request.url.toString();

    // Log WASM file requests for debugging
    if (url.endsWith('.wasm')) {
      print('Intercepting WASM file request: $url');
      // The actual WASM handling is done via JavaScript injection in onLoadStop
      // Return null to let the normal request proceed, but with better JS handling
      return null;
    }

    return null; // Let other requests proceed normally
  }

  Future<void> _openInExternalBrowser() async {
    try {
      final uri = Uri.parse(widget.gameUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        // Optionally close this screen after opening in browser
        // Navigator.of(context).pop();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot open this URL in browser'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error opening in external browser: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening browser: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.boxClr,
          title: Text(
            'Exit Game?',
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white,
              fontSize: 18.sp,
            ),
          ),
          content: Text(
            'Are you sure you want to close the game?',
            style: AppTextStyles.regular.copyWith(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
              child: Text(
                'No',
                style: AppTextStyles.medium.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                Navigator.of(context).pop(); // Exit game screen
              },
              child: Text(
                'Yes',
                style: AppTextStyles.medium.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = !kIsWeb && Platform.isIOS;
    
    // On iOS, show loading screen while opening external browser
    if (isIOS) {
      return Scaffold(
        backgroundColor: AppColors.bgClr,
        appBar: AppBar(
          backgroundColor: AppColors.boxClr,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.gameTitle,
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white,
              fontSize: 18.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ThreeDotLoader(
                color: AppColors.primaryColor,
                size: 12.w,
                spacing: 8.w,
              ),
              16.verticalSpace,
              Text(
                'Opening game in browser...',
                style: AppTextStyles.medium.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // For Android and other platforms, show WebView
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgClr,
        appBar: AppBar(
          backgroundColor: AppColors.boxClr,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _showExitDialog(context),
          ),
          title: Text(
            widget.gameTitle,
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white,
              fontSize: 18.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            // External browser button - always available
            IconButton(
              icon: Icon(Icons.open_in_browser, color: Colors.white),
              onPressed: () => _openInExternalBrowser(),
              tooltip: 'Open in Browser',
            ),
          ],
        ),
        body: Stack(
          children: [
            // InAppWebView - Platform-specific loading strategy
            Builder(
              builder: (context) {
                final isIOS = !kIsWeb && Platform.isIOS;
                
                // On iOS, load URL after WebView is created to avoid WebKit networking initialization issues
                if (isIOS) {
                  return InAppWebView(
                    // Load blank page first, then load game URL after WebView initializes
                    initialUrlRequest: URLRequest(
                      url: WebUri('about:blank'),
                    ),
                    initialSettings: _buildWebViewSettings(),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                      _setupJavaScriptHandlers(controller);
                      
                      // Load game URL after WebView is fully initialized (fixes WebKit networking error)
                      Future.delayed(Duration(milliseconds: 500), () {
                        if (mounted && _webViewController != null) {
                          print('iOS: Loading game URL after WebView initialization');
                          _webViewController!.loadUrl(
                            urlRequest: URLRequest(
                              url: WebUri(widget.gameUrl),
                            ),
                          );
                        }
                      });
                    },
                    onLoadStart: _onLoadStart,
                    onLoadStop: _onLoadStopDirect,
                    onConsoleMessage: _onConsoleMessage,
                    onProgressChanged: _onProgressChanged,
                    onReceivedError: _onReceivedError,
                    shouldInterceptRequest: _shouldInterceptRequest,
                    onReceivedHttpError: (controller, request, response) {
                      final url = request.url.toString();
                      
                      // Ignore about:blank errors
                      if (url == 'about:blank') return;
                      
                      final isWasm = url.endsWith('.wasm') || url.contains('.wasm');
                      final statusCode = response.statusCode;
                      
                      if (statusCode != null && statusCode >= 400 && !isWasm) {
                        final isForMainFrame = request.isForMainFrame ?? false;
                        if (isForMainFrame) {
                          setState(() {
                            _isLoading = false;
                            _hasError = true;
                          });
                          print('HTTP error (main frame): $statusCode');
                        }
                      }
                    },
                  );
                }
                
                // On Android, use iframe wrapper for Unity WASM/GPU control
                return InAppWebView(
                  initialData: InAppWebViewInitialData(
                    data: _buildIframeHtml(),
                    baseUrl: WebUri(widget.gameUrl),
                    mimeType: 'text/html',
                    encoding: 'utf-8',
                  ),
                  initialSettings: _buildWebViewSettings(),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    _setupJavaScriptHandlers(controller);
                  },
                  onLoadStart: _onLoadStart,
                  onLoadStop: _onLoadStop,
                  onConsoleMessage: _onConsoleMessage,
                  onProgressChanged: _onProgressChanged,
                  onReceivedError: _onReceivedError,
                  shouldInterceptRequest: _shouldInterceptRequest,
                  onReceivedHttpError: (controller, request, response) {
                    final url = request.url.toString();
                    final isWasm = url.endsWith('.wasm') || url.contains('.wasm');
                    final statusCode = response.statusCode;
                    
                    if (statusCode != null && statusCode >= 400 && !isWasm) {
                      final isForMainFrame = request.isForMainFrame ?? false;
                      if (isForMainFrame) {
                        setState(() {
                          _isLoading = false;
                          _hasError = true;
                        });
                        print('HTTP error (main frame): $statusCode');
                      }
                    }
                  },
                );
              },
            ),

            // Loading Indicator
            if (_isLoading && !_hasError)
              Container(
                color: AppColors.bgClr,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ThreeDotLoader(
                        color: AppColors.primaryColor,
                        size: 12.w,
                        spacing: 8.w,
                      ),
                      16.verticalSpace,
                      Text(
                        'Loading game...',
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14.sp,
                        ),
                      ),
                      if (_progress > 0 && _progress < 1) ...[
                        16.verticalSpace,
                        SizedBox(
                          width: 200.w,
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // External Browser Banner (shown when content not detected)
            if (_showExternalBrowserOption && !_isLoading && !_hasError)
              SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.boxClr,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 24.sp),
                          12.horizontalSpace,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Game may not be loading properly',
                                  style: AppTextStyles.medium.copyWith(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                4.verticalSpace,
                                Text(
                                  'Try opening in external browser for better compatibility',
                                  style: AppTextStyles.regular.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white, size: 20.sp),
                            onPressed: () {
                              setState(() {
                                _showExternalBrowserOption = false;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                      12.verticalSpace,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openInExternalBrowser,
                          icon: Icon(Icons.open_in_browser, size: 18.sp),
                          label: Text(
                            'Open in Browser',
                            style: AppTextStyles.medium.copyWith(
                              color: Colors.black,
                              fontSize: 14.sp,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Error State
            if (_hasError && !_isLoading)
              Container(
                color: AppColors.bgClr,
                padding: EdgeInsets.all(20.w),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 64.sp),
                      16.verticalSpace,
                      Text(
                        'Failed to load game',
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: Colors.white,
                          fontSize: 18.sp,
                        ),
                      ),
                      8.verticalSpace,
                      Text(
                        'Please check your internet connection and try again.',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      24.verticalSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _openInExternalBrowser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                            ),
                            child: Text(
                              'Open in Browser',
                              style: AppTextStyles.medium.copyWith(
                                color: Colors.black,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          16.horizontalSpace,
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _hasError = false;
                              });
                              _webViewController?.reload();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                              side: BorderSide(color: AppColors.primaryColor),
                            ),
                            child: Text(
                              'Retry',
                              style: AppTextStyles.medium.copyWith(
                                color: AppColors.primaryColor,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
