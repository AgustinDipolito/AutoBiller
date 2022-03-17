List<List<DateTime>> getWeeksForRange(DateTime start, DateTime end) {
  var result = <List<DateTime>>[];

  var date = start;
  var week = <DateTime>[];

  while (date.difference(end).inDays <= 0) {
    // start new week on Monday
    if (date.weekday == 1 && week.length > 0) {
      result.add(week);
      week = <DateTime>[];
    }

    week.add(date);

    date = date.add(const Duration(days: 1));
  }

  result.add(week);

  return result;
}
