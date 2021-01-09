import 'dart:math';
import 'package:intl/intl.dart';

num removeDecimalZero(double n) {
  String result = n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 1);
  return num.parse(result);
}

List parseHistory(txs) {
  var transBC = [];
  int i = 0;

  final currentBase = 0;
  double currentUD = 10.54;

  for (final trans in txs) {
    var direction = trans['direction'];
    final transaction = trans['node'];
    var output = transaction['outputs'][0];

    transBC.add(i);
    transBC[i] = [];
    final dateBrut =
        DateTime.fromMillisecondsSinceEpoch(transaction['writtenTime'] * 1000);
    final DateFormat formatter = DateFormat('dd-MM-yy - HH:mm');
    final date = formatter.format(dateBrut);
    transBC[i].add(transaction['writtenTime']);
    transBC[i].add(date);
    print(
        "DEBUG date et comment: ${date.toString()} -- ${transaction['comment'].toString()}");
    int amountBrut = int.parse(output.split(':')[0]);
    final base = int.parse(output.split(':')[1]);
    final int applyBase = base - currentBase;
    final num amount = removeDecimalZero(amountBrut * pow(10, applyBase) / 100);
    num amountUD = amount / currentUD;
    int padNbr = 14 - amount.toString().length;
    if (direction == "RECEIVED") {
      transBC[i].add(transaction['issuers'][0]);
      transBC[i].add('  ' + amount.toString().padRight(padNbr));
      transBC[i].add(amountUD.toStringAsFixed(2));
    } else if (direction == "SENT") {
      final outPubkey = output.split("SIG(")[1].replaceAll(')', '');
      transBC[i].add(outPubkey);
      transBC[i].add('  -' + amount.toString().padRight(padNbr - 1));
      transBC[i].add(amountUD.toStringAsFixed(2));
    }
    transBC[i].add(transaction['comment']);

    i++;
  }

  // transBC.sort((b, a) => Comparable.compare(a[0], b[0]));
  return transBC;
}
