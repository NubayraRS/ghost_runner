import 'dart:async';

import 'package:flutter/material.dart';

import '../game/ghost_costume.dart';
import '../game/wardrobe_store.dart';
import 'ghost_portrait.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key, required this.wardrobe});
  final WardrobeStore wardrobe;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF25203F),
    appBar: AppBar(
      backgroundColor: const Color(0xFF25203F),
      foregroundColor: const Color(0xFFFFF4E8),
      title: const Text(
        'Ghost Wardrobe',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF25203F), Color(0xFF49365D)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                children: [
                  const Text(
                    'A little dress-up. A lot of boo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFE8CA),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'All three costumes are free and ready to wear.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFFDFCEE9)),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 840
                          ? 3
                          : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                      final cardWidth =
                          (constraints.maxWidth - (columns - 1) * 16) / columns;
                      return ValueListenableBuilder<GhostCostume>(
                        valueListenable: wardrobe,
                        builder: (_, selected, _) => Wrap(
                          spacing: 16,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final costume in GhostCostume.values)
                              SizedBox(
                                width: cardWidth,
                                child: _card(costume, selected == costume),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _card(GhostCostume costume, bool selected) => Semantics(
    button: true,
    selected: selected,
    label: costume.label,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x44FFC598),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: selected ? const Color(0xFF564066) : const Color(0xFF3B304F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            width: 2,
            color: selected ? const Color(0xFFFFCC95) : const Color(0xFF7C638F),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('costume-${costume.id}'),
          onTap: () => unawaited(wardrobe.select(costume)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'FREE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFBCE8D4),
                    ),
                  ),
                ),
                GhostPortrait(
                  costume: costume,
                  height: 210,
                  width: 240,
                  maxGhostSize: 145,
                ),
                Text(
                  costume.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFF4E8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  costume.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFDFCEE9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 20,
                      color: const Color(0xFFFFCC95),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selected ? 'Selected' : 'Tap to wear',
                      style: const TextStyle(
                        color: Color(0xFFFFCC95),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
