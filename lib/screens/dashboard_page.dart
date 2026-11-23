import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/aurora_background.dart';
import '../widgets/fade_slide.dart';
import '../widgets/gradient_button.dart';
import 'achievement_sheet.dart';

/// PAGE 3 — My Journey dashboard (Firestore CRUD).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final User _user = FirebaseAuth.instance.currentUser!;
  late final AchievementService _service = AchievementService(_user.uid);
  late final Stream<List<Achievement>> _stream = _service.watch(); // created once
  final _search = TextEditingController();
  String _category = 'All';
  String _status = 'All';
  final Set<String> _removing = {}; // hides swiped items instantly

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _name {
    final n = _user.displayName?.trim() ?? '';
    return n.isEmpty ? 'Friend' : n.split(' ').first;
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  // CREATE + UPDATE open the same bottom sheet.
  void _openSheet([Achievement? existing]) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.55),
        constraints: const BoxConstraints(maxWidth: 640),
        builder: (_) => AchievementSheet(service: _service, existing: existing),
      );

  // UPDATE: quick toggle between In progress and Completed.
  Future<void> _toggle(Achievement a) async {
    final messenger = ScaffoldMessenger.of(context);
    final completing = !a.isCompleted;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      await _service.setStatus(
        a.id,
        completing ? 'Completed' : 'In progress',
        date: completing && !a.date.isBefore(today.add(const Duration(days: 1))) ? today : null,
      );
      showAppSnack(messenger, completing ? 'Marked as completed. Well done!' : 'Moved back to in progress');
    } catch (e) {
      showAppSnack(messenger, 'Could not update: $e', error: true);
    }
  }

  // DELETE (always confirmed with an AlertDialog first), with Undo.
  Future<void> _delete(Achievement a, {bool alreadyConfirmed = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!alreadyConfirmed) {
      final ok = await _confirmDelete(a);
      if (!ok) return;
    }
    setState(() => _removing.add(a.id));
    try {
      await _service.delete(a.id);
      showAppSnack(
        messenger,
        '"${a.title}" deleted',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await _service.restore(a);
            if (mounted) setState(() => _removing.remove(a.id));
          },
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _removing.remove(a.id));
      showAppSnack(messenger, 'Could not delete: $e', error: true);
    }
  }

  Future<bool> _confirmDelete(Achievement a) => confirmAction(
        context,
        title: 'Delete achievement?',
        message: '"${a.title}" will be removed from your journey.',
        confirmLabel: 'Delete',
        icon: Icons.delete_outline_rounded,
        danger: true,
      );

  Future<void> _logout() async {
    final ok = await confirmAction(
      context,
      title: 'Log out?',
      message: 'Your achievements are saved safely in the cloud.',
      confirmLabel: 'Log out',
      icon: Icons.logout_rounded,
    );
    if (ok) await FirebaseAuth.instance.signOut(); // AuthGate returns to Login
  }

  List<Achievement> _filter(List<Achievement> all) {
    final q = _search.text.trim().toLowerCase();
    return all
        .where((a) => _category == 'All' || a.category == _category)
        .where((a) => _status == 'All' || a.status == _status)
        .where((a) => q.isEmpty || a.title.toLowerCase().contains(q) || a.reflection.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: _NewButton(onPressed: () => _openSheet()),
        body: AuroraBackground(
          subtle: true,
          child: SafeArea(
            bottom: false,
            child: StreamBuilder<List<Achievement>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) return _ErrorView(error: '${snap.error}');
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final all = snap.data!.where((a) => !_removing.contains(a.id)).toList();
                final shown = _filter(all);
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              FadeSlideIn(child: _header()),
                              const SizedBox(height: 24),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 100),
                                child: _JourneyCard(items: all),
                              ),
                              const SizedBox(height: 14),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 180),
                                child: _statsRow(all),
                              ),
                              const SizedBox(height: 28),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 240),
                                child: Row(
                                  children: [
                                    Text('My achievements', style: AppText.display(22)),
                                    const SizedBox(width: 10),
                                    _CountPill(count: shown.length),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 280),
                                child: TextField(
                                  controller: _search,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'Search achievements or reflections',
                                    prefixIcon: const Icon(Icons.search_rounded),
                                    suffixIcon: _search.text.isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: 'Clear search',
                                            icon: const Icon(Icons.close_rounded),
                                            onPressed: () {
                                              _search.clear();
                                              setState(() {});
                                            },
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ]),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: FadeSlideIn(
                            delay: const Duration(milliseconds: 320),
                            child: SizedBox(height: 42, child: _categoryChips()),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: FadeSlideIn(
                              delay: const Duration(milliseconds: 360),
                              child: _statusSelector(),
                            ),
                          ),
                        ),
                        if (shown.isEmpty)
                          SliverToBoxAdapter(
                            child: _EmptyState(
                              hasAny: all.isNotEmpty,
                              onAdd: () => _openSheet(),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => _buildCard(shown[i], i),
                                childCount: shown.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

  Widget _header() => Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
            alignment: Alignment.center,
            child: Text(_name[0].toUpperCase(), style: AppText.display(22, color: AppColors.bgDeep)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting,
                    style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                Text(_name, overflow: TextOverflow.ellipsis, style: AppText.display(26)),
              ],
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.07),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout_rounded, color: AppColors.text),
              onPressed: _logout,
            ),
          ),
        ],
      );

  Widget _statsRow(List<Achievement> all) => Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.emoji_events_rounded,
              label: 'Total',
              value: all.length,
              color: AppColors.lilac,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              icon: Icons.timelapse_rounded,
              label: 'In progress',
              value: all.where((a) => !a.isCompleted).length,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              icon: Icons.star_rounded,
              label: 'Highlights',
              value: all.where((a) => a.isFeatured).length,
              color: AppColors.peach,
            ),
          ),
        ],
      );

  Widget _categoryChips() {
    final names = ['All', ...kCategories];
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: names.length,
      separatorBuilder: (context, i) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final name = names[i];
        final selected = _category == name;
        final style = name == 'All'
            ? const CategoryStyle(Icons.auto_awesome_rounded, AppColors.lilac)
            : categoryStyle(name);
        return ChoiceChip(
          label: Text(name),
          avatar: Icon(style.icon, size: 16, color: selected ? AppColors.bgDeep : style.color),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => setState(() => _category = name),
          selectedColor: style.color,
          backgroundColor: Colors.white.withOpacity(0.06),
          labelStyle: TextStyle(
            color: selected ? AppColors.bgDeep : AppColors.text,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(color: selected ? style.color : AppColors.stroke),
          shape: const StadiumBorder(),
        );
      },
    );
  }

  Widget _statusSelector() => SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'All', label: Text('All')),
            ButtonSegment(value: 'In progress', label: Text('In progress'), icon: Icon(Icons.timelapse_rounded)),
            ButtonSegment(value: 'Completed', label: Text('Completed'), icon: Icon(Icons.verified_rounded)),
          ],
          selected: {_status},
          onSelectionChanged: (s) => setState(() => _status = s.first),
          style: SegmentedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.04),
            foregroundColor: AppColors.textMuted,
            selectedBackgroundColor: AppColors.lilac.withOpacity(0.22),
            selectedForegroundColor: AppColors.text,
            side: const BorderSide(color: AppColors.stroke),
          ),
        ),
      );

  Widget _buildCard(Achievement a, int i) => FadeSlideIn(
        key: ValueKey('anim-${a.id}'),
        delay: Duration(milliseconds: 50 * min(i, 8)),
        child: Dismissible(
          key: ValueKey(a.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(a),
          onDismissed: (_) => _delete(a, alreadyConfirmed: true),
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.only(right: 24),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
                SizedBox(width: 8),
                Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              ],
            ),
          ),
          child: _AchievementCard(
            item: a,
            onTap: () => _openSheet(a),
            onToggle: () => _toggle(a),
            onDelete: () => _delete(a),
          ),
        ),
      );
}

