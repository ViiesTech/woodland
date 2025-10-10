import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  /// Returns a relative time string (e.g., "2 days ago", "3 hours ago", "1 day ago")
  /// For dates less than 3 days old, shows "X days ago"
  /// For dates 3 days or older, shows the actual date
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    // If the date is in the future
    if (difference.isNegative) {
      return _formatFutureDate(this, now);
    }

    // If less than 3 days old, show relative time
    if (difference.inDays < 3) {
      return _formatRelativeTime(difference);
    }

    // If 3 days or older, show the actual date
    return _formatDate(this);
  }

  /// Returns a relative time string for any time difference
  String get relativeTimeAlways {
    final now = DateTime.now();
    final difference = now.difference(this);

    // If the date is in the future
    if (difference.isNegative) {
      return _formatFutureDate(this, now);
    }

    return _formatRelativeTime(difference);
  }

  /// Returns a short relative time string (e.g., "2d ago", "3h ago")
  String get shortRelativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    // If the date is in the future
    if (difference.isNegative) {
      return _formatShortFutureDate(this, now);
    }

    // If less than 3 days old, show short relative time
    if (difference.inDays < 3) {
      return _formatShortRelativeTime(difference);
    }

    // If 3 days or older, show the actual date
    return _formatShortDate(this);
  }

  /// Returns a short relative time string for any time difference
  String get shortRelativeTimeAlways {
    final now = DateTime.now();
    final difference = now.difference(this);

    // If the date is in the future
    if (difference.isNegative) {
      return _formatShortFutureDate(this, now);
    }

    return _formatShortRelativeTime(difference);
  }

  /// Returns a formatted date string (e.g., "15 Jan 2024")
  String get formattedDate {
    return _formatDate(this);
  }

  /// Returns a short formatted date string (e.g., "15/01/24")
  String get shortFormattedDate {
    return _formatShortDate(this);
  }

  /// Returns a formatted date and time string (e.g., "15 Jan 2024 at 2:30 PM")
  String get formattedDateTime {
    return _formatDateTime(this);
  }

  /// Returns a short formatted date and time string (e.g., "15/01/24 14:30")
  String get shortFormattedDateTime {
    return _formatShortDateTime(this);
  }

  /// Returns true if the date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if the date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns true if the date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Returns true if the date is within the last 24 hours
  bool get isWithin24Hours {
    final now = DateTime.now();
    final difference = now.difference(this);
    return difference.inHours < 24 && !difference.isNegative;
  }

  /// Returns true if the date is within the last 7 days
  bool get isWithin7Days {
    final now = DateTime.now();
    final difference = now.difference(this);
    return difference.inDays < 7 && !difference.isNegative;
  }

  /// Returns true if the date is within the last 30 days
  bool get isWithin30Days {
    final now = DateTime.now();
    final difference = now.difference(this);
    return difference.inDays < 30 && !difference.isNegative;
  }

  // Private helper methods
  String _formatRelativeTime(Duration difference) {
    if (difference.inDays > 0) {
      return difference.inDays == 1
          ? '1 day ago'
          : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  String _formatShortRelativeTime(Duration difference) {
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  String _formatFutureDate(DateTime futureDate, DateTime now) {
    final difference = futureDate.difference(now);
    if (difference.inDays > 0) {
      return difference.inDays == 1
          ? 'Tomorrow'
          : 'In ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? 'In 1 hour'
          : 'In ${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? 'In 1 minute'
          : 'In ${difference.inMinutes} minutes';
    } else {
      return 'Now';
    }
  }

  String _formatShortFutureDate(DateTime futureDate, DateTime now) {
    final difference = futureDate.difference(now);
    if (difference.inDays > 0) {
      return 'In ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }

  String _formatShortDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yy');
    return formatter.format(date);
  }

  String _formatDateTime(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy \'at\' h:mm a');
    return formatter.format(date);
  }

  String _formatShortDateTime(DateTime date) {
    final formatter = DateFormat('dd/MM/yy HH:mm');
    return formatter.format(date);
  }
}

/// Extension for String to parse dates
extension StringDateTimeExtension on String {
  /// Converts a string to DateTime if it's a valid date format
  DateTime? get toDateTime {
    try {
      return DateTime.parse(this);
    } catch (e) {
      return null;
    }
  }

  /// Returns relative time if the string is a valid date
  String get relativeTime {
    final date = toDateTime;
    if (date != null) {
      return date.relativeTime;
    }
    return this; // Return original string if parsing fails
  }

  /// Returns relative time always if the string is a valid date
  String get relativeTimeAlways {
    final date = toDateTime;
    if (date != null) {
      return date.relativeTimeAlways;
    }
    return this; // Return original string if parsing fails
  }

  /// Returns short relative time if the string is a valid date
  String get shortRelativeTime {
    final date = toDateTime;
    if (date != null) {
      return date.shortRelativeTime;
    }
    return this; // Return original string if parsing fails
  }

  /// Returns short relative time always if the string is a valid date
  String get shortRelativeTimeAlways {
    final date = toDateTime;
    if (date != null) {
      return date.shortRelativeTimeAlways;
    }
    return this; // Return original string if parsing fails
  }
}
