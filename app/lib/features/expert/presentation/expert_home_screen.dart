import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';

import '../../authentication/data/auth_providers.dart';
import '../../authentication/presentation/auth_screen.dart';
import '../../community/presentation/community_screen.dart';
import '../../community/presentation/messages_screen.dart';
import 'diagnosis_queue_screen.dart';

class ExpertHomeScreen extends ConsumerWidget {
  const ExpertHomeScreen({super.key});

  static const forest = Color(0xFF183F32);
  static const cream = Color(0xFFF7F6EF);
  static const muted = Color(0xFF849087);

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.expertLogoutQuestion),
        content: const Text(
          'Are you sure you want to log out of your expert account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: forest),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(authApiServiceProvider).logout();
    } catch (_) {
      // Always return to authentication even if the server is unavailable.
    }

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5EDDF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.spa_rounded, color: forest, size: 27),
                ),
                const SizedBox(width: 11),
                const Text(
                  'AETHERA',
                  style: TextStyle(
                    color: forest,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.logout,
                  onPressed: () => _logout(context, ref),
                  icon: const Icon(Icons.logout_rounded, color: forest),
                ),
              ],
            ),
            const SizedBox(height: 35),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: forest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFFC9D8B9),
                        size: 17,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'EXPERT WORKSPACE',
                        style: TextStyle(
                          color: Color(0xFFC9D8B9),
                          fontSize: 10,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Knowledge that makes a difference.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 11),
                  Text(
                    'Support farmers, review crop diagnoses and share trusted agricultural knowledge.',
                    style: TextStyle(
                      color: Color(0xFFD7E1D5),
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'YOUR WORKSPACE',
              style: TextStyle(
                color: forest,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 13),
            _workspaceCard(
              icon: Icons.fact_check_outlined,
              title: 'Diagnosis review',
              subtitle: 'Review crop photos and validate farmer cases.',
              tag: 'CASE MANAGEMENT',
              onTap: () => _open(context, const DiagnosisQueueScreen()),
            ),
            const SizedBox(height: 12),
            _workspaceCard(
              icon: Icons.forum_outlined,
              title: 'Farmer community',
              subtitle:
                  'Share knowledge and discover agricultural discussions.',
              tag: 'COMMUNITY',
              onTap: () => _open(context, const CommunityScreen()),
            ),
            const SizedBox(height: 12),
            _workspaceCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Messages',
              subtitle: 'Communicate directly with farmers and experts.',
              tag: 'CONVERSATIONS',
              onTap: () => _open(context, const MessagesScreen()),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDDE),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Row(
                children: [
                  Icon(Icons.eco_outlined, color: forest, size: 25),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your expertise helps transform agricultural knowledge into better decisions for farmers.',
                      style: TextStyle(
                        color: forest,
                        height: 1.5,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _workspaceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFE9ECE4)),
          ),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDDE),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: forest, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      style: const TextStyle(
                        color: Color(0xFF527B58),
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF24352C),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: forest,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
