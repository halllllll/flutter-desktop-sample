import 'package:flutter/material.dart';
import 'src/github_login.dart';
import 'github_oauth_credentials.dart';
import 'package:github/github.dart';
import 'package:window_to_front/window_to_front.dart';
import 'src/github_summary.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Github Client',
      theme: ThemeData(
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Github Client'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return GithubLoginWidget(
        // builderよくわからん、なんでhttpClientがここで使える？
        builder: (context, httpClient) {
          // 追加↓
          WindowToFront.activate();
          // 追加↑
          // return FutureBuilder<CurrentUser>(
          //   future: viewerDetail(httpClient.credentials.accessToken),
          //   builder: (context, snapshot) {
          //     return Scaffold(
          //       appBar: AppBar(
          //         title: Text(title),
          //       ),
          //       body: GithubSummary(
          //           github: _getGithub(httpClient.credentials.accessToken)),
          //     );
          //   },
          // );
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
            ),
            body: GithubSummary(
                github: _getGithub(httpClient.credentials.accessToken)),
          );
        },
        githubClientId: githubClientId,
        githubClientSecret: githubClientSecret,
        githubScopes: githubscopes);
  }
}

Future<CurrentUser> viewerDetail(String accessToken) async {
  final github = GitHub(auth: Authentication.withToken(accessToken));
  return github.users.getCurrentUser();
}

GitHub _getGithub(String accessToken) {
  return GitHub(auth: Authentication.withToken(accessToken));
}
