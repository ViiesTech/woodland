import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
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
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    // Load game after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGame();
    });
  }

  void _loadGame() {
    if (_webViewController != null) {
      _webViewController!.loadData(
        data: _buildIframeHtml(),
        baseUrl: WebUri(widget.gameUrl),
        mimeType: 'text/html',
        encoding: 'utf-8',
      );
    }
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
            
            // Hide loading after iframe loads
            iframe.addEventListener('load', function() {
                console.log('Unity game iframe loaded');
                
                // Wait for Unity to initialize inside the iframe
                setTimeout(function() {
                    try {
                        // Try to access iframe content (might fail due to CORS)
                        const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                        const hasCanvas = iframeDoc.querySelector('canvas') !== null;
                        const hasUnity = typeof iframe.contentWindow.Unity !== 'undefined' || 
                                       typeof iframe.contentWindow.unityInstance !== 'undefined';
                        
                        console.log('Unity check inside iframe - hasCanvas:', hasCanvas, 'hasUnity:', hasUnity);
                        
                        if (hasCanvas || hasUnity) {
                            console.log('Unity game detected inside iframe');
                            if (loading) {
                                loading.style.display = 'none';
                            }
                        } else {
                            // Even if Unity not detected, hide loading after a delay
                            console.log('Unity not detected but hiding loading anyway');
                            setTimeout(function() {
                                if (loading) {
                                    loading.style.display = 'none';
                                }
                            }, 3000);
                        }
                    } catch (e) {
                        // CORS might block access to iframe content
                        console.log('Cannot access iframe content (CORS):', e);
                        // Hide loading anyway after delay
                        setTimeout(function() {
                            if (loading) {
                                loading.style.display = 'none';
                            }
                        }, 5000);
                    }
                    
                    // Notify parent that iframe loaded
                    try {
                        if (window.parent !== window) {
                            window.parent.postMessage('unity-game-loaded', '*');
                        }
                    } catch (e) {
                        console.log('Cannot post message to parent:', e);
                    }
                }, 2000); // Wait 2 seconds for Unity to start loading
            });
            
            // Handle errors
            iframe.addEventListener('error', function(e) {
                console.error('Iframe load error:', e);
                if (loading) {
                    loading.textContent = 'Failed to load game. Please try again.';
                }
            });
            
            // Listen for messages from Unity
            window.addEventListener('message', function(event) {
                console.log('Received message from Unity:', event.data);
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
    setState(() {
      _isLoading = true;
      _hasError = false;
      _progress = 0;
    });
  }

  Future<void> _onLoadStop(
    InAppWebViewController controller,
    WebUri? url,
  ) async {
    print('Page loaded: ${url?.toString()}');

    // Wait for iframe to load and Unity to initialize
    await Future.delayed(Duration(seconds: 3));

    // Check if iframe loaded
    final iframeLoaded = await controller.evaluateJavascript(
      source: 'document.getElementById("game-iframe") !== null;',
    );
    print('Iframe element exists: $iframeLoaded');

    // Try to check if Unity is loading in iframe (might be blocked by CORS)
    try {
      final iframeSrc = await controller.evaluateJavascript(
        source: 'document.getElementById("game-iframe")?.src || "not found";',
      );
      print('Iframe src: $iframeSrc');
    } catch (e) {
      print('Error checking iframe src: $e');
    }

    // Hide loading after delay - Unity should be loading
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _onProgressChanged(InAppWebViewController controller, int progress) {
    setState(() {
      _progress = progress / 100;
      // Wait a bit before hiding loader to ensure Unity has time to initialize
      if (progress == 100) {
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    });
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
          actions: [],
        ),
        body: Stack(
          children: [
            // InAppWebView - Use iframe wrapper for Unity WASM/GPU control
            InAppWebView(
              initialData: InAppWebViewInitialData(
                data: _buildIframeHtml(),
                baseUrl: WebUri(widget.gameUrl),
                mimeType: 'text/html',
                encoding: 'utf-8',
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                cacheEnabled: true,
                cacheMode: CacheMode.LOAD_DEFAULT,
                clearCache: false,
                mediaPlaybackRequiresUserGesture: false,
                useHybridComposition: true,
                useShouldOverrideUrlLoading: true,
                allowsInlineMediaPlayback: true,
                supportZoom: false,
                transparentBackground: false,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                // Unity WebGL specific settings
                allowsLinkPreview: false,
                disableHorizontalScroll: false,
                disableVerticalScroll: false,
                // Better WASM support
                useOnDownloadStart: false,
                useOnLoadResource: false,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                // Listen for messages from iframe
                controller.addJavaScriptHandler(
                  handlerName: 'unityGameLoaded',
                  callback: (args) {
                    print('Unity game loaded via iframe');
                    setState(() {
                      _isLoading = false;
                    });
                  },
                );
              },
              onLoadStart: _onLoadStart,
              onLoadStop: _onLoadStop,
              onConsoleMessage: (controller, message) {
                // Handle iframe messages
                if (message.message.contains('unity-game-loaded')) {
                  setState(() {
                    _isLoading = false;
                  });
                }
                _onConsoleMessage(controller, message);
              },
              onProgressChanged: _onProgressChanged,
              onReceivedError: _onReceivedError,
              shouldInterceptRequest: _shouldInterceptRequest,
              onReceivedHttpError: (controller, request, response) {
                // Don't treat WASM-related errors as fatal
                final url = request.url.toString();
                final isWasm = url.endsWith('.wasm') || url.contains('.wasm');

                final statusCode = response.statusCode;
                // Only show error for critical HTTP errors that aren't WASM-related
                if (statusCode != null && statusCode >= 400 && !isWasm) {
                  // Check if it's a main frame error
                  final isForMainFrame = request.isForMainFrame ?? false;
                  if (isForMainFrame) {
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                    });
                    print('HTTP error (main frame): $statusCode');
                  } else {
                    print('HTTP error (resource): $statusCode for $url');
                  }
                }
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
                            onPressed: () async {
                              final uri = Uri.parse(widget.gameUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
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
