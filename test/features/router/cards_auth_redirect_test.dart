import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/features/router/cards_auth_redirect.dart';

void main() {
  group('cardsAuthRedirect', () {
    test('not authed on deep link goes to onboarding with encoded next', () {
      expect(
        cardsAuthRedirect(
          Uri.parse('/cards/card_1/issue?step=2'),
          false,
        ),
        '/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2',
      );
    });

    test('authed on onboarding returns safe next', () {
      expect(
        cardsAuthRedirect(
          Uri.parse('/onboarding?next=%2Fcards%2Fcard_1%2Fissue%3Fstep%3D2'),
          true,
        ),
        '/cards/card_1/issue?step=2',
      );
    });

    test('authed on onboarding with external next returns /cards', () {
      expect(
        cardsAuthRedirect(
          Uri.parse('/onboarding?next=https%3A%2F%2Fevil.com'),
          true,
        ),
        '/cards',
      );

      expect(
        cardsAuthRedirect(Uri.parse('/onboarding?next='), true),
        '/cards',
      );

      expect(
        cardsAuthRedirect(Uri.parse('/onboarding'), true),
        '/cards',
      );

      expect(
        cardsAuthRedirect(Uri.parse('/onboarding?next=%2Fwallet'), true),
        '/cards',
      );
    });

    test('not authed on onboarding returns null', () {
      expect(cardsAuthRedirect(Uri.parse('/onboarding'), false), isNull);

      expect(
        cardsAuthRedirect(
          Uri.parse('/onboarding?next=%2Fcards'),
          false,
        ),
        isNull,
      );
    });

    test('authed on cards returns null', () {
      expect(cardsAuthRedirect(Uri.parse('/cards'), true), isNull);

      expect(
        cardsAuthRedirect(Uri.parse('/cards/card_1/issue?step=2'), true),
        isNull,
      );
    });

    test('other paths return null', () {
      expect(cardsAuthRedirect(Uri.parse('/wallet'), false), isNull);
      expect(cardsAuthRedirect(Uri.parse('/wallet'), true), isNull);
    });
  });
}
