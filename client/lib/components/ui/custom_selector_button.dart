import 'package:flutter/material.dart';

class CustomSelectorButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onPressed;

  const CustomSelectorButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 60, // Egységes magasság
          decoration: BoxDecoration(
            // Ha kiválasztott: Zöld (App téma), Ha nem: Sötétszürke
            color: isSelected 
                ? const Color.fromARGB(255, 85, 173, 78) 
                : const Color.fromARGB(255, 45, 45, 45),
            borderRadius: BorderRadius.circular(16), // Kerekített sarkok (mint a kártyáknál)
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white24,
              width: 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color.fromARGB(255, 85, 173, 78).withOpacity(0.4),
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
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}