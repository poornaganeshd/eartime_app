/// Small, dependency-free formatting helpers shared by the UI.
class Fmt {
  Fmt._();

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String two(int n) => n.toString().padLeft(2, '0');

  /// `01:05:09`
  static String clock(Duration d) {
    final s = d.isNegative ? Duration.zero : d;
    return '${two(s.inHours)}:${two(s.inMinutes % 60)}:${two(s.inSeconds % 60)}';
  }

  /// `1h 05m`, `12m`, `45s`
  static String duration(Duration d, {bool seconds = false}) {
    final s = d.isNegative ? Duration.zero : d;
    if (s.inHours > 0) return '${s.inHours}h ${two(s.inMinutes % 60)}m';
    if (s.inMinutes > 0 || !seconds) return '${s.inMinutes}m';
    return '${s.inSeconds}s';
  }

  /// Compact form for chart axes: `2h`, `45m`.
  static String short(Duration d) {
    if (d.inHours >= 1) {
      final h = d.inMinutes / 60;
      return h >= 10 ? '${h.round()}h' : '${h.toStringAsFixed(1)}h';
    }
    return '${d.inMinutes}m';
  }

  /// `14:05`
  static String time(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

  static String weekday(DateTime t) => _weekdays[t.weekday - 1];

  static String month(DateTime t) => _months[t.month - 1];

  /// `Today`, `Yesterday`, `Mon 21 Sep`
  static String day(DateTime t, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final that = DateTime(t.year, t.month, t.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${weekday(t)} ${t.day} ${month(t)}';
  }

  /// `just now`, `5 min ago`, `3 h ago`, `Mon 21 Sep`
  static String ago(DateTime t, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final d = n.difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return day(t, now: n);
  }

  static String percent(double fraction) => '${(fraction * 100).round()}%';

  static String greeting(DateTime now) {
    final h = now.hour;
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    if (h >= 17 && h < 22) return 'Good evening';
    return 'Good night';
  }
}
