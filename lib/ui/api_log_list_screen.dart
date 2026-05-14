import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../models/api_log_model.dart';
import '../services/api_log_service.dart';
import 'api_log_detail_screen.dart';

class ApiLogListScreen extends StatefulWidget {
  final String sessionId;
  final String sessionName;

  const ApiLogListScreen({
    super.key,
    required this.sessionId,
    required this.sessionName,
  });

  @override
  State<ApiLogListScreen> createState() => _ApiLogListScreenState();
}

class _ApiLogListScreenState extends State<ApiLogListScreen> {
  late bool _isCurrentSession;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  late String _sessionName;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _isCurrentSession = widget.sessionId == ApiLogService().currentSessionId;
    _sessionName = widget.sessionName;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ApiLogModel> _filterLogs(List<ApiLogModel> logs) {
    if (_searchQuery.trim().isEmpty) return logs;
    final query = _searchQuery.trim().toLowerCase();
    return logs.where((log) {
      return log.url.toLowerCase().contains(query) ||
          log.method.toLowerCase().contains(query) ||
          (log.statusCode?.toString().contains(query) ?? false) ||
          (log.screenName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
    });
  }

  String _buildLogText(List<ApiLogModel> logs) {
    final buf = StringBuffer();
    final now = DateTime.now().toLocal();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    int hour = now.hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = now.minute.toString().padLeft(2, '0');
    final formattedNow = '$day-$month-$year $hourStr:$minuteStr $amPm';

    final smtpConfig = ApiLogService().smtpConfig;

    buf.writeln('═══════════════════════════════════════════════════════════');
    buf.writeln('  API LOGS EXPORT');
    buf.writeln('  Session     : ${widget.sessionName}');
    buf.writeln('  Session ID  : ${widget.sessionId}');
    if (smtpConfig != null) {
      buf.writeln('  From        : ${smtpConfig.fromEmail}');
    }
    buf.writeln('  Exported    : $formattedNow');
    buf.writeln('  Total       : ${logs.length} request(s)');
    buf.writeln('═══════════════════════════════════════════════════════════');
    buf.writeln();

    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      buf.writeln(
          '───────────────────────────────────────────────────────────');
      buf.writeln(
          '#${i + 1}  [${log.method.toUpperCase()}]  ${log.statusCode ?? "---"}  ${log.isError ? "ERROR" : "OK"}');
      buf.writeln('URL      : ${log.url}');
      buf.writeln('Time     : ${log.formattedDateTime}');
      buf.writeln('Duration : ${log.formattedDuration}');
      if (log.screenName != null) {
        buf.writeln('Screen   : ${log.screenName}');
      }
      buf.writeln();
      buf.writeln('-- Request Headers --');
      buf.writeln(log.formattedRequestHeaders);
      buf.writeln();
      buf.writeln('-- Request Body --');
      buf.writeln(log.formattedRequestBody);
      buf.writeln();
      buf.writeln('-- Response Headers --');
      buf.writeln(log.formattedResponseHeaders);
      buf.writeln();
      buf.writeln('-- Response Body --');
      buf.writeln(log.formattedResponseBody);
      buf.writeln();
    }

    buf.writeln('═══════════════════════════════════════════════════════════');
    buf.writeln('  END OF EXPORT');
    buf.writeln('═══════════════════════════════════════════════════════════');
    return buf.toString();
  }

  Future<void> _shareLogs(List<ApiLogModel> logs) async {
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No logs to share.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final text = _buildLogText(logs);

    try {
      // Save to a temporary file for sharing
      final dir = await getTemporaryDirectory();
      final now = DateTime.now().toLocal();
      final day = now.day.toString().padLeft(2, '0');
      final month = now.month.toString().padLeft(2, '0');
      final timestamp =
          '$month$day${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      final cleanSessionName = _sessionName
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .replaceAll(' ', '_');
      final fileName = 'api_report_${cleanSessionName}_$timestamp.txt';
      final file = File(p.join(dir.path, fileName));
      await file.writeAsString(text, flush: true);

      // Share the file
      if (!mounted) return;

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'API Logs Export - Session $_sessionName',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share logs: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editSessionName() async {
    final controller = TextEditingController(text: _sessionName);
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Edit Session Name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Session Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Name cannot be empty'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName != _sessionName) {
      await ApiLogService().updateSessionName(widget.sessionId, newName);
      if (mounted) {
        setState(() {
          _sessionName = newName;
        });
      }
    }
  }

  Future<void> _confirmDeleteSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Session?'),
        content: Text(
            'Are you sure you want to permanently delete the session "$_sessionName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiLogService().clearSession(widget.sessionId);
      if (mounted) Navigator.pop(context);
    }
  }

