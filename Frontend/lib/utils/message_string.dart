import 'package:aplikasi_demo_test/database/order.dart';
import 'package:intl/intl.dart';

String generateOrderMessageText({
  required Order order,
  required List<Map<String, dynamic>> items,
  required String status,
}) {
  String divider = "--" * 15;
  String formatTime(String datetime) {
    final date = DateTime.parse(datetime);

    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // * Fungsi untuk menentukan waktu berdasarkan jam saat ini
  String generateTime() {
    final hourNow = DateTime.now().hour;
    if (hourNow >= 4 && hourNow <= 11) {
      return "pagi";
    } else if (hourNow >= 12 && hourNow <= 14) {
      return "siang";
    } else if (hourNow >= 15 && hourNow <= 16) {
      return "sore";
    } else {
      return "malam";
    }
  }

  // * Fungsi untuk menghasilkan nomor pemesanan berdasarkan tanggal transaksi dan ID order
  String generateOrderNumber(DateTime transactionDate, int orderId) {
    final datePart =
        '${transactionDate.year.toString().substring(2)}'
        '${transactionDate.day.toString().padLeft(2, '0')}'
        '${transactionDate.month.toString().padLeft(2, '0')}';

    final idPart = orderId.toString().padLeft(3, '0');

    return '$datePart$idPart';
  }

  // * Fungsi untuk memecah string input menjadi potongan 3 karakter dengan karakter nol-width space
  String breakDigits(String input) {
    return input.replaceAllMapped(
      RegExp(r".{3}"),
      (match) => "${match.group(0)}\u200B",
    );
  }

  // * Fungsi untuk memformat angka menjadi string mata uang Indonesia
  String formatCurrency(num number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  // * Map status order ke string yang lebih mudah dibaca
  final statusMap = {
    '0': 'Antrian',
    '1': 'Diproses',
    '2': 'Siap diambil',
    '3': 'Selesai',
  };

  final orderNumber = generateOrderNumber(
    DateTime.parse(order.transactionTime.toString()),
    order.id,
  );
  final paymentStatus = order.isPaymentComplete.toString();
  final status = statusMap[order.isOrderComplete.toString()] ?? 'Unknown';
  final metodePembayaran = () {
    switch (order.paymentMethod.toString()) {
      case '0':
        return 'Cash';
      case '1':
        return 'QRIS';
      case '2':
        return 'Belum Bayar';
      default:
        return 'Tidak diketahui';
    }
  }();

  final total = order.total;
  final bayar = order.totalPayment;
  final kembalian = bayar - total;

  if (status == 'Antrian' || status == 'Diproses') {
    final buffer = StringBuffer();
    buffer.writeln('Qlaundry');
    buffer.writeln('Jl. Tani, Bukit Batu Singkawang');
    buffer.writeln(divider);
    buffer.writeln('No Pemesanan: *${breakDigits(orderNumber)}*');
    buffer.writeln('Tanggal: ${formatTime(order.transactionTime)}');
    buffer.writeln('Nama Pelanggan: ${order.customerName}');
    buffer.writeln('Nomor HP: 0${breakDigits(order.phoneNumber.toString())}');
    buffer.writeln('Kasir: ${order.cashierName}');
    buffer.writeln('Metode Pembayaran: *$metodePembayaran*');
    buffer.writeln(divider);
    buffer.writeln('Daftar Produk:');
    for (final item in items) {
      final itemTotal = (item['weight'] ?? 0) * (item['price'] ?? 0);
      buffer.writeln('- ${item['product_name']}');
      buffer.writeln(
        '  ${item['weight']} Kg x ${formatCurrency(item['price'])} = ${formatCurrency(itemTotal)}',
      );
    }
    buffer.writeln(divider);
    buffer.writeln("QTY: ${order.totalItem}");
    buffer.writeln('Subtotal: ${formatCurrency(order.subTotal)}');
    buffer.writeln('Total: ${formatCurrency(total)}');
    buffer.writeln('Bayar: ${formatCurrency(bayar)}');
    if (paymentStatus == '1') {
      buffer.writeln('Kembalian: ${formatCurrency(kembalian)}');
    } else {
      buffer.writeln("");
    }
    buffer.writeln('');
    buffer.writeln('Terima kasih telah memesan di laundry kami.');

    return buffer.toString();
  } else if (status == 'Siap diambil') {
    return '''
Selamat ${generateTime()} ${order.customerName}
Laundry anda dengan nomor Pemesanan *${breakDigits(orderNumber)}* 
Sudah selesai dan sudah bisa diambil\n
Terima kasih telah menggunakan layanan kami!
''';
  } else {
    return '';
  }
}
