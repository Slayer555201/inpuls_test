import 'package:dio/dio.dart';

import 'package:wallet_test/core/errors/app_exception.dart';
import 'package:wallet_test/core/network/api_client.dart';
import 'package:wallet_test/features/transfers/transfer.dart';
import 'package:wallet_test/features/transfers/transfer_repository.dart';

class TransferStatusSyncService {
  TransferStatusSyncService({
    required ApiClient api,
    required ITransferRepository repository,
  })  : _api = api,
        _repository = repository;

  static const int maxAttempts = 3;

  static const List<Duration> retryDelays = [
    Duration(milliseconds: 200),
    Duration(milliseconds: 500),
  ];

  static const Set<int> retryableStatusCodes = {408, 429, 503};

  static const Set<DioExceptionType> retryableTypes = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.receiveTimeout,
    DioExceptionType.sendTimeout,
  };

  final ApiClient _api;
  final ITransferRepository _repository;

  Future<TransferStatus> sync(
    Transfer transfer, {
    CancelToken? cancelToken,
  }) async {
    final String idempotencyKey =
        '${transfer.network.toLowerCase()}:${transfer.txHash}';

    Response<dynamic>? response;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        response = await _api.dio.get<dynamic>(
          '/v1/transfers/${transfer.txHash}/status',
          cancelToken: cancelToken,
          options: Options(
            headers: <String, dynamic>{
              'Idempotency-Key': idempotencyKey,
            },
          ),
        );

        break;
      } on DioException catch (error) {
        if (error.type == DioExceptionType.cancel) {
          throw const CancelException();
        }

        if (attempt == maxAttempts || !_canRetry(error)) {
          throw _mapDioError(error);
        }

        await Future<void>.delayed(retryDelays[attempt - 1]);
      }
    }

    final dynamic data = response!.data;

    final TransferStatus status = TransferStatus.fromName(
      (data is Map ? data['status'] as String? : null) ?? 'unknown',
    );

    try {
      await _repository.applyStatus(transfer, status, DateTime.now());
    } catch (_) {
      throw const TransferSyncException(code: 'localPersistenceFailed');
    }

    return status;
  }

  bool _canRetry(DioException error) {
    final int? statusCode = error.response?.statusCode;

    if (statusCode != null) {
      return retryableStatusCodes.contains(statusCode);
    }

    return retryableTypes.contains(error.type);
  }

  TransferSyncException _mapDioError(DioException error) {
    final int? statusCode = error.response?.statusCode;

    switch (statusCode) {
      case 401:
        return const TransferSyncException(code: 'unauthorized');
      case 404:
        return const TransferSyncException(code: 'notFound');
      case 409:
        return const TransferSyncException(code: 'conflict');
      case 408:
      case 429:
        return const TransferSyncException(code: 'rateLimited');
      case 503:
        return const TransferSyncException(code: 'serverUnavailable');
      case 500:
        return const TransferSyncException(code: 'internal');
    }

    if (statusCode != null) {
      return const TransferSyncException(code: 'internal');
    }

    return const TransferSyncException(code: 'network');
  }
}
