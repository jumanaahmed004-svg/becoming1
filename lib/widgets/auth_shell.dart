import 'package:flutter/material.dart';

import '../theme.dart';
import 'aurora_background.dart';
import 'brand_logo.dart';
import 'fade_slide.dart';
import 'glass_card.dart';

/// Shared layout for the Login and Registration pages.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FadeSlideIn(
                          child: Center(child: Hero(tag: 'brand', child: BrandWordmark())),
                        ),
                        const SizedBox(height: 22),
                        const FadeSlideIn(delay: Duration(milliseconds: 90), child: _HeroArt()),
                        const SizedBox(height: 18),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 170),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eyebrow.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.lilac,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(title, style: AppText.display(30)),
                                const SizedBox(height: 6),
                                Text(subtitle,
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14.5)),
                                const SizedBox(height: 24),
                                child,
                              ],
                            ),
                          ),
                        ),
                        if (footer != null) ...[
                          const SizedBox(height: 12),
                          FadeSlideIn(delay: const Duration(milliseconds: 240), child: footer!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (canPop)
                Positioned(
                  left: 8,
                  top: 8,
                  child: IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.08)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/becoming_hero.png', fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.bg.withOpacity(0.75)],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 14,
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 16),
                    const SizedBox(width: 8),
                    Text('Every step counts.',
                        style: AppText.display(18).copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
