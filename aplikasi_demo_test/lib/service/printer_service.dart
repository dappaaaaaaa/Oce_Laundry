import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;

  PrinterService._internal();

  bool connected = false;
  String? connectedMac;

  // * Fungsi untuk mendapatkan daftar perangkat Bluetooth yang sudah terpasang
  Future<List<BluetoothInfo>> getBondedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  // *Fungsi untuk menghubungkan ke printer Bluetooth
  Future<bool> connect(String macAddress) async {
    final result = await PrintBluetoothThermal.connect(
      macPrinterAddress: macAddress,
    );
    connected = result;
    if (result) connectedMac = macAddress;
    return result;
  }

  // *Fungsi untuk memutuskan koneksi printer Bluetooth
  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    connected = false;
    connectedMac = null;
  }

  // *Fungsi untuk mengecek status koneksi printer Bluetooth
  Future<bool> isConnected() async {
    connected = await PrintBluetoothThermal.connectionStatus;
    return connected;
  }
}
