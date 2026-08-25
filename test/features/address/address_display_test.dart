import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/features/address/address_display.dart';

void main() {
  group('formatAddressForCell', () {
    test('short address is returned as is', () {
      expect(formatAddressForCell('0x1234', 2.0), '0x1234');
      expect(formatAddressForCell('0x123456789012', 1.0), '0x123456789012');
      expect(formatAddressForCell('short', 1.0), 'short');
    });

    test('long address with 0x is shortened as 6 + 4', () {
      expect(
        formatAddressForCell(
          '0x1234567890abcdef1234567890abcdef12345678',
          1.0,
        ),
        '0x123456…5678',
      );
    });

    test('long address is shortened as 4 + 4 when textScaleFactor >= 1.6', () {
      expect(
        formatAddressForCell(
          '0x1234567890abcdef1234567890abcdef12345678',
          2.0,
        ),
        '0x1234…5678',
      );

      expect(
        formatAddressForCell(
          '0x1234567890abcdef1234567890abcdef12345678',
          1.6,
        ),
        '0x1234…5678',
      );
    });

    test('address without 0x is shortened too', () {
      expect(
        formatAddressForCell(
          'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
          1.0,
        ),
        'bc1qar…5mdq',
      );

      expect(
        formatAddressForCell(
          'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
          2.0,
        ),
        'bc1q…5mdq',
      );
    });

    test('0x prefix is never lost', () {
      const address = '0x1234567890abcdef1234567890abcdef12345678';

      expect(formatAddressForCell(address, 1.0).startsWith('0x'), isTrue);
      expect(formatAddressForCell(address, 2.0).startsWith('0x'), isTrue);
      expect(formatAddressForCell('0x1234', 2.0).startsWith('0x'), isTrue);
    });
  });
}
