import 'package:timeago/timeago.dart';

/// Esperanto locale messages for the timeago package.
class EoMessages implements LookupMessages {
  @override
  String prefixAgo() => 'antaŭ';
  @override
  String prefixFromNow() => 'post';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => 'momento';
  @override
  String aboutAMinute(int minutes) => 'ĉirkaŭ minuto';
  @override
  String minutes(int minutes) => '$minutes minutoj';
  @override
  String aboutAnHour(int minutes) => 'ĉirkaŭ horo';
  @override
  String hours(int hours) => '$hours horoj';
  @override
  String aDay(int hours) => 'ĉirkaŭ tago';
  @override
  String days(int days) => '$days tagoj';
  @override
  String aboutAMonth(int days) => 'ĉirkaŭ monato';
  @override
  String months(int months) => '$months monatoj';
  @override
  String aboutAYear(int year) => 'ĉirkaŭ jaro';
  @override
  String years(int years) => '$years jaroj';
  @override
  String wordSeparator() => ' ';
}