// ───────────────────────── Pieces of the dashboard ─────────────────────────

class _NewButton extends StatelessWidget {
  const _NewButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.violet.withOpacity(0.5), blurRadius: 26, offset: const Offset(0, 10)),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: onPressed,
          elevation: 0,
          backgroundColor: AppColors.lilac,
          foregroundColor: AppColors.bgDeep,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New achievement', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.items});
  final List<Achievement> items;

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final done = items.where((a) => a.isCompleted).length;
    final progress = total == 0 ? 0.0 : done / total;
    final now = DateTime.now();
    final thisMonth = items.where((a) => a.date.year == now.year && a.date.month == now.month).length;
    final message = total == 0
        ? 'Add your first achievement to begin.'
        : progress >= 1
            ? 'Everything completed. Remarkable!'
            : progress >= 0.5
                ? 'More than halfway there. Keep going!'
                : "You're building momentum. Every step counts.";

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B2A7A), Color(0xFF221844)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: AppColors.violet.withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 14)),
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => SizedBox(
              width: 108,
              height: 108,
              child: CustomPaint(
                painter: _RingPainter(v),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(v * 100).round()}%', style: AppText.display(26)),
                      const Text('complete', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR JOURNEY',
                  style: TextStyle(
                      color: AppColors.lilac, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
                ),
                const SizedBox(height: 6),
                Text('$done of $total completed', style: AppText.display(21)),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: AppColors.peach, size: 16),
                      const SizedBox(width: 4),
                      Text('$thisMonth this month',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withOpacity(0.12),
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [AppColors.lilac, AppColors.peach, AppColors.gold, AppColors.lilac],
          transform: GradientRotation(-pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text('${v.round()}', style: AppText.display(26)),
            ),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Container(
          key: ValueKey(count),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.lilac.withOpacity(0.18),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('$count', style: const TextStyle(color: AppColors.lilac, fontWeight: FontWeight.w800)),
        ),
      );
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.item,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final Achievement item;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(item.category);
    final statusColor = item.isCompleted ? AppColors.mint : AppColors.gold;
    final radius = BorderRadius.circular(22);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.88),
        borderRadius: radius,
        border: Border.all(
          color: item.isFeatured ? AppColors.gold.withOpacity(0.5) : AppColors.stroke,
        ),
        boxShadow: item.isFeatured
            ? [BoxShadow(color: AppColors.gold.withOpacity(0.12), blurRadius: 24)]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: style.color.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(style.icon, color: style.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (item.isFeatured)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _Pill(text: item.category, color: style.color),
                          _Pill(
                            text: item.status,
                            color: statusColor,
                            icon: item.isCompleted ? Icons.verified_rounded : Icons.timelapse_rounded,
                          ),
                        ],
                      ),
                      if (item.reflection.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          item.reflection,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.event_rounded, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(formatDate(item.date),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(width: 12),
                          for (var i = 1; i <= 5; i++)
                            Icon(
                              Icons.circle,
                              size: 7,
                              color: i <= item.impact ? AppColors.peach : Colors.white.withOpacity(0.15),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _StatusToggle(done: item.isCompleted, onTap: onToggle),
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
                      color: AppColors.surfaceHigh,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (v) => v == 'edit' ? onTap() : onDelete(),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                            SizedBox(width: 10),
                            Text('Delete', style: TextStyle(color: AppColors.danger)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({required this.done, required this.onTap});
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: done ? 'Mark as in progress' : 'Mark as completed',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done ? const LinearGradient(colors: [AppColors.mint, Color(0xFF34D399)]) : null,
                border: done ? null : Border.all(color: AppColors.textMuted, width: 1.6),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: done
                    ? const Icon(Icons.check_rounded, key: ValueKey('on'), size: 18, color: AppColors.bgDeep)
                    : const SizedBox(key: ValueKey('off')),
              ),
            ),
          ),
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(text, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasAny, required this.onAdd});
  final bool hasAny;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => FadeSlideIn(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/images/becoming_hero.png',
                    height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              Text(hasAny ? 'Nothing matches' : 'Your journey starts here',
                  textAlign: TextAlign.center, style: AppText.display(22)),
              const SizedBox(height: 8),
              Text(
                hasAny
                    ? 'Try another category, status or search word.'
                    : 'Record a course you finished, a skill you learned or a goal you are chasing.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              if (!hasAny) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: 260,
                  child: GradientButton(
                    label: 'Add my first win',
                    icon: Icons.add_rounded,
                    onPressed: onAdd,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('Could not load your journey', style: AppText.display(20)),
              const SizedBox(height: 8),
              Text(
                error.contains('permission-denied')
                    ? 'Firestore blocked the request. Check that the security rules are published.'
                    : error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
}
