String rp(num value) {
  final n = value.round().toString();
  final chars = n.split('');
  var out = '';
  for (var i = 0; i < chars.length; i++) {
    final pos = chars.length - i;
    out += chars[i];
    if (pos > 1 && pos % 3 == 1) out += '.';
  }
  return 'Rp$out';
}

String stamp() {
  final d = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
}

String dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String displayDate(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
