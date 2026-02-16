import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connect/models/promotion.dart';
import 'package:connect/components/promotion_carousel.dart';

class PromotionPopup extends StatefulWidget {
  final List<Promotion> promotions;
  final Function(Promotion) onTap;
  final Duration autoDismissDuration;

  const PromotionPopup({
    super.key,
    required this.promotions,
    required this.onTap,
    this.autoDismissDuration = const Duration(seconds: 30),
  });

  @override
  State<PromotionPopup> createState() => _PromotionPopupState();

  static bool _hasBeenShown = false;

  static void resetShownFlag() {
    _hasBeenShown = false;
  }

  static void show(BuildContext context, List<Promotion> promotions,
      Function(Promotion) onTap) {
    if (_hasBeenShown) return;
    _hasBeenShown = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PromotionPopup(
        promotions: promotions,
        onTap: (promo) {
          Navigator.pop(context);
          onTap(promo);
        },
      ),
    );
  }
}

class _PromotionPopupState extends State<PromotionPopup> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _startDismissTimer();
  }

  void _startDismissTimer() {
    if (widget.autoDismissDuration.inSeconds > 0) {
      _dismissTimer = Timer(widget.autoDismissDuration, () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: PromotionCarousel(
              promotions: widget.promotions,
              onTap: widget.onTap,
            ),
          ),
          // Close Icon
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
