import 'package:flutter_test/flutter_test.dart';
import 'package:physiocare/services/notification_service.dart';

void main() {
  group('NotificationService.isStreakMilestone', () {
    test('returns true for 7, 14, 30', () {
      expect(NotificationService.isStreakMilestone(7), isTrue);
      expect(NotificationService.isStreakMilestone(14), isTrue);
      expect(NotificationService.isStreakMilestone(30), isTrue);
    });

    test('returns false for non-milestone streaks', () {
      expect(NotificationService.isStreakMilestone(1), isFalse);
      expect(NotificationService.isStreakMilestone(5), isFalse);
      expect(NotificationService.isStreakMilestone(10), isFalse);
      expect(NotificationService.isStreakMilestone(31), isFalse);
    });
  });
}
