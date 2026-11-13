import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../content.dart';
import '../friends_service.dart';
import '../publishing.dart';
import 'components.dart';

class FriendsView extends StatefulWidget {
  const FriendsView({
    super.key,
    required this.language,
    this.publisher,
    this.service,
  });
  final String language;
  final Publisher? publisher;
  final FriendsService? service;
  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> with WidgetsBindingObserver {
  late final _service = widget.service ?? FriendsService();
  late List<FriendLink> _links = _service.snapshot;
  String? _error;
  bool _loading = false;
  Timer? _refresh;
  bool get _zh => widget.language.startsWith('zh');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startRefresh();
  }

  void _startRefresh() {
    _refresh?.cancel();
    _refresh = Timer.periodic(const Duration(minutes: 1), (_) => _load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _refresh?.cancel();
    if (state == AppLifecycleState.resumed) {
      _load();
      _startRefresh();
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final links = await _service.load();
      if (mounted) {
        setState(() {
          _links = links;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _zh
              ? '暂时无法同步 GitHub，当前保留上次可用的友链。'
              : 'GitHub is unavailable. Showing the last available links.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _manage() async {
    final publisher = widget.publisher;
    if (publisher == null || !publisher.canPublish) {
      context.go('/${widget.language}/studio');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => FriendEditor(
        publisher: publisher,
        onSaved: (links, sha) {
          _service.acceptSaved(links, sha);
          if (mounted) {
            setState(() {
              _links = links;
              _error = null;
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.sync),
            label: Text(_zh ? '刷新友链' : 'Refresh'),
          ),
          TextButton.icon(
            onPressed: _manage,
            icon: const Icon(Icons.manage_accounts_outlined),
            label: Text(
              _zh ? '站主管理 · GitHub 验证' : 'Owner · GitHub verification',
            ),
          ),
        ],
      ),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 24),
      ResponsiveColumns(
        minWidth: 320,
        children: _links
            .map(
              (friend) => Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(child: Text(friend.name.characters.first)),
                      const SizedBox(height: 20),
                      Text(
                        friend.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _zh || friend.descEn.isEmpty
                            ? friend.desc
                            : friend.descEn,
                      ),
                      const SizedBox(height: 20),
                      ExternalLink(
                        url: friend.url,
                        label: '${Uri.parse(friend.url).host} ↗',
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class FriendEditor extends StatefulWidget {
  const FriendEditor({
    super.key,
    required this.publisher,
    required this.onSaved,
  });
  final Publisher publisher;
  final void Function(List<FriendLink>, String sha) onSaved;
  @override
  State<FriendEditor> createState() => _FriendEditorState();
}

class _FriendEditorState extends State<FriendEditor> {
  final _name = TextEditingController(),
      _url = TextEditingController(),
      _desc = TextEditingController(),
      _en = TextEditingController();
  List<FriendLink> _links = [];
  String? _sha;
  String _status = '';
  bool _busy = false, _ready = false, _dirty = false;
  int? _editing;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('重新读取远程版本？'),
          content: const Text('这会替换尚未保存的列表。发生版本冲突时，请先复制当前列表，再读取远程版本合并。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('重新读取'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final remote = await widget.publisher.readFriends();
      if (mounted) {
        setState(() {
          _links = List.of(remote.links);
          _sha = remote.sha;
          _ready = true;
          _dirty = false;
          _status = '已读取远程版本。修改后保存即可同步到访客页面。';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clear() {
    for (final field in [_name, _url, _desc, _en]) {
      field.clear();
    }
    _editing = null;
  }

  void _add() {
    try {
      final link = FriendLink(
        name: _name.text.trim(),
        url: _url.text.trim(),
        desc: _desc.text.trim(),
        descEn: _en.text.trim(),
      );
      final next = List<FriendLink>.of(_links);
      if (_editing == null) {
        next.add(link);
      } else {
        next[_editing!] = link;
      }
      FriendLink.encode(next);
      setState(() {
        _links = next;
        _dirty = true;
        _clear();
        _status = '修改尚未保存。';
      });
    } catch (e) {
      setState(() => _status = '$e');
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final sha = await widget.publisher.publishFriends(_links, sha: _sha);
      if (!mounted) return;
      setState(() {
        _sha = sha;
        _dirty = false;
        _status = '已保存到 GitHub。其他访客会在下一次同步时看到更新。';
      });
      widget.onSaved(List.unmodifiable(_links), sha);
    } catch (e) {
      if (mounted) setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('移除 ${_links[index].name}？'),
        content: const Text('保存后才会更新线上友链。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _links.removeAt(index);
        _dirty = true;
        _clear();
      });
    }
  }

  @override
  void dispose() {
    for (final field in [_name, _url, _desc, _en]) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.publisher,
    builder: (context, _) {
      final enabled = !_busy && _ready && widget.publisher.canPublish;
      return AlertDialog(
        title: const Text('友链管理'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_busy) const LinearProgressIndicator(),
                Text(_status, semanticsLabel: _status),
                const SizedBox(height: 16),
                for (var i = 0; i < _links.length; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_links[i].name),
                    subtitle: Text(_links[i].url),
                    onTap: !enabled
                        ? null
                        : () => setState(() {
                            _editing = i;
                            _name.text = _links[i].name;
                            _url.text = _links[i].url;
                            _desc.text = _links[i].desc;
                            _en.text = _links[i].descEn;
                          }),
                    trailing: IconButton(
                      tooltip: '移除友链',
                      onPressed: !enabled ? null : () => _remove(i),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                const Divider(),
                for (final entry in [
                  (_name, '名称'),
                  (_url, 'HTTPS 网址'),
                  (_desc, '中文简介'),
                  (_en, '英文简介（可选）'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: entry.$1,
                      enabled: enabled,
                      maxLength: entry.$1 == _url
                          ? 2048
                          : entry.$1 == _name
                          ? 80
                          : 400,
                      decoration: InputDecoration(
                        labelText: entry.$2,
                        counterText: '',
                      ),
                    ),
                  ),
                OutlinedButton(
                  onPressed: enabled ? _add : null,
                  child: Text(_editing == null ? '加入列表' : '应用修改'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: !_ready
                ? null
                : () async {
                    try {
                      await Clipboard.setData(
                        ClipboardData(text: FriendLink.encode(_links)),
                      );
                      if (mounted) setState(() => _status = '列表已复制，可用来合并版本冲突。');
                    } catch (_) {
                      if (mounted) setState(() => _status = '剪贴板不可用，请保留当前窗口。');
                    }
                  },
            child: const Text('复制列表'),
          ),
          TextButton(
            onPressed: _busy ? null : _load,
            child: const Text('重新读取'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: enabled && _dirty ? _save : null,
            child: const Text('保存到 GitHub'),
          ),
        ],
      );
    },
  );
}
