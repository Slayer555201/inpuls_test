import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_address_repository.dart';
import 'package:wallet_test/core/theme/app_tokens.dart';
import 'package:wallet_test/features/address/address_repository.dart';
import 'package:wallet_test/features/address/address_tile.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';

import '../../helpers/test_get_it.dart';

const String _address = '0x1234567890abcdef1234567890abcdef12345678';

AddressTileBloc _registerSharedBloc() {
  final bloc = AddressTileBloc(
    repository: GetIt.instance<IAddressRepository>(),
  );

  GetIt.instance.unregister<AddressTileBloc>();
  GetIt.instance.registerFactory<AddressTileBloc>(() => bloc);

  return bloc;
}

InMemoryAddressRepository _repository() {
  return GetIt.instance<IAddressRepository>() as InMemoryAddressRepository;
}

Widget _host({double textScale = 1.0}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(
            body: AddressTile(
              address: _address,
              network: 'Ethereum',
            ),
          ),
        );
      },
    ),
  );
}

Icon _icon(WidgetTester tester) {
  return tester.widget<Icon>(find.descendant(
    of: find.byType(AddressTile),
    matching: find.byType(Icon),
  ));
}

void main() {
  testWidgets('renders network and shortened address', (tester) async {
    await testWithGetIt(() async {
      _registerSharedBloc();

      await tester.pumpWidget(_host());

      expect(find.byType(AddressTile), findsOneWidget);
      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.text('0x123456…5678'), findsOneWidget);
      expect(_icon(tester).icon, Icons.copy);
      expect(_icon(tester).color, AppTokens.textSecondary);
    });
  });

  testWidgets('has no overflow with textScaleFactor 2.0', (tester) async {
    await testWithGetIt(() async {
      _registerSharedBloc();

      await tester.pumpWidget(_host(textScale: 2.0));
      await tester.pump();

      expect(find.text('0x1234…5678'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('tap calls IAddressRepository.copyAddress', (tester) async {
    await testWithGetIt(() async {
      _registerSharedBloc();

      await tester.pumpWidget(_host());
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 50));

      expect(_repository().copyCalls, 1);
      expect(_repository().lastAddress, _address);

      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('shows copied state on success', (tester) async {
    await testWithGetIt(() async {
      _registerSharedBloc();

      await tester.pumpWidget(_host());
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 50));

      expect(_icon(tester).icon, Icons.check);
      expect(_icon(tester).color, AppTokens.success);

      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('shows error state on failure', (tester) async {
    await testWithGetIt(() async {
      _registerSharedBloc();
      _repository().shouldFail = true;

      await tester.pumpWidget(_host());
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 50));

      expect(_icon(tester).icon, Icons.error_outline);
      expect(_icon(tester).color, AppTokens.danger);

      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('resets state after 1500ms', (tester) async {
    await testWithGetIt(() async {
      _registerSharedBloc();

      await tester.pumpWidget(_host());
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 50));

      expect(_icon(tester).icon, Icons.check);

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      expect(_icon(tester).icon, Icons.copy);
      expect(_icon(tester).color, AppTokens.textSecondary);
    });
  });

  testWidgets('bloc is closed after dispose', (tester) async {
    await testWithGetIt(() async {
      final bloc = _registerSharedBloc();

      await tester.pumpWidget(_host());
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      expect(bloc.isClosed, isTrue);
    });
  });
}
