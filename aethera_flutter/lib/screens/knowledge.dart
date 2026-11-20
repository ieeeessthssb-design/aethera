import 'package:flutter/material.dart';

import '../widgets/app_shell.dart';
import '../widgets/knowledge_hub.dart';

class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppShell(
      role: Role.farmer, path: '/knowledge', child: KnowledgeHub());
}
