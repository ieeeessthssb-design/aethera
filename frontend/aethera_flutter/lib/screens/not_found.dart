import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('404',
                    style: display(size: 72, w: FontWeight.w700, height: 1)),
                const SizedBox(height: 16),
                Text('Page not found',
                    style: body(size: 20, w: FontWeight.w600)),
                const SizedBox(height: 8),
                Text("This field is empty. Let's head back to the farm.",
                    textAlign: TextAlign.center,
                    style: body(size: 14, color: AppColors.mutedForeground)),
                const SizedBox(height: 24),
                AppButton(
                    label: 'Go home',
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (r) => false)),
              ]),
            ),
          ),
        ),
      );
}
