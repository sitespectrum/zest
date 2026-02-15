import 'package:flutter/material.dart';

class CustomSelectorButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onPressed;
  final Color activeColor;
  final IconData iconData;

  const CustomSelectorButton({
    super.key,
    required this.isSelected,
    required this.onPressed,
    required this.activeColor,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = activeColor;
    return SizedBox(
      height: 70,
      width: double.infinity,
      child: Center(
        child: GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isSelected ? 70 : 65,
            width: isSelected ? 70 : 65,
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColor
                  : const Color.fromARGB(255, 45, 45, 45),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: selectedColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Center(child: Icon(iconData)),
          ),
        ),
      ),
    );
  }
}
