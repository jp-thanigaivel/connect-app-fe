import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connect/models/promotion.dart';
import 'package:connect/components/promotion_banner.dart';

class PromotionCarousel extends StatefulWidget {
  final List<Promotion> promotions;
  final Function(Promotion) onTap;
  final bool isCompact;
  final bool autoScroll;

  const PromotionCarousel({
    super.key,
    required this.promotions,
    required this.onTap,
    this.isCompact = false,
    this.autoScroll = true,
  });

  @override
  State<PromotionCarousel> createState() => _PromotionCarouselState();
}

class _PromotionCarouselState extends State<PromotionCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  // Large number to simulate infinite scrolling
  static const int _infiniteCount = 10000;

  @override
  void initState() {
    super.initState();
    // Start in the middle of the infinite scroll to allow scrolling both ways
    _currentPage = _infiniteCount ~/ 2;
    _pageController = PageController(initialPage: _currentPage);

    if (widget.autoScroll) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.promotions.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.isCompact
              ? 86
              : 220, // Adjust based on PromotionBanner height
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final promotion =
                  widget.promotions[index % widget.promotions.length];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: PromotionBanner(
                  promotion: promotion,
                  onTap: () => widget.onTap(promotion),
                  isCompact: widget.isCompact,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        // Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.promotions.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (index == _currentPage % widget.promotions.length)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
