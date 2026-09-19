/// 字符串运行时保护：关键字符串以 XOR 密文存储，运行时还原。
/// 目的：Blutter dump libapp.so 字符串池时看到的是乱码，而非明文。
/// 注意：这不能阻止真正下功夫的人，但能大幅提高逆向门槛（配合
/// flutter build apk --obfuscate，类名/方法名已随机化）。
library;

/// 将字符串编码为 XOR 密文（明文 -> 整数列表）
/// 生成后写进代码里，运行时用 [xorDecode] 还原。
String xorEncode(String s, int key) {
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i) ^ (key + i * 31) & 0xFFFF;
    buf.writeCharCode(c);
  }
  return buf.toString();
}

/// 还原 XOR 密文 -> 明文
String xorDecode(String s, int key) {
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i) ^ (key + i * 31) & 0xFFFF;
    buf.writeCharCode(c);
  }
  return buf.toString();
}

/// 关键字符串（密文，key 各不相同）
/// '_prefix' = 'https://auth.platorelay.com/a?d=' （XOR 0x5A 生成）
const String _sPrefix = '2\r\u00ec\u00c7\u00a5\u00cf\u013b\u011c\u0133\u0104\u01e4\u01c7\u01e0\u019d\u0260\u024a\u023e\u0206\u02fa\u02c2\u02aa\u0284\u037d\u030d\u0321\u030e\u03ed\u03b0\u03df\u03e2\u0398\u0426';
const int _kPrefix = 0x5A;

String get kPrefix => xorDecode(_sPrefix, _kPrefix);