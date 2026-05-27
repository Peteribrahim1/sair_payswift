void main() {
  final isoDate = "2026-05-22T19:49:44.018Z";
  final dt = DateTime.parse(isoDate).toLocal();
  final now = DateTime.now();
  final diff = now.difference(dt);
  print('isoDate: $isoDate');
  print('dt: $dt');
  print('now: $now');
  print('diff in minutes: ${diff.inMinutes}');
  print('diff in hours: ${diff.inHours}');
  print('diff in days: ${diff.inDays}');
}
