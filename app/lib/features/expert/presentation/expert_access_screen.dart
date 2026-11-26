import 'package:flutter/material.dart';

class ExpertAccessScreen extends StatelessWidget {
  const ExpertAccessScreen({super.key, required this.status});

  final String status;

  static const forest = Color(0xFF183F32);

  @override
  Widget build(BuildContext context) {
    final isRejected = status == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6EF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRejected
                    ? Icons.info_outline_rounded
                    : Icons.hourglass_top_rounded,
                color: forest,
                size: 58,
              ),
              const SizedBox(height: 22),
              Text(
                isRejected
                    ? 'Application not approved'
                    : 'Your application is under review',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: forest,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isRejected
                    ? 'Your expert application was not approved. Please contact the AETHERA administration team for more information.'
                    : 'Thank you for joining AETHERA. Our team needs to approve your expert account before you can access the expert workspace.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF849087),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
