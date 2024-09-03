import 'package:flutter/material.dart';
import 'package:fluttericon/octicons_icons.dart';
import 'package:github/github.dart';
import 'package:url_launcher/url_launcher.dart';

class GithubSummary extends StatefulWidget {
  const GithubSummary({super.key, required this.github});
  final GitHub github;

  @override
  _GithubSummaryState createState() => _GithubSummaryState();
}

class _GithubSummaryState extends State<GithubSummary> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          onDestinationSelected: (index) => {
            setState(() {
              _selectedIndex = index;
            }),
          },
          labelType: NavigationRailLabelType.selected,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Octicons.repo),
              label: Text("Repositories"),
            ),
            NavigationRailDestination(
              icon: Icon(Octicons.issue_opened),
              label: Text("Assgined Issues"),
            ),
            NavigationRailDestination(
              icon: Icon(Octicons.git_pull_request),
              label: Text("Pull Requests"),
            ),
          ],
          selectedIndex: _selectedIndex,
        ),
        const VerticalDivider(
          thickness: 1,
          width: 1,
        ),
        Expanded(
            child: IndexedStack(
          index: _selectedIndex,
          children: [
            RepositoryList(github: widget.github),
            AssignedIssuesList(github: widget.github),
            PullRequestList(github: widget.github),
          ],
        ))
      ],
    );
  }
}

class RepositoryList extends StatefulWidget {
  const RepositoryList({required this.github, super.key});
  final GitHub github;

  @override
  State<RepositoryList> createState() => _RepositoryListState();
}

class _RepositoryListState extends State<RepositoryList> {
  @override
  void initState() {
    super.initState();
    // ここで取得が走るっぽい？（非同期であることはここではわからない？？？）
    _repositories = widget.github.repositories.listRepositories().toList();
  }

  // 取得する・したレポジトリデータ
  late Future<List<Repository>> _repositories;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _repositories,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        var repositories = snapshot.data;
        return ListView.builder(
          itemBuilder: (context, index) {
            var repository = repositories[index];
            return ListTile(
              title:
                  Text('${repository.owner?.login ?? ''}/${repository.name}'),
              subtitle: Text(repository.description),
              onTap: () => _launchUrl(context, repository.htmlUrl),
            );
          },
          itemCount: repositories!.length,
        );
      },
    );
  }
}

class AssignedIssuesList extends StatefulWidget {
  const AssignedIssuesList({required this.github, super.key});

  final GitHub github;
  @override
  State<AssignedIssuesList> createState() => _AssignedIssuesListState();
}

class _AssignedIssuesListState extends State<AssignedIssuesList> {
  @override
  void initState() {
    super.initState();
    _assignedIssues = widget.github.issues.listByUser().toList();
  }

  late Future<List<Issue>> _assignedIssues;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Issue>>(
      future: _assignedIssues,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        var assignedIssues = snapshot.data;
        return ListView.builder(
          itemBuilder: (context, index) {
            var assignedIssue = assignedIssues[index];
            return ListTile(
              title: Text(assignedIssue.title),
              subtitle: Text(
                '${_nameWithOwner(assignedIssue)}'
                'Issue #${assignedIssue.number}'
                'opend by ${assignedIssue.user?.login ?? ''}',
              ),
              onTap: () => _launchUrl(context, assignedIssue.htmlUrl),
            );
          },
          itemCount: assignedIssues!.length,
        );
      },
    );
  }

  String _nameWithOwner(Issue assignedIssue) {
    // ??????????? よくわからん
    final endIndex = assignedIssue.url.lastIndexOf('/issue/');
    return assignedIssue.url.substring(29, endIndex); // 29 is 何
  }
}

class PullRequestList extends StatefulWidget {
  const PullRequestList({required this.github, super.key});
  final GitHub github;
  @override
  State<PullRequestList> createState() => _PullRequestListState();
}

class _PullRequestListState extends State<PullRequestList> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pullRequests = widget.github.pullRequests
        .list(RepositorySlug('flutter', 'flutter'))
        .toList();
  }

  late Future<List<PullRequest>> _pullRequests;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PullRequest>>(
      future: _pullRequests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        var pullRequests = snapshot.data;
        return ListView.builder(
          itemBuilder: (context, index) {
            var pullRequest = pullRequests[index];
            return ListTile(
              title: Text(pullRequest.title ?? ""),
              subtitle: Text(
                'flutter/fluter'
                'PR #${pullRequest.number}'
                'opened by ${pullRequest.user?.login ?? ''}'
                '(${pullRequest.state?.toLowerCase() ?? ''})',
              ),
              onTap: () => _launchUrl(context, pullRequest.htmlUrl ?? ""),
            );
          },
          itemCount: pullRequests!.length,
        );
      },
    );
  }
}

Future<void> _launchUrl(BuildContext context, String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    return showDialog(
        // ここでbuildcontext使うなと言われる
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Navigation error"),
              content: Text("Could not launch $url"),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("close"))
              ],
            ));
  }
}
