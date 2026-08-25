const String _prefix = '0x';
const int _minBodyLength = 12;
const int _tailLength = 4;
const double _largeTextScaleFactor = 1.6;

String formatAddressForCell(String address, double textScaleFactor) {
  final bool hasPrefix = address.startsWith(_prefix);
  final String body = hasPrefix ? address.substring(_prefix.length) : address;

  if (body.length <= _minBodyLength) {
    return address;
  }

  final int headLength = textScaleFactor < _largeTextScaleFactor ? 6 : 4;

  final String head = body.substring(0, headLength);
  final String tail = body.substring(body.length - _tailLength);

  return '${hasPrefix ? _prefix : ''}$head…$tail';
}
