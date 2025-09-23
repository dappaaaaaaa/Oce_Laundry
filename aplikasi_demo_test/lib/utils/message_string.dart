import 'package:intl/intl.dart';

String generateOrderMessageText({
  required Map<String, dynamic> order,
  required List<Map<String, dynamic>> items,
  required String status,
}) {
  String divider = "--" * 15;
  String formatTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
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
        '${transactionDate.year.toString().substring(2)}${transactionDate.day.toString().padLeft(2, '0')}${transactionDate.month.toString().padLeft(2, '0')}';
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
  final transactionDate = DateTime.fromMillisecondsSinceEpoch(
    order['transaction_time'],
  );
  final orderId = order['id'] as int;
  final orderNumber = generateOrderNumber(transactionDate, orderId);
  final paymentStatus = order['is_payment_complete'].toString();
  final status = statusMap[order['is_order_complete'].toString()] ?? 'Unknown';
  final metodePembayaran = () {
    switch (order['payment_method'].toString()) {
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

  final total = order['total'] ?? 0;
  final bayar = order['total_payment'] ?? 0;
  final kembalian = bayar - total;

  if (status == 'Antrian') {
    final buffer = StringBuffer();
    buffer.writeln('Qlaundry');
    buffer.writeln('Jl. Tani, Bukit Batu Singkawang');
    buffer.writeln(divider);
    buffer.writeln('No Pemesanan: *${breakDigits(orderNumber)}*');
    buffer.writeln('Tanggal: ${formatTime(order['transaction_time'])}');
    buffer.writeln('Nama Pelanggan: ${order['customer_name']}');
    buffer.writeln('Nomor HP: 0${breakDigits(order['phone_number'])}');
    buffer.writeln('Kasir: ${order['cashier_name']}');
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
    buffer.writeln("QTY: ${order['total_item']}");
    buffer.writeln('Subtotal: ${formatCurrency(order['sub_total'])}');
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
Selamat ${generateTime()} ${order['customer_name']}
Laundry anda dengan nomor Pemesanan *${breakDigits(orderNumber)}* 
Sudah selesai dan sudah bisa diambil\n
Terima kasih telah menggunakan layanan kami!
''';
  } else {
    return '';
  }
}
