import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/dev_stubs/dev_card_issuer.dart';
import 'package:wallet_test/features/cards/card_issue_bloc.dart';
import 'package:wallet_test/features/cards/card_issue_page.dart';
import 'package:wallet_test/features/cards/card_issuer.dart';

import '../../helpers/test_get_it.dart';

void main() {
  testWidgets('page renders', (tester) async {
    await testWithGetIt(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      expect(find.byType(CardIssuePage), findsOneWidget);
      expect(find.text('Issue card'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('bloc is taken from GetIt', (tester) async {
    await testWithGetIt(() async {
      final bloc = CardIssueBloc(issuer: GetIt.instance<ICardIssuer>());
      int blocRequests = 0;

      GetIt.instance.unregister<CardIssueBloc>();
      GetIt.instance.registerFactory<CardIssueBloc>(() {
        blocRequests++;
        return bloc;
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      expect(blocRequests, 1);

      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('ICardIssuer is taken from GetIt', (tester) async {
    await testWithGetIt(() async {
      final issuer = GetIt.instance<ICardIssuer>() as DevCardIssuer;

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      await tester.tap(find.text('Issue card'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(const SizedBox());

      expect(issuer.cancelCalls, 1);
    });
  });

  testWidgets('dispose closes bloc and cancels pending once', (tester) async {
    await testWithGetIt(() async {
      final issuer = GetIt.instance<ICardIssuer>() as DevCardIssuer;
      final bloc = CardIssueBloc(issuer: issuer);

      GetIt.instance.unregister<CardIssueBloc>();
      GetIt.instance.registerFactory<CardIssueBloc>(() => bloc);

      await tester.pumpWidget(
        const MaterialApp(
          home: CardIssuePage(cardId: 'card_1'),
        ),
      );

      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      expect(bloc.isClosed, isTrue);
      expect(issuer.cancelCalls, 1);
    });
  });
}
