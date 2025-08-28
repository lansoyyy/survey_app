import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../widgets/text_widget.dart';

class CoffeeShopDetailsBottomSheet extends StatelessWidget {
  final String name;
  final String location;
  final String hours;
  final String rating;

  const CoffeeShopDetailsBottomSheet({
    super.key,
    required this.name,
    required this.location,
    required this.hours,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Location header
          Center(
            child: TextWidget(
              text: location,
              fontSize: 16,
              color: Colors.white,
              isBold: true,
            ),
          ),

          const SizedBox(height: 25),

          // Coffee shop image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Placeholder image
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.white38, size: 50),
                    ),
                  ),

                  // Overlay with coffee shop name
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: name,
                            fontSize: 24,
                            color: Colors.white,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Rating badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.bookmark_border,
                          color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Coffee shop details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: name,
                      fontSize: 20,
                      color: Colors.white,
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: hours,
                          fontSize: 14,
                          color: Colors.grey[400]!,
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        TextWidget(
                          text: rating,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: primary,
                  child: const Icon(
                    Icons.local_cafe,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String name,
    required String location,
    required String hours,
    required String rating,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CoffeeShopDetailsBottomSheet(
        name: name,
        location: location,
        hours: hours,
        rating: rating,
      ),
    );
  }
}
