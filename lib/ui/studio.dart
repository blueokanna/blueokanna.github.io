import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization.dart';
import '../publishing.dart';
import '../companion.dart';
import 'components.dart';
import 'rich_content.dart';

class WritingStudio extends StatefulWidget {
  const WritingStudio({
    super.key,
    required this.publisher,
    required this.language,
  });
  final Publisher publisher;
  final String language;
  @override
  State<WritingStudio> createState() => _WritingStudioState();
}

class _WritingStudioState extends State<WritingStudio> {
  final _token = TextEditingController();
  final _id = TextEditingController(),
      _title = TextEditingController(),
      _summary = TextEditingController(),
      _category = TextEditingController(),
      _body = TextEditingController();
  late String _language = widget.language;
  String? _sha, _remoteKey;
  String _status = '', _draftStatus = '';
  bool _busy = false, _preview = false, _restoring = true;
  Timer? _saveTimer;
  SharedPreferences? _storage;
  static const _draftKey = 'pulselink.writing.draft.v1';
  List<TextEditingController> get _fields => [
    _id,
    _title,
    _summary,
    _category,
    _body,
  ];
  ArticleDraft get _draft => ArticleDraft(
    id: _id.text.trim(),
    language: _language,
    title: _title.text.trim(),
    summary: _summary.text.trim(),
    category: _category.text.trim(),
    body: _body.text,
  );
  @override
  void initState() {
    super.initState();
    for (final field in _fields) {
      field.addListener(_changed);
    }
    _restore();
  }

  Future<void> _restore() async {
    try {
      _storage = await SharedPreferences.getInstance();
      if (!mounted) return;
      final saved = _storage?.getString(_draftKey);
      if (saved != null) {
        final json = jsonDecode(saved) as Map<String, dynamic>;
        final draft = ArticleDraft.fromJson(
          json['draft'] as Map<String, dynamic>,
        );
        if (!languages.containsKey(draft.language)) {
          throw const FormatException();
        }
        _fill(draft);
        _sha = json['sha'] as String?;
        _remoteKey = json['remoteKey'] as String?;
        _draftStatus = '已恢复本机草稿';
      }
    } catch (_) {
      _draftStatus = '本机草稿存储不可用，请及时复制 Markdown。';
    }
    if (mounted) setState(() => _restoring = false);
  }

  void _fill(ArticleDraft draft) {
    _language = draft.language;
    _id.text = draft.id;
    _title.text = draft.title;
    _summary.text = draft.summary;
    _category.text = draft.category;
    _body.text = draft.body;
  }

