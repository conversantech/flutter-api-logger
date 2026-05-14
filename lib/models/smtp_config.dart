class RecipientConfig {
  /// The display name of the recipient (e.g., 'QA Team').
  final String name;

  /// The email address of the recipient.
  final String email;

  const RecipientConfig({
    required this.name,
    required this.email,
  });
}

class SmtpConfig {
  /// The SMTP server host address (e.g., 'smtp.gmail.com').
  final String server;

  /// The SMTP server port (e.g., 587 or 465).
  final int port;

  /// The username for SMTP authentication.
  final String username;

  /// The password for SMTP authentication.
  final String password;

  /// The email address that will appear in the "From" field.
  final String fromEmail;

  /// Whether to use a secure connection (SSL/TLS).
  final bool secure;

  /// A list of default recipients to display as chips in the UI.
  final List<RecipientConfig> defaultRecipients;

  const SmtpConfig({
    required this.server,
    required this.port,
    required this.username,
    required this.password,
    required this.fromEmail,
    this.secure = false,
    this.defaultRecipients = const [],
  });
}
