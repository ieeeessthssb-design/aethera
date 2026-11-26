import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const forest = Color(0xFF183F32);
  static const cream = Color(0xFFF7F6EF);
  static const muted = Color(0xFF849087);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Row(
              children: [
                const Icon(Icons.spa_rounded, color: forest, size: 30),
                const SizedBox(width: 10),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDDE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: forest,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            const Text(
              'PLATFORM MANAGEMENT',
              style: TextStyle(
                color: forest,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Everything under control.',
              style: TextStyle(
                color: Color(0xFF24352C),
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Oversee the platform, support the expert network and maintain a trusted agricultural community.',
              style: TextStyle(color: muted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),
            const Text(
              'MANAGEMENT CENTER',
              style: TextStyle(
                color: forest,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _adminCard(
              icon: Icons.verified_user_outlined,
              title: 'Expert approvals',
              subtitle: 'Review and manage expert applications.',
              tag: 'PRIORITY',
            ),
            const SizedBox(height: 12),
            _adminCard(
              icon: Icons.people_outline_rounded,
              title: 'User management',
              subtitle: 'Manage platform accounts and access.',
              tag: 'USERS',
            ),
            const SizedBox(height: 12),
            _adminCard(
              icon: Icons.health_and_safety_outlined,
              title: 'Content & reports',
              subtitle: 'Oversee reports and community safety.',
              tag: 'MODERATION',
            ),
            const SizedBox(height: 12),
            _adminCard(
              icon: Icons.analytics_outlined,
              title: 'Platform overview',
              subtitle: 'Monitor platform activity and operations.',
              tag: 'INSIGHTS',
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: forest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined,
                      color: Color(0xFFD9E9B7), size: 28),
                  SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      'A trusted platform starts with responsible management.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.5,
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

  Widget _adminCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFEAECE4)),
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDDE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: forest, size: 24),
          ),
          const SizedBox(width: 13),
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
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: forest, size: 15),
        ],
      ),
    );
  }
}
