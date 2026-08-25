import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_transfer_repository.dart';
import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_status_sync_service.dart';

import '../../fakes/fake_http_client_adapter.dart';

const Transfer _transfer = Transfer(
  id: 'tr_1',
  network: 'Ethereum',
  txHash: '0x1234abcd',
  memo: 'secret memo',
  privateNote: 'secret note',
);

class _TestSetup {
  _TestSetup(List<HttpOutcome> outcomes)
      : adapter = FakeHttpClientAdapter(outcomes),
        repository = InMemoryTransferRepository() {
    final dio = Dio();
    dio.httpClientAdapter = adapter;

    service = TransferStatusSyncService(
      api: ApiClient(dio: dio),
      repository: repository,
    );
  }

  final FakeHttpClientAdapter adapter;
  final InMemoryTransferRepository repository;
  late final TransferStatusSyncService service;
}

void main() {
  test('429 then 200: two calls, one db write, confirmed', () async {
    final setup = _TestSetup([
      HttpOutcome(429),
      HttpOutcome(200, body: {'status': 'confirmed'}),
    ]);

    final status = await setup.service.sync(_transfer);

    expect(setup.adapter.calls.length, 2);
    expect(setup.repository.applyCalls, 1);
    expect(setup.repository.lastStatus, TransferStatus.confirmed);
    expect(status, TransferStatus.confirmed);
  });

  test('401: no retry, no db write, unauthorized', () async {
    final setup = _TestSetup([HttpOutcome(401)]);

    await expectLater(
      setup.service.sync(_transfer),
      throwsA(
        isA<TransferSyncException>().having(
          (error) => error.code,
          'code',
          'unauthorized',
        ),
      ),
    );

    expect(setup.adapter.calls.length, 1);
    expect(setup.repository.applyCalls, 0);
  });

  test('500: no retry, internal', () async {
    final setup = _TestSetup([HttpOutcome(500)]);

    await expectLater(
      setup.service.sync(_transfer),
      throwsA(
        isA<TransferSyncException>().having(
          (error) => error.code,
          'code',
          'internal',
        ),
      ),
    );

    expect(setup.adapter.calls.length, 1);
    expect(setup.repository.applyCalls, 0);
  });

  test('429 three times: three calls, rateLimited', () async {
    final setup = _TestSetup([
      HttpOutcome(429),
      HttpOutcome(429),
      HttpOutcome(429),
    ]);

    await expectLater(
      setup.service.sync(_transfer),
      throwsA(
        isA<TransferSyncException>().having(
          (error) => error.code,
          'code',
          'rateLimited',
        ),
      ),
    );

    expect(setup.adapter.calls.length, 3);
    expect(setup.repository.applyCalls, 0);
  });

  test('200 but local db fails: localPersistenceFailed', () async {
    final setup = _TestSetup([
      HttpOutcome(200, body: {'status': 'confirmed'}),
    ]);
    setup.repository.shouldFail = true;

    await expectLater(
      setup.service.sync(_transfer),
      throwsA(
        isA<TransferSyncException>().having(
          (error) => error.code,
          'code',
          'localPersistenceFailed',
        ),
      ),
    );

    expect(setup.adapter.calls.length, 1);
    expect(setup.repository.lastStatus, isNull);
  });

  test('Idempotency-Key is stable and lowercased', () async {
    final setup = _TestSetup([
      HttpOutcome(429),
      HttpOutcome(200, body: {'status': 'confirmed'}),
    ]);

    await setup.service.sync(_transfer);

    final keys = setup.adapter.calls
        .map((call) => call.headers['Idempotency-Key'])
        .toList();

    expect(keys.length, 2);
    expect(keys.first, 'ethereum:0x1234abcd');
    expect(keys.last, keys.first);
  });

  test('cancel throws CancelException without retry', () async {
    final setup = _TestSetup([HttpOutcome(200)]);
    final cancelToken = CancelToken();
    cancelToken.cancel();

    await expectLater(
      setup.service.sync(_transfer, cancelToken: cancelToken),
      throwsA(isA<CancelException>()),
    );

    expect(setup.adapter.calls.length, 0);
    expect(setup.repository.applyCalls, 0);
  });
}