  void _changed() {
    if (_restoring) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _save);
    if (mounted) setState(() => _draftStatus = '正在编辑');
    if (mounted) CompanionScope.read(context)?.react(CompanionMood.write);
  }

  Future<void> _save() async {
    try {
      if (_storage == null) return;
      final ok = await _storage!.setString(
        _draftKey,
        jsonEncode({
          'draft': _draft.toJson(),
          'sha': _sha,
          'remoteKey': _remoteKey,
        }),
      );
      if (mounted) {
        setState(() => _draftStatus = ok ? '草稿已保存到此浏览器' : '草稿保存失败，请复制正文备份');
        CompanionScope.read(context)
            ?.react(ok ? CompanionMood.saved : CompanionMood.error);
      }
    } catch (_) {
      if (mounted) setState(() => _draftStatus = '草稿保存失败，请复制正文备份');
      if (mounted) CompanionScope.read(context)?.react(CompanionMood.error);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    final actor = CompanionScope.read(context);
    final ticket = actor?.beginWork();
    setState(() {
      _busy = true;
      _status = '';
    });
    try {
      await action();
      if (ticket != null) actor!.completeWork(ticket, CompanionMood.celebrate);
    } on PublishingException catch (error) {
      if (ticket != null) actor!.completeWork(ticket, CompanionMood.error);
      if (mounted) setState(() => _status = error.message);
    } catch (_) {
      if (ticket != null) actor!.completeWork(ticket, CompanionMood.error);
      if (mounted) setState(() => _status = '操作未完成，请检查网络和文章格式后重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _run(() async {
    final token = _token.text.trim();
    _token.clear();
    await widget.publisher.connect(token);
    if (mounted) {
      setState(
        () => _status = widget.publisher.canPublish
            ? '已确认 blueokanna 身份。提交时由 GitHub 校验令牌写权限与分支规则。'
            : '身份已验证；此账户没有站点发布权限。',
      );
    }
  });
  Future<void> _loadRemote() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('读取远程版本？'),
        content: const Text('这会替换当前编辑内容。请先复制尚未合并的 Markdown。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('读取并替换'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    await _run(() async {
      final result = await widget.publisher.read(_language, _id.text.trim());
      if (!mounted) return;
      _restoring = true;
      _fill(result.draft);
      _restoring = false;
      _sha = result.sha;
      _remoteKey = '$_language/${_id.text.trim()}';
      await _save();
      if (mounted) setState(() => _status = '已读取远程版本。发布时将校验这个版本，防止覆盖他人的修改。');
    });
  }

  Future<void> _publish() async {
    try {
      _draft.validate();
    } on PublishingException catch (error) {
      setState(() => _status = error.message);
      CompanionScope.read(context)?.react(CompanionMood.error, priority: 3);
      return;
    }
    final snapshot = _draft;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发布到 GitHub？'),
        content: Text(
          '《${snapshot.title}》\ncontent/posts/${snapshot.language}/${snapshot.id}.md\n\n将提交到 main 分支并触发 Pages 构建，文章会公开。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认发布'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    await _run(() async {
      final key = '${snapshot.language}/${snapshot.id}';
      final sha = await widget.publisher.publish(
        snapshot,
        sha: _remoteKey == key ? _sha : null,
      );
      if (!mounted) return;
      _sha = sha;
      _remoteKey = key;
      await _save();
      if (mounted) {
        setState(
          () => _status = '文章已提交到 GitHub。请在 Actions 查看构建结果；构建部署成功后刷新站点即可阅读。',
        );
      }
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // Snapshot before disposing controllers; never save the credential.
    if (!_restoring && _storage != null) {
      unawaited(
        _storage!
            .setString(
              _draftKey,
              jsonEncode({
                'draft': _draft.toJson(),
                'sha': _sha,
                'remoteKey': _remoteKey,
              }),
            )
            .catchError((_) => false),
      );
    }
    for (final field in [..._fields, _token]) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.publisher,
    builder: (context, _) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.sizeOf(context).width < 600 ? 24 : 144,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Writing studio',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              const Text('把想清楚的事写下来。Markdown 预览、浏览器草稿、GitHub 版本记录。'),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.publisher.login == null
                            ? 'GitHub 令牌登录'
                            : 'GitHub · ${widget.publisher.login}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '仅 blueokanna 可发布。创建 fine-grained token，只选择 blueokanna.github.io 仓库，授予 Contents: Read and write 并设置有效期。令牌仅在本次会话内使用，刷新或退出后清除。访客评论请使用文章下方的 GitHub 登录。',
                      ),
                      const ExternalLink(
                        url: 'https://github.com/settings/personal-access-tokens/new',
                        label: '在 GitHub 创建限权令牌 ↗',
                      ),
                      if (widget.publisher.login == null) ...[
                        TextField(
                          controller: _token,
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          enabled: !_busy,
                          maxLength: 255,
                          decoration: const InputDecoration(
                            labelText: 'Fine-grained token',
                            hintText: 'github_pat_…',
                          ),
                          onSubmitted: (_) {
                            if (!_busy) _connect();
                          },
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _connect,
                            icon: const Icon(Icons.login),
                            label: const Text('验证 GitHub 身份'),
                          ),
                        ),
                      ] else
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _busy
                                ? null
                                : widget.publisher.disconnect,
                            icon: const Icon(Icons.logout),
                            label: const Text('退出并清除令牌'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.publisher.canPublish)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => context.go('/${widget.language}/friends'),
                    icon: const Icon(Icons.link),
                    label: const Text('管理友链'),
                  ),
                ),
              if (_busy) const LinearProgressIndicator(),
              if (_status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: SelectableText(_status),
                  ),
                ),
              if (_restoring)
                const LinearProgressIndicator()
              else ...[
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownMenu<String>(
                      initialSelection: _language,
                      label: const Text('文章语言'),
                      enabled: !_busy,
                      dropdownMenuEntries: languages.entries
                          .map(
                            (e) =>
                                DropdownMenuEntry(value: e.key, label: e.value),
                          )
                          .toList(),
                      onSelected: (value) {
                        if (value != null) {
                          setState(() => _language = value);
                          _changed();
                        }
                      },
                    ),
                    Text(_draftStatus),
                  ],
                ),
                const SizedBox(height: 16),
                for (final entry in [
                  (_id, '文章 ID（URL）', 64),
                  (_title, '标题', 160),
                  (_category, '分类', 40),
                  (_summary, '摘要', 600),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: entry.$1,
                      enabled: !_busy,
                      maxLength: entry.$3,
                      decoration: InputDecoration(
                        labelText: entry.$2,
                        border: const OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: entry.$1 == _summary ? 4 : 2,
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Markdown'),
                      selected: !_preview,
                      onSelected: (_) => setState(() => _preview = false),
                    ),
                    ChoiceChip(
                      label: const Text('阅读预览'),
                      selected: _preview,
                      onSelected: (_) => setState(() => _preview = true),
                    ),
                    TextButton(
                      onPressed: _busy || !widget.publisher.canPublish
                          ? null
                          : _loadRemote,
                      child: const Text('读取远程版本'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_preview)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: RichContent(data: _body.text),
                    ),
                  )
                else
                  TextField(
                    controller: _body,
                    enabled: !_busy,
                    minLines: 18,
                    maxLines: null,
                    maxLength: 131072,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      height: 1.65,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Markdown 正文',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy || !widget.publisher.canPublish
                          ? null
                          : _publish,
                      icon: const Icon(Icons.publish),
                      label: const Text('发布文章'),
                    ),
                    const ExternalLink(
                      url: 'https://github.com/blueokanna/blueokanna.github.io/actions',
                      label: '查看构建状态 ↗',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('草稿只保存在当前浏览器，不会自动上传。请勿在正文中写入密钥。发布只更新选定语言，不会自动编造翻译。'),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    ),
  );
}
