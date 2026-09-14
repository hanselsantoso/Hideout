import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/hideout_tokens.dart';

class CheckInPassCard extends StatelessWidget {
  const CheckInPassCard({
    super.key,
    required this.registrationId,
    required this.tournamentName,
    this.playerName = '',
    this.playerCode = '',
    this.deck = '',
    this.venue = '',
    this.city = '',
    this.date = '',
  });

  final String registrationId;
  final String tournamentName;
  final String playerName;
  final String playerCode;
  final String deck;
  final String venue;
  final String city;
  final String date;

  String get _code => playerCode.isEmpty ? registrationId : playerCode;

  @override
  Widget build(BuildContext context) {
    final location = [venue, city].where((part) => part.isNotEmpty).join(', ');
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CHECK-IN PASS', style: HDTText.overline(size: 9)),
                    const SizedBox(height: 4),
                    Text(tournamentName.isEmpty
                        ? 'Tournament'
                        : tournamentName),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(location,
                          style: HDTText.body(
                              size: 11, color: HDTColors.text3)),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: HDTSpace.sm, vertical: HDTSpace.xs),
                decoration: BoxDecoration(
                  color: HDTColors.success.withValues(alpha: .15),
                  borderRadius: HDTR.sm,
                  border: Border.all(
                      color: HDTColors.success.withValues(alpha: .4)),
                ),
                child: Text('ACTIVE',
                    style: HDTText.overline(
                        size: 8, color: HDTColors.success)),
              ),
            ],
          ),
          const SizedBox(height: HDTSpace.lg),
          Center(
              child: Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(HDTSpace.sm),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: HDTR.lg,
                ),
              child: QrImageView(
                data: 'TURNY|$registrationId|$_code',
                version: QrVersions.auto,
                backgroundColor: Colors.white,
                errorStateBuilder: (context, error) => const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                ),
              ),
            ),
          ),
          const SizedBox(height: HDTSpace.sm),
          Center(
            child: Text(_code,
                style: HDTText.mono(size: 12, color: HDTColors.text2)),
          ),
          const SizedBox(height: HDTSpace.md),
          if (playerName.isNotEmpty || deck.isNotEmpty)
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                if (playerName.isNotEmpty)
                  Text('PLAYER: ${playerName.toUpperCase()}',
                      style: HDTText.mono(size: 10, color: HDTColors.text3)),
                if (deck.isNotEmpty)
                  Text('DECK: ${deck.toUpperCase()}',
                      style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          const SizedBox(height: HDTSpace.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _code));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Check-in code copied.')),
                );
              },
              icon: const Icon(Icons.copy_outlined, size: 14),
              label: const Text('COPY CHECK-IN CODE'),
            ),
          ),
          const SizedBox(height: HDTSpace.md),
          Text(
            'Show this QR at the venue entrance, or give the code to the judge when they call your match.',
            style: HDTText.body(size: 11, color: HDTColors.text3),
          ),
        ],
      ),
    );
  }
}
