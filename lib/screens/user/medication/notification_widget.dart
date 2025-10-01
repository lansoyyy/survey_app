import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:survey_app/utils/colors.dart';
import 'package:survey_app/widgets/text_widget.dart';
import 'package:survey_app/widgets/button_widget.dart';
import 'package:survey_app/services/medication_service.dart';
import 'notification_frequency_dialog.dart';

class NotificationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(String) onClear;
  final Function(String, TimeOfDay)? onSetFrequency;
  final MedicationService medicationService;

  const NotificationWidget({
    super.key,
    required this.notifications,
    required this.onClear,
    this.onSetFrequency,
    required this.medicationService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (onSetFrequency != null)
              ButtonWidget(
                label: 'Set Frequency',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => NotificationFrequencyDialog(
                      initialFrequency: 'Daily',
                      initialTime: TimeOfDay.now(),
                      onSave: (frequency, time) {
                        onSetFrequency?.call(frequency, time);
                      },
                    ),
                  );
                },
                width: 120,
                fontSize: 12,
                height: 36,
                color: primaryLight,
                textColor: textPrimary,
              ),
            if (notifications.isNotEmpty) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: TextWidget(
                        text: 'Clear All Notifications',
                        fontSize: 18,
                        color: textPrimary,
                        fontFamily: 'Bold',
                      ),
                      content: TextWidget(
                        text:
                            'Are you sure you want to clear all notifications?',
                        fontSize: 16,
                        color: textSecondary,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: TextWidget(
                            text: 'Cancel',
                            fontSize: 16,
                            color: primary,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            for (var notification in notifications) {
                              // Cancel the scheduled notification
                              await medicationService
                                  .cancelScheduledNotification(
                                      notification['id']);
                              // Clear from local storage
                              onClear(notification['id']);
                            }
                            Navigator.of(context).pop();
                          },
                          child: TextWidget(
                            text: 'Clear All',
                            fontSize: 16,
                            color: healthRed,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: TextWidget(
                  text: 'Clear All',
                  fontSize: 14,
                  color: primary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (notifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 48,
                    color: textLight,
                  ),
                  const SizedBox(height: 12),
                  TextWidget(
                    text: 'No notifications',
                    fontSize: 16,
                    color: textLight,
                  ),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'Your notifications will appear here',
                    fontSize: 14,
                    color: textLight,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Dismissible(
                  key: Key(notification['id']),
                  background: Container(
                    decoration: BoxDecoration(
                      color: healthRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    // Cancel the scheduled notification
                    await medicationService
                        .cancelScheduledNotification(notification['id']);
                    // Clear from local storage
                    onClear(notification['id']);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Notification icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification['type'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _getNotificationIcon(notification['type']),
                        ),

                        const SizedBox(width: 12),

                        // Notification content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: notification['title'],
                                fontSize: 16,
                                color: textPrimary,
                                fontFamily: 'Medium',
                              ),
                              const SizedBox(height: 4),
                              TextWidget(
                                text: notification['message'],
                                fontSize: 14,
                                color: textSecondary,
                              ),
                              if (notification['frequency'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.repeat,
                                      size: 14,
                                      color: textLight,
                                    ),
                                    const SizedBox(width: 4),
                                    TextWidget(
                                      text:
                                          '${notification['frequency']} at ${notification['time'] ?? '12:00 PM'}',
                                      fontSize: 12,
                                      color: textLight,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextWidget(
                              text: DateFormat('hh:mm a').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    notification['timestamp']),
                              ),
                              fontSize: 12,
                              color: textLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Icon _getNotificationIcon(String type) {
    Color color = _getNotificationColor(type);

    switch (type) {
      case 'bp_reading':
        return Icon(Icons.favorite, color: color);
      case 'medication':
        return Icon(Icons.medication, color: color);
      case 'consultation':
        return Icon(Icons.calendar_today, color: color);
      default:
        return Icon(Icons.notifications, color: color);
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'bp_reading':
        return healthRed;
      case 'medication':
        return primary;
      case 'consultation':
        return healthGreen;
      default:
        return textLight;
    }
  }
}
