import 'package:flutter_test/flutter_test.dart';
import 'package:nokia_fm_tracker/services/ticket_formatters.dart';

void main() {
  test('durationText formats recent durations', () {
    final firstOccurrence = DateTime.now().subtract(const Duration(hours: 2));
    expect(durationText(firstOccurrence), contains('h'));
  });
}
