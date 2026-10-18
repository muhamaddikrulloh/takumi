import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:task_track/core/providers/connectivity_provider.dart';
import 'package:task_track/core/providers/core_providers.dart';
import 'package:task_track/core/services/local_data_service.dart';

/// Avatar offline-safe: menyimpan byte foto di SharedPreferences (cache lokal)
/// dan menampilkannya saat offline. Fallback ke ikon bila belum pernah dimuat.
class CachedAvatar extends ConsumerStatefulWidget {
  final String? url;
  final double size;
  final Color fallbackColor;

  const CachedAvatar({
    super.key,
    required this.url,
    required this.size,
    required this.fallbackColor,
  });

  @override
  ConsumerState<CachedAvatar> createState() => _CachedAvatarState();
}

class _CachedAvatarState extends ConsumerState<CachedAvatar> {
  static const _maxImageBytes = 5 * 1024 * 1024;

  Uint8List? _bytes;
  bool _loading = true;
  bool _listening = false;
  int _generation = 0;
  HttpClient? _client;

  @override
  void initState() {
    super.initState();
    _loadCached();
    _fetch();
  }

  @override
  void didUpdateWidget(CachedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _generation++;
      _client?.close(force: true);
      _client = null;
      _bytes = null;
      _loading = true;
      _loadCached();
      _fetch();
    }
  }

  @override
  void dispose() {
    _generation++;
    _client?.close(force: true);
    super.dispose();
  }

  Future<void> _loadCached() async {
    final url = widget.url;
    if (url == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final generation = _generation;
    final prefs = ref.read(sharedPreferencesProvider);
    final cacheKey = LocalDataService.accountPhotoCacheKey(url);
    final cached = prefs.getString(cacheKey);
    if (!mounted || generation != _generation || widget.url != url) return;
    if (cached == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final bytes = base64Decode(cached);
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } on FormatException {
      await prefs.remove(cacheKey);
      if (mounted && generation == _generation && widget.url == url) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _fetch() async {
    final url = widget.url;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;

    final generation = _generation;
    final prefs = ref.read(sharedPreferencesProvider);
    final cacheKey = LocalDataService.accountPhotoCacheKey(url);
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    _client?.close(force: true);
    _client = client;
    try {
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'image/*');
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != HttpStatus.ok) return;
      if (response.headers.contentType?.primaryType != 'image') return;
      if (response.contentLength > _maxImageBytes) return;

      final sink = BytesBuilder(copy: false);
      var byteCount = 0;
      await for (final chunk in response) {
        byteCount += chunk.length;
        if (byteCount > _maxImageBytes) return;
        sink.add(chunk);
      }
      final bytes = sink.takeBytes();
      if (bytes.isEmpty ||
          !mounted ||
          generation != _generation ||
          widget.url != url) {
        return;
      }

      setState(() => _bytes = bytes);
      unawaited(prefs.setString(cacheKey, base64Encode(bytes)));
    } catch (_) {
      // Offline / gagal jaringan: pakai cache bila ada, ikon bila tidak.
    } finally {
      client.close();
      if (identical(_client, client)) _client = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_listening) {
      _listening = true;
      ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
        final online = next.valueOrNull ?? false;
        final wasOnline = prev?.valueOrNull ?? false;
        if (online && !wasOnline && _bytes == null) _fetch();
      });
    }

    final url = widget.url;
    if (url == null) {
      return _Fallback(size: widget.size, color: widget.fallbackColor);
    }

    final child = _bytes != null
        ? Image.memory(
            _bytes!,
            width: widget.size,
            height: widget.size,
            gaplessPlayback: true,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _Fallback(size: widget.size, color: widget.fallbackColor),
          )
        : _loading
        ? const SizedBox.shrink()
        : _Fallback(size: widget.size, color: widget.fallbackColor);

    return ClipOval(
      child: SizedBox(width: widget.size, height: widget.size, child: child),
    );
  }
}

class _Fallback extends StatelessWidget {
  final double size;
  final Color color;

  const _Fallback({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.transparent,
      child: Icon(
        PhosphorIconsRegular.userCircle,
        size: size * 0.5,
        color: color,
      ),
    );
  }
}
