import 'package:flutter/material.dart';

import '../../core/theme/hideout_tokens.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'public_top_nav.dart';

class PublicLeaderboardScreen extends StatelessWidget {
  const PublicLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
        titleSpacing: 0,
        title: const PublicTopNav(activeRoute: '/public/leaderboard'),
      ),
      body: const LeaderboardScreen(showAppBar: false),
    );
  }
}
