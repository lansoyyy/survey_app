import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(String) onClear;

  const NotificationWidget({
    super.key,
    required this.notifications,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (notifications.isNotEmpty)
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Notifications'),
                      content: const Text(
                          'Are you sure you want to clear all notifications?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            for (var notification in notifications) {
                              onClear(notification['id']);
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Clear All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (notifications.isEmpty)
          const Center(
            child: Text(
              'No notifications',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
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
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  key: Key(notification['id']),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    onClear(notification['id']);
                  },
                  child: ListTile(
                    leading: _getNotificationIcon(notification['type']),
                    title: Text(notification['title']),
                    subtitle: Text(notification['message']),
                    trailing: Text(
                      DateFormat('hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                            notification['timestamp']),
                      ),
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
    switch (type) {
      case 'bp_reading':
        return const Icon(Icons.favorite, color: Colors.red);
      case 'medication':
        return const Icon(Icons.medication, color: Colors.blue);
      case 'consultation':
        return const Icon(Icons.calendar_today, color: Colors.green);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }
}
