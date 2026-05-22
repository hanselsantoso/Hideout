import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/theme/hideout_tokens.dart';
import 'public_top_nav.dart';

class PublicCommunitiesScreen extends StatelessWidget {
  const PublicCommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
        titleSpacing: 0,
        title: const PublicTopNav(activeRoute: '/communities'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(FirestorePaths.communities)
            .limit(60)
            .snapshots(),
        builder: (context, snapshot) {
          final rows = snapshot.data?.docs
                  .map((doc) => _CommunityPublicEntry.fromFirestore(doc))
                  .toList() ??
              _demoCommunities;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COMMUNITIES', style: HDTText.display(size: 48)),
                        const SizedBox(height: HDTSpace.sm),
                        Text(
                          'Find active Beyblade communities, review region and status, and start a new community application without leaving the public page.',
                          style: HDTText.body(
                            size: 14,
                            color: HDTColors.text2,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: HDTSpace.lg),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    icon: const Icon(Icons.add),
                    label: const Text('OPEN COMMUNITY'),
                  ),
                ],
              ),
              const SizedBox(height: HDTSpace.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 980
                      ? 3
                      : constraints.maxWidth >= 620
                          ? 2
                          : 1;
                  final width =
                      (constraints.maxWidth - (cols - 1) * HDTSpace.md) / cols;
                  return Wrap(
                    spacing: HDTSpace.md,
                    runSpacing: HDTSpace.md,
                    children: [
                      for (final row in rows)
                        SizedBox(
                            width: width, child: _CommunityPublicCard(row)),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommunityPublicCard extends StatelessWidget {
  const _CommunityPublicCard(this.entry);

  final _CommunityPublicEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.xl),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: entry.color,
                  borderRadius: HDTR.md,
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white),
              ),
              const Spacer(),
              Text(entry.status,
                  style: HDTText.overline(
                    size: 9,
                    color: entry.status.contains('LIVE')
                        ? HDTColors.accentHover
                        : HDTColors.text3,
                  )),
            ],
          ),
          const SizedBox(height: HDTSpace.xl),
          Text(entry.name, style: HDTText.display(size: 24)),
          const SizedBox(height: HDTSpace.xs),
          Text(entry.region, style: HDTText.overline(size: 10)),
          const SizedBox(height: HDTSpace.xl),
          hdtDivider(),
          const SizedBox(height: HDTSpace.md),
          Row(
            children: [
              const Icon(Icons.groups_outlined,
                  size: 16, color: HDTColors.text3),
              const SizedBox(width: HDTSpace.sm),
              Text(entry.members, style: HDTText.mono()),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommunityPublicEntry {
  const _CommunityPublicEntry({
    required this.name,
    required this.region,
    required this.members,
    required this.status,
    required this.color,
  });

  final String name;
  final String region;
  final String members;
  final String status;
  final Color color;

  factory _CommunityPublicEntry.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _CommunityPublicEntry(
      name: (data['name'] ?? data['communityName'] ?? doc.id).toString(),
      region: (data['city'] ?? data['region'] ?? 'Indonesia').toString(),
      members: ((data['memberCount'] as num?)?.round() ?? 0).toString(),
      status: (data['status'] ?? 'OPEN').toString().toUpperCase(),
      color: HDTColors.accent,
    );
  }
}

const _demoCommunities = [
  _CommunityPublicEntry(
    name: 'JKT WOLVES',
    region: 'Jakarta',
    members: '1,248',
    status: '2 LIVE',
    color: HDTColors.accent,
  ),
  _CommunityPublicEntry(
    name: 'SBY SPIN',
    region: 'Surabaya',
    members: '843',
    status: '1 LIVE',
    color: HDTColors.danger,
  ),
  _CommunityPublicEntry(
    name: 'BDG GRINDERS',
    region: 'Bandung',
    members: '712',
    status: 'OPEN',
    color: HDTColors.info,
  ),
];
