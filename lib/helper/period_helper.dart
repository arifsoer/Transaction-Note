import 'package:flutter/material.dart';

class PeriodHelper {
  /// Calculates the start and end dates of the period.
  /// [startDay] is the day of the month the period starts (1-28).
  /// [currentDate] is the reference date.
  /// [monthOffset] is used to navigate previous/next periods.
  static DateTimeRange calculatePeriod(int startDay, DateTime currentDate, {int monthOffset = 0}) {
    // Determine the base month and year
    int baseYear = currentDate.year;
    int baseMonth = currentDate.month;

    // If current day is less than the startDay, the current period actually started last month.
    if (currentDate.day < startDay) {
      baseMonth -= 1;
    }

    // Apply the offset
    baseMonth += monthOffset;

    // Adjust year/month if month goes out of bounds (e.g. < 1 or > 12)
    // DateTime handles out-of-bounds months automatically.
    
    DateTime startDate = DateTime(baseYear, baseMonth, startDay);
    
    // End date is exactly one month minus one day from the start date, or up to the startDay of the next month minus 1 day.
    // It's easier to say: start date of the NEXT period, minus 1 millisecond (or 1 day).
    DateTime nextStartDate = DateTime(baseYear, baseMonth + 1, startDay);
    DateTime endDate = nextStartDate.subtract(const Duration(days: 1));

    // To ensure full coverage of the day, endDate should be at 23:59:59
    endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return DateTimeRange(start: startDate, end: endDate);
  }
}
