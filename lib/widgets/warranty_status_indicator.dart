import 'package:flutter/material.dart';

class WarrantyStatusIndicator extends StatelessWidget {
  final String? warrantyExpiry;
  final DateTime currentDate;

  const WarrantyStatusIndicator({
    Key? key,
    this.warrantyExpiry,
    required this.currentDate,
  }) : super(key: key);

  int _getActiveIndex() {
    if (warrantyExpiry == null || warrantyExpiry!.isEmpty) {
      return -1; // Case 4: No warranty (All grey)
    }

    final expiryDate = DateTime.tryParse(warrantyExpiry!);
    if (expiryDate == null) {
      return -1; // Case 4: Invalid date (All grey)
    }

    if (currentDate.isAfter(expiryDate)) {
      return 2; // Case 3: Expired (Circle 3 highlighted in Red)
    }

    final daysRemaining = expiryDate.difference(currentDate).inDays;
    if (daysRemaining <= 30 && daysRemaining > 0) {
      return 1; // Case 2: Expiring Soon (Circle 2 highlighted in Yellow/Amber)
    }

    if (daysRemaining > 30) {
      return 0; // Case 1: Active Warranty (Circle 1 highlighted in Green)
    }

    return -1;
  }

  Color _getCircleColor(int index, int activeIndex) {
    if (activeIndex == index) {
      switch (index) {
        case 0:
          return const Color(0xFF00FF66); // Bright Green
        case 1:
          return const Color(0xFFFFB300); // Amber / Yellow
        case 2:
          return const Color(0xFFFF3333); // Bright Red
      }
    }
    return Colors.grey.withOpacity(0.4); // Inactive 40% Opacity Grey
  }

  List<BoxShadow>? _getCircleGlow(int index, int activeIndex) {
    if (activeIndex == index) {
      final Color glowColor = _getCircleColor(index, activeIndex);
      return [
        BoxShadow(
          color: glowColor.withOpacity(0.4),
          blurRadius: 6,
          spreadRadius: 1,
        )
      ];
    }
    return null;
  }

  double _getCircleScale(int index, int activeIndex) {
    return activeIndex == index ? 1.2 : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _getActiveIndex();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final double scale = _getCircleScale(index, activeIndex);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: scale),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getCircleColor(index, activeIndex),
                    boxShadow: _getCircleGlow(index, activeIndex),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
