import 'package:aplikasi_demo_test/database/order.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

// *Fungsi untuk format angka menjadi mata uang Indonesia
String formatCurrency(num number) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(number);
}

// *Fungsi untuk format angka dengan pemisah ribuan
String formatNumber(num value) {
  return NumberFormat.decimalPattern('id_ID').format(value);
}

// *Fungsi untuk menghasilkan nomor pemesanan berdasarkan tanggal transaksi dan ID pesanan
String generateOrderNumber(DateTime transactionDate, int orderId) {
  final datePart =
      '${transactionDate.year.toString().substring(2)}${transactionDate.day.toString().padLeft(2, '0')}${transactionDate.month.toString().padLeft(2, '0')}';
  final idPart = orderId.toString().padLeft(3, '0');
  return '$datePart$idPart';
}

// *Fungsi untuk mencetak struk laundry menggunakan printer thermal Bluetooth
Future<void> cetakStrukLaundryEscPos({
  required Order order,
  required List<Map<String, dynamic>> items,
}) async {
  final bool isConnected = await PrintBluetoothThermal.connectionStatus;

  if (!isConnected) {
    print("Printer belum terhubung.");
    return;
  }

  // parse tanggal
  final transactionDate = DateTime.parse(order.transactionTime.toString());

  final orderNumber = generateOrderNumber(transactionDate, order.id);

  final profile = await CapabilityProfile.load();

  final generator = Generator(PaperSize.mm58, profile);

  List<int> bytes = [];

  // payment method
  final paymentMethod = () {
    switch (order.paymentMethod.toString()) {
      case '0':
        return 'Cash';

      case '1':
        return 'QRIS';

      case '2':
        return 'Belum Lunas';

      default:
        return 'Tidak diketahui';
    }
  }();

  // =========================
  // HEADER
  // =========================

  bytes += generator.text(
    'QLaundry',
    styles: PosStyles(
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    ),
    linesAfter: 1,
  );

  bytes += generator.text(
    'Jl. Tani, Bukit Batu Singkawang\n'
    'Telp: 0895-3283-64478',
    styles: PosStyles(align: PosAlign.center),
  );

  bytes += generator.hr();

  // =========================
  // INFO ORDER
  // =========================

  bytes += generator.row([
    PosColumn(text: "No. Pemesanan", width: 6),
    PosColumn(
      text: orderNumber,
      width: 6,
      styles: PosStyles(align: PosAlign.right),
    ),
  ]);

  bytes += generator.row([
    PosColumn(text: "Tanggal", width: 6),
    PosColumn(
      text: DateFormat('dd/MM/yyyy').format(transactionDate),
      width: 6,
      styles: PosStyles(align: PosAlign.right),
    ),
  ]);

  bytes += generator.row([
    PosColumn(text: "Pelanggan", width: 6),
    PosColumn(
      text: order.customerName,
      width: 6,
      styles: PosStyles(align: PosAlign.right),
    ),
  ]);

  bytes += generator.row([
    PosColumn(text: "Kasir", width: 6),
    PosColumn(
      text: order.cashierName,
      width: 6,
      styles: PosStyles(align: PosAlign.right),
    ),
  ]);

  bytes += generator.hr();

  // =========================
  // ITEM
  // =========================

  for (final item in items) {
    final String name = item['product_name'] ?? '';

    final num weight = item['weight'] ?? 0;

    final num price = item['price'] ?? 0;

    final num total = weight * price;

    bytes += generator.text(name, styles: PosStyles(align: PosAlign.left));

    bytes += generator.row([
      PosColumn(text: '$weight Kg X ${formatNumber(price)}', width: 6),
      PosColumn(
        text: formatCurrency(total),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
  }

  bytes += generator.hr();

  // =========================
  // TOTAL
  // =========================

  bytes += generator.row([
    PosColumn(text: "QTY", width: 6),
    PosColumn(
      text: order.totalItem.toString(),
      width: 6,
      styles: PosStyles(align: PosAlign.right),
    ),
  ]);

  bytes += generator.row([
    PosColumn(text: "Sub total", width: 6),
    PosColumn(
      text: formatCurrency(order.subTotal),
      width: 6,
      styles: PosStyles(align: PosAlign.right),
    ),
  ]);

  bytes += generator.row([
    PosColumn(text: "Total", width: 6),
    PosColumn(
      text: formatCurrency(order.total),
      width: 6,
      styles: PosStyles(align: PosAlign.right),
    ),
  ]);

  bytes += generator.row([
    PosColumn(text: "BAYAR ($paymentMethod)", width: 6),
    PosColumn(
      text: formatCurrency(order.totalPayment),
      width: 6,
      styles: PosStyles(align: PosAlign.right),
    ),
  ]);

  final int kembalian = order.totalPayment - order.total;

  if (order.isPaymentComplete == 1) {
    bytes += generator.row([
      PosColumn(text: "Kembalian", width: 6),
      PosColumn(
        text: formatCurrency(kembalian),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
  }

  bytes += generator.hr();

  bytes += generator.feed(1);

  bytes += generator.text(
    'Terima kasih telah menggunakan\n'
    'jasa laundry kami.',
    styles: PosStyles(align: PosAlign.center),
    linesAfter: 2,
  );

  await PrintBluetoothThermal.writeBytes(bytes);
}
