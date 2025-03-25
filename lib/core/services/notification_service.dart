import 'package:ev_charging_app/core/models/notification.dart';

class NotificationService {
  List<EVNotification> getDemoNotifications() {
    return [
      EVNotification(
        id: '1',
        title: 'Low Battery Warning',
        message:
            'Your car battery is at 15%. Check nearby EV stations to charge.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: 'warning',
        isRead: false,
        imageUrl: 'assets/images/low_battery.jpeg',
      ),
      EVNotification(
        id: '2',
        title: 'Charging Complete',
        message: 'Your vehicle has been charged to 100%.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: 'success',
        isRead: true,
        imageUrl: 'assets/images/full_battery.jpeg',
      ),
      EVNotification(
        id: '3',
        title: 'New Station Available',
        message:
            'A new charging station has been added near UIR. Check it out!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'info',
        isRead: true,
        imageUrl: 'assets/images/new_station.png',
      ),
      EVNotification(
        id: '4',
        title: 'Maintenance Complete',
        message: 'Your scheduled maintenance has been completed.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: 'info',
        isRead: true,
        imageUrl: 'assets/images/maintenance.png',
      ),
    ];
  }

  int getUnreadCount() {
    return getDemoNotifications().where((n) => !n.isRead).length;
  }
}