  /// Shows an email form dialog and then sends the session report via SMTP.
  Future<void> _showEmailForm() async {
    final smtpConfig = ApiLogService().smtpConfig;

    if (smtpConfig == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'SMTP is not configured. please initialize ApiDebugger with SmtpConfig.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final formKey = GlobalKey<FormState>();
    final toController = TextEditingController();
    final senderController =
        TextEditingController(text: ApiLogService().lastSenderName);
    final remarksController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isSending,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.email_outlined,
                  color: Theme.of(ctx).colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              const Text('Email Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _isSending
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Sending report...'),
                    ],
                  )
                : Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Default Recipients Chips ────────────────────────
                        if (smtpConfig.defaultRecipients.isNotEmpty) ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Quick Select:',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: smtpConfig.defaultRecipients.map((r) {
                                return ActionChip(
                                  label: Text(r.name),
                                  labelStyle: const TextStyle(fontSize: 12),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onPressed: () {
                                    toController.text = r.email;
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── To (email) ──────────────────────────────────────
                        TextFormField(
                          controller: toController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'To (Email Address) *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.alternate_email, size: 18),
                            isDense: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email address is required';
                            }
                            final emailRegex = RegExp(
                              r'^[\w.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+$',
                            );
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Sender Name ──────────────────────────────────────
                        TextFormField(
                          controller: senderController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Sender Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline, size: 18),
                            isDense: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Sender name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Remarks ─────────────────────────────────────────
                        TextFormField(
                          controller: remarksController,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Remarks (optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Icon(Icons.notes_outlined, size: 18),
                            ),
                            isDense: true,
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          actions: _isSending
              ? null
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Send'),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => _isSending = true);
                        try {
                          await _buildAndSendReport(
                            toEmail: toController.text.trim(),
                            senderName: senderController.text.trim(),
                            remarks: remarksController.text.trim(),
                          );
                          // Persist sender name for next time
                          await ApiLogService()
                              .setLastSenderName(senderController.text.trim());

                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setDialogState(() => _isSending = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          _isSending = false;
                        }
                      }
                    },
                  ),
                ],
        ),
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report sent successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Generates the report and sends it using direct SMTP.
  Future<void> _buildAndSendReport({
    required String toEmail,
    required String senderName,
    required String remarks,
  }) async {
    final smtpConfig = ApiLogService().smtpConfig;
    if (smtpConfig == null) throw Exception('SMTP config missing');

    final logs = await ApiLogService().getLogsForSession(widget.sessionId);

    final now = DateTime.now().toLocal();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    int hour = now.hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = now.minute.toString().padLeft(2, '0');
    final formattedNow = '$day-$month-$year $hourStr:$minuteStr $amPm';

    final buffer = StringBuffer();
    buffer
        .writeln('═══════════════════════════════════════════════════════════');
    buffer.writeln('  API DEBUG REPORT');
    buffer
        .writeln('═══════════════════════════════════════════════════════════');
    buffer.writeln('Generated  : $formattedNow');
    buffer.writeln('To         : $toEmail');
    buffer.writeln('From Email : ${smtpConfig.fromEmail}');
    buffer.writeln('Sender Name: $senderName');
    if (remarks.isNotEmpty) {
      buffer.writeln('Remarks    : $remarks');
    }
    buffer
        .writeln('──────────────────────────────────────────────────────────');
    buffer.writeln('Session    : $_sessionName');
    buffer.writeln('Session ID : ${widget.sessionId}');

    final sessions = await ApiLogService().getSessions();
    final session = sessions.firstWhere((s) => s.id == widget.sessionId);

    buffer.writeln('Started    : ${ApiLogModel(
      id: '',
      sessionId: '',
      method: '',
      url: '',
      timestamp: session.startTime,
      duration: Duration.zero,
    ).formattedDateTime}');
    buffer.writeln('Total APIs : ${logs.length}');
    buffer.writeln();

    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      buffer.writeln(
          '──────────────────────────────────────────────────────────');
      buffer.writeln(
          '#${i + 1}  [${log.method.toUpperCase()}]  ${log.statusCode ?? '---'}  ${log.isError ? 'ERROR' : 'OK'}');
      buffer.writeln('URL      : ${log.url}');
      buffer.writeln('Time     : ${log.formattedDateTime}');
      buffer.writeln('Duration : ${log.formattedDuration}');
      if (log.screenName != null) {
        buffer.writeln('Screen   : ${log.screenName}');
      }
      buffer.writeln();
      buffer.writeln('-- Request Body --');
      buffer.writeln(log.formattedRequestBody);
      buffer.writeln();
      buffer.writeln('-- Response Body --');
      buffer.writeln(log.formattedResponseBody);
      buffer.writeln();
    }

    buffer
        .writeln('═══════════════════════════════════════════════════════════');
    buffer.writeln('  END OF REPORT');
    buffer
        .writeln('═══════════════════════════════════════════════════════════');

    final smtpServer = SmtpServer(
      smtpConfig.server,
      port: smtpConfig.port,
      username: smtpConfig.username,
      password: smtpConfig.password,
      ssl: smtpConfig.secure,
    );

    final timestamp =
        '$month$day${now.year}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final cleanSessionName =
        _sessionName.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
    final reportFileName = 'api_report_${cleanSessionName}_$timestamp.txt';

    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, reportFileName));
    await file.writeAsString(buffer.toString());

    final failedCount = logs.where((log) => log.isError).length;
    final successCount = logs.length - failedCount;

    final message = Message()
      ..from = Address(smtpConfig.fromEmail, senderName)
      ..recipients.add(toEmail)
      ..subject = 'API Debug Report – $_sessionName'
      ..html = '''
<div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
  <div style="background-color: #2196F3; color: white; padding: 20px; text-align: center;">
    <h1 style="margin: 0; font-size: 24px;">API Debug Report</h1>
    <p style="margin: 5px 0 0 0; opacity: 0.8;">Session: $_sessionName</p>
  </div>

  <div style="padding: 20px; color: #333; line-height: 1.6;">
    <h2 style="border-bottom: 2px solid #2196F3; padding-bottom: 8px; font-size: 18px; color: #2196F3;">Session Overview</h2>
    <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
      <tr>
        <td style="padding: 8px 0; font-weight: bold; width: 120px;">Session ID:</td>
        <td style="padding: 8px 0;">${widget.sessionId}</td>
      </tr>
      <tr>
        <td style="padding: 8px 0; font-weight: bold;">Started:</td>
        <td style="padding: 8px 0;">${ApiLogModel(
        id: '',
        sessionId: '',
        method: '',
        url: '',
        timestamp: session.startTime,
        duration: Duration.zero,
      ).formattedDateTime}</td>
      </tr>
      <tr>
        <td style="padding: 8px 0; font-weight: bold;">Generated:</td>
        <td style="padding: 8px 0;">$formattedNow</td>
      </tr>
    </table>

    <h2 style="border-bottom: 2px solid #2196F3; padding-bottom: 8px; font-size: 18px; color: #2196F3;">Request Summary</h2>
    <div style="display: flex; gap: 20px; margin-bottom: 20px;">
      <div style="background-color: #f5f5f5; padding: 15px; border-radius: 6px; flex: 1; text-align: center;">
        <div style="font-size: 20px; font-weight: bold; color: #333;">${logs.length}</div>
        <div style="font-size: 12px; color: #666;">Total Requests</div>
      </div>
      <div style="background-color: #e8f5e9; padding: 15px; border-radius: 6px; flex: 1; text-align: center;">
        <div style="font-size: 20px; font-weight: bold; color: #4CAF50;">$successCount</div>
        <div style="font-size: 12px; color: #666;">Successful</div>
      </div>
      <div style="background-color: #ffebee; padding: 15px; border-radius: 6px; flex: 1; text-align: center;">
        <div style="font-size: 20px; font-weight: bold; color: #F44336;">$failedCount</div>
        <div style="font-size: 12px; color: #666;">Failed</div>
      </div>
    </div>

    ${remarks.isNotEmpty ? '''
    <h2 style="border-bottom: 2px solid #2196F3; padding-bottom: 8px; font-size: 18px; color: #2196F3;">Sender Remarks</h2>
    <p style="background-color: #fff9c4; padding: 10px; border-left: 4px solid #fbc02d; font-style: italic; margin-bottom: 20px;">
      "$remarks"
    </p>
    ''' : ''}

    <div style="background-color: #e3f2fd; padding: 15px; border-radius: 6px; border: 1px dashed #2196F3;">
      <p style="margin: 0; font-size: 14px; text-align: center;">
        <strong>Full Logs Attached:</strong> Detailed technical logs are available in the attached <code>.txt</code> file.
      </p>
    </div>
  </div>

  <div style="background-color: #f5f5f5; color: #999; padding: 15px; text-align: center; font-size: 11px;">
    Sent from <strong>ApiSequenceDebugger</strong> • Generated by $senderName
  </div>
</div>
'''
      ..text = 'API Debug Report – $_sessionName\n\n'
          'Sent by $senderName\n'
          '${remarks.isNotEmpty ? 'Remarks: $remarks\n\n' : ''}'
          'Check the attached .txt file for full log details.'
      ..attachments.add(
        FileAttachment(file)
          ..fileName = reportFileName
          ..contentType = 'text/plain',
      );

    await send(message, smtpServer);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: _isSearching ? 0 : null,
        title: _isSearching
            ? Container(
                height: 40,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search URL, method, status...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    icon: Icon(Icons.search,
                        size: 18, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Logs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _sessionName,
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 2,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Clear search',
              onPressed: _clearSearch,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search logs',
              onPressed: _startSearch,
            ),
            IconButton(
              icon: const Icon(Icons.email_outlined),
              tooltip: 'Email Report',
              onPressed: _showEmailForm,
            ),
            _ShareLogsButton(
              sessionId: widget.sessionId,
              isCurrentSession: _isCurrentSession,
              onShare: _shareLogs,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editSessionName();
                } else if (value == 'delete') {
                  _confirmDeleteSession();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Edit Name'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete Session',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Active search indicator banner
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _isSearching && _searchQuery.isNotEmpty
                ? _SearchBanner(query: _searchQuery, colorScheme: colorScheme)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: _isCurrentSession
                ? StreamBuilder<List<ApiLogModel>>(
                    stream: ApiLogService().logStream,
                    initialData: ApiLogService().getCurrentSessionLogs(),
                    builder: (context, snapshot) {
                      return _buildLogList(_filterLogs(snapshot.data ?? []));
                    },
                  )
                : FutureBuilder<List<ApiLogModel>>(
                    future: ApiLogService().getLogsForSession(widget.sessionId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _buildLogList(_filterLogs(snapshot.data ?? []));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<ApiLogModel> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.trim().isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.api_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.trim().isNotEmpty
                    ? 'No results for "$_searchQuery"'
                    : 'No API logs captured for this session',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _LogItem(log: log, searchQuery: _searchQuery.trim());
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Banner
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBanner extends StatelessWidget {
  final String query;
  final ColorScheme colorScheme;
  const _SearchBanner({required this.query, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        // Warm amber tint to signal "highlight mode"
        color: const Color(0xFFFFF8E1),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFD54F).withOpacity(0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.highlight_rounded,
              size: 14, color: Color(0xFF795548)),
          const SizedBox(width: 6),
          Text(
            'Highlighting: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.brown.shade600,
            ),
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
// Log Item
// ─────────────────────────────────────────────────────────────────────────────

class _LogItem extends StatelessWidget {
  final ApiLogModel log;
  final String searchQuery;

  const _LogItem({required this.log, required this.searchQuery});

  bool _isMatch(ApiLogModel log, String query) {
    if (query.isEmpty) return false;
    final q = query.toLowerCase();
    return log.url.toLowerCase().contains(q) ||
        log.method.toLowerCase().contains(q) ||
        (log.statusCode?.toString().contains(q) ?? false) ||
        (log.screenName?.toLowerCase().contains(q) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final matched = _isMatch(log, searchQuery);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ApiLogDetailScreen(log: log)),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // Very subtle left accent line for matched rows
          border: Border(
            left: matched
                ? const BorderSide(color: Color(0xFFFFD54F), width: 3)
                : BorderSide.none,
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: method + status + time ──────────────────────────
            Row(
              children: [
                _MethodBadge(method: log.method, searchQuery: searchQuery),
                const SizedBox(width: 8),
                _StatusBadge(
                    statusCode: log.statusCode,
                    isError: log.isError,
                    searchQuery: searchQuery),
                const Spacer(),
                Text(
                  log.formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Row 2: URL with highlights ──────────────────────────────
            _HighlightedText(
              text: log.url,
              query: searchQuery,
              baseStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                color: colorScheme.onSurface, // ← always readable
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),

            // ── Row 3: duration + screen name + date ───────────────────
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  log.formattedDuration,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                if (log.screenName != null) ...[
                  Icon(
                    Icons.stay_current_portrait_rounded,
                    size: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _HighlightedText(
                      text: log.screenName!,
                      query: searchQuery,
                      baseStyle: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ] else
                  const Spacer(),
                const SizedBox(width: 8),
                Text(
                  '${log.timestamp.day.toString().padLeft(2, '0')}/'
                  '${log.timestamp.month.toString().padLeft(2, '0')}/'
                  '${log.timestamp.year}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ],
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
  final int? maxLines;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
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
        // remaining non-matching text
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: baseStyle, // normal colour, fully readable
          ));
        }
        break;
      }

      // Non-matching chunk before this match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: baseStyle, // normal colour
        ));
      }

      // The matching chunk — amber marker, always dark text
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: baseStyle.copyWith(
            backgroundColor: const Color(0xFFFFD54F), // vivid amber
            color: const Color(0xFF1A1A1A), // near-black, always readable
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Method Badge
// ─────────────────────────────────────────────────────────────────────────────

class _MethodBadge extends StatelessWidget {
  final String method;
  final String searchQuery;
  const _MethodBadge({required this.method, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final color = _getMethodColor(method);
    final isHighlighted = searchQuery.isNotEmpty &&
        method.toLowerCase().contains(searchQuery.toLowerCase());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.25) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isHighlighted ? color : color.withOpacity(0.45),
          width: isHighlighted ? 1.5 : 0.8,
        ),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final int? statusCode;
  final bool isError;
  final String searchQuery;
  const _StatusBadge(
      {this.statusCode, required this.isError, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : Colors.green;
    final statusStr = '${statusCode ?? '---'}';
    final isHighlighted = searchQuery.isNotEmpty &&
        statusStr.toLowerCase().contains(searchQuery.toLowerCase());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.25) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isHighlighted ? color : color.withOpacity(0.45),
          width: isHighlighted ? 1.5 : 0.8,
        ),
      ),
      child: Text(
        statusStr,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share Logs Button
// ─────────────────────────────────────────────────────────────────────────────

class _ShareLogsButton extends StatefulWidget {
  final String sessionId;
  final bool isCurrentSession;
  final Future<void> Function(List<ApiLogModel> logs) onShare;

  const _ShareLogsButton({
    required this.sessionId,
    required this.isCurrentSession,
    required this.onShare,
  });

  @override
  State<_ShareLogsButton> createState() => _ShareLogsButtonState();
}

class _ShareLogsButtonState extends State<_ShareLogsButton> {
  bool _isExporting = false;

  void _handleShare() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      List<ApiLogModel> logs;
      if (widget.isCurrentSession) {
        logs = ApiLogService().getCurrentSessionLogs();
      } else {
        logs = await ApiLogService().getLogsForSession(widget.sessionId);
      }
      await widget.onShare(logs);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isExporting) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.share_rounded),
      tooltip: 'Share logs text file',
      onPressed: _handleShare,
    );
  }
}
