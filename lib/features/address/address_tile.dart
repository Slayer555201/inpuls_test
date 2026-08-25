import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/theme/app_tokens.dart';
import 'package:wallet_test/features/address/address_display.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';

class AddressTile extends StatefulWidget {
  const AddressTile({
    super.key,
    required this.address,
    required this.network,
  });

  final String address;
  final String network;

  @override
  State<AddressTile> createState() => _AddressTileState();
}

class _AddressTileState extends State<AddressTile> {
  late final AddressTileBloc _bloc = GetIt.instance<AddressTileBloc>();

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  IconData _iconData(AddressTileState state) {
    if (state.error != null) {
      return Icons.error_outline;
    }

    if (state.copied) {
      return Icons.check;
    }

    return Icons.copy;
  }

  Color _iconColor(AddressTileState state) {
    if (state.error != null) {
      return AppTokens.danger;
    }

    if (state.copied) {
      return AppTokens.success;
    }

    return AppTokens.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final double textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    return Container(
      height: AppTokens.cellHeight,
      color: AppTokens.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.horizontalPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.network,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTokens.verticalGap),
                  Text(
                    formatAddressForCell(widget.address, textScaleFactor),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTokens.gapTextIcon),
          SizedBox(
            width: AppTokens.tapTarget,
            height: AppTokens.tapTarget,
            child: BlocBuilder<AddressTileBloc, AddressTileState>(
              bloc: _bloc,
              builder: (context, state) {
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: AppTokens.iconSize,
                  onPressed: () => _bloc.add(CopyTapped(widget.address)),
                  icon: Icon(
                    _iconData(state),
                    size: AppTokens.iconSize,
                    color: _iconColor(state),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
