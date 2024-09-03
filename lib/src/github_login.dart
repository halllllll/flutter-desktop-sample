import 'dart:io';
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

final _authorizationEndpoint =
    Uri.parse('https://github.com/login/oauth/authorize');
final _tokenEndpoint = Uri.parse('https://github.com/login/oauth/access_token');

class GithubLoginWidget extends StatefulWidget {
  const GithubLoginWidget({
    required this.builder,
    required this.githubClientId,
    required this.githubClientSecret,
    required this.githubScopes,
    super.key,
  });

  final AuthenticationBuilder builder;
  final String githubClientId;
  final String githubClientSecret;
  final List<String> githubScopes;

  @override
  _GithubLoginState createState() => _GithubLoginState();
}

// なんかやってる
typedef AuthenticationBuilder = Widget Function(
    BuildContext context, oauth2.Client client);

class _GithubLoginState extends State<GithubLoginWidget> {
  // なんかローカルサーバーを立てるらしい HttpServerはdart:ioにある
  HttpServer? _redirectServer;
  oauth2.Client? _client;

  @override
  Widget build(BuildContext context) {
    final client = _client;
    if (client != null) {
      return widget.builder(context, client); // ???
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Github Login"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // bind to an ephemerarl port on localhost
            _redirectServer = await HttpServer.bind('localhost', 0);
            // ここでUri.parseに投げているurlがなんなのかは不明（github oauthに設定したものではない）
            var authenticatedHttpClient = await _getOAuth2Client(
                Uri.parse('http://localhost:${_redirectServer!.port}/auth'));
            setState(() {
              _client = authenticatedHttpClient;
            });
          },
          child: const Text("Login to Github"),
        ),
      ),
    );
  }

  Future<oauth2.Client> _getOAuth2Client(Uri redirectUri) async {
    if (widget.githubClientId.isEmpty || widget.githubClientSecret.isEmpty) {
      throw const GithubLoginException(
          'githubClientID and gihtubClientSecret must be not empty'
          'See `lib/github_oauth_credentials.dart` for more detail');
    }
    // 汎用oauthパッケージ強いな
    var grant = oauth2.AuthorizationCodeGrant(
        widget.githubClientId, _authorizationEndpoint, _tokenEndpoint,
        secret: widget.githubClientSecret,
        httpClient: _JsonAcceptingHttpClient());
    var authorizationUrl =
        grant.getAuthorizationUrl(redirectUri, scopes: widget.githubScopes);
    // ログイン画面起動ぽい
    await _redirect(authorizationUrl);

    // これでなんでログイン後のレスポンスを取得できるのか不明
    var responseQueryParameters = await _listen();

    var client =
        await grant.handleAuthorizationResponse(responseQueryParameters);

    return client;
  }

  Future<void> _redirect(Uri authorizationUrl) async {
    // var url = authorizationUrl.toString();
    var url = authorizationUrl;
    if (await canLaunchUrl(url)) {
      // 元のやつだとtoStringにしているが、今だとUrl型じゃないとだめなのかも
      // await launch(urlString);
      // launchはdeprecatedされてて、今はlaunchUrl
      await launchUrl(url);
    } else {
      throw GithubLoginException('Could not launch $url');
    }
  }

  Future<Map<String, String>> _listen() async {
    // ??? よくわからん
    var request = await _redirectServer!.first;
    var params = request.uri.queryParameters;

    request.response.statusCode = 200;
    request.response.headers.set('Content-Type', 'text/plain');
    request.response.writeln('Authenticated! you can close this tab.');
    await request.response.close();
    await _redirectServer!.close();
    _redirectServer = null;
    return params;
  }
}

class _JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}

class GithubLoginException implements Exception {
  const GithubLoginException(this.message);
  final String message;
  @override
  String toString() => message;
}
