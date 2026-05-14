import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/api_log_model.dart';

class ApiLogDetailScreen extends StatefulWidget {
  final ApiLogModel log;

  const ApiLogDetailScreen({super.key, required this.log});

  @override
  State<ApiLogDetailScreen> createState() => _ApiLogDetailScreenState();
}

class _ApiLogDetailScreenState extends State<ApiLogDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
    });
  }

  void _copyToClipboard(BuildContext context) {
    final log = widget.log;
    final text = '''
URL: ${log.url}
Method: ${log.method}
Status: ${log.statusCode}
Duration: ${log.formattedDuration}

[Request Headers]
${log.formattedRequestHeaders}

[Request Body]
${log.formattedRequestBody}

[Response Headers]
${log.formattedResponseHeaders}

[Response Body]
${log.formattedResponseBody}
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final log = widget.log;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 2,
          leading: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _clearSearch,
                )
              : null,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search in log details...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => _searchController.clear(),
                            tooltip: 'Clear text',
                          )
                        : null,
                  ),
                )
              : const Text(
                  'Log Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
          actions: [
            if (!_isSearching) ...[
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Search in details',
                onPressed: _startSearch,
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copyToClipboard(context),
                tooltip: 'Copy all to clipboard',
              ),
            ],
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kTextTabBarHeight + 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Amber search banner
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _isSearching && _searchQuery.isNotEmpty
                      ? _SearchBanner(query: _searchQuery)
                      : const SizedBox.shrink(),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Request'),
                    Tab(text: 'Response'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestTab(log),
            _buildResponseTab(log),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTab(ApiLogModel log) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(
            title: 'Overview',
            children: [
              _InfoRow(label: 'URL', value: log.url, searchQuery: _searchQuery),
              _InfoRow(
                  label: 'Method',
                  value: log.method,
                  searchQuery: _searchQuery),
              _InfoRow(
                  label: 'Time',
                  value: log.formattedTime,
                  searchQuery: _searchQuery),
              _InfoRow(
                label: 'Date',
                value:
                    '${log.timestamp.day.toString().padLeft(2, '0')}/${log.timestamp.month.toString().padLeft(2, '0')}/${log.timestamp.year}',
                searchQuery: _searchQuery,
              ),
              _InfoRow(
                  label: 'Duration',
                  value: log.formattedDuration,
                  searchQuery: _searchQuery),
              if (log.screenName != null)
                _InfoRow(
                    label: 'Screen',
                    value: log.screenName!,
                    searchQuery: _searchQuery),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Headers',
            children: [
              _CodeBlock(
                  text: log.formattedRequestHeaders, searchQuery: _searchQuery),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Body',
            children: [
              _CodeBlock(
                  text: log.formattedRequestBody, searchQuery: _searchQuery),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTab(ApiLogModel log) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(
            title: 'Overview',
            children: [
              _InfoRow(
                label: 'Status Code',
                value: log.statusCode?.toString() ?? '---',
                valueColor: log.isError ? Colors.red : Colors.green,
                searchQuery: _searchQuery,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Headers',
            children: [
              _CodeBlock(
                  text: log.formattedResponseHeaders,
                  searchQuery: _searchQuery),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Body',
            children: [
              _CodeBlock(
                  text: log.formattedResponseBody, searchQuery: _searchQuery),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Banner
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBanner extends StatelessWidget {
  final String query;
  const _SearchBanner({required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8E1),
        border: Border(
          bottom: BorderSide(color: Color(0xFFFFD54F), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.highlight_rounded,
              size: 14, color: Color(0xFF795548)),
          const SizedBox(width: 6),
          Text(
            'Highlighting: ',
            style: TextStyle(fontSize: 12, color: Colors.brown.shade600),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '"$query"',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colorScheme.primary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Divider(height: 1, thickness: 0.8, color: colorScheme.outlineVariant),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String searchQuery;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.searchQuery,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: _HighlightedText(
              text: value,
              query: searchQuery,
              baseStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Code Block
// ─────────────────────────────────────────────────────────────────────────────

class _CodeBlock extends StatelessWidget {
  final String text;
  final String searchQuery;

  const _CodeBlock({required this.text, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.6),
          width: 0.8,
        ),
      ),
      child: _HighlightedText(
        text: text,
        query: searchQuery,
        baseStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: colorScheme.onSurface, // always readable
          height: 1.55,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Highlighted Text — amber marker with forced dark text for readability
// ─────────────────────────────────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
      );
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: baseStyle,
          ));
        }
        break;
      }

      // Non-matching chunk before this match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: baseStyle,
        ));
      }

      // Highlighted match — amber background, always-readable dark text
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: baseStyle.copyWith(
            backgroundColor: const Color(0xFFFFD54F), // vivid amber marker
            color: const Color(0xFF1A1A1A), // near-black, always readable
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
