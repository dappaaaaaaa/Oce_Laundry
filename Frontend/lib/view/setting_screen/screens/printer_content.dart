import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:aplikasi_demo_test/service/printer_service.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class PrinterContent extends StatefulWidget {
  const PrinterContent({super.key});

  @override
  State<PrinterContent> createState() => _PrinterContentState();
}

class _PrinterContentState extends State<PrinterContent> {
  final printerService = PrinterService();

  List<BluetoothInfo> bluetoothItems = [];
  bool _progress = false;
  String _msj = "";
  String _msjprogress = "";
  Widget _infoBluetooth = Icon(Icons.media_bluetooth_off, color: Colors.red);
  String _infoConnection = "";
  bool connected = false;

  @override
  void initState() {
    super.initState();
    _loadBluetoothStatus();
    _getBondedDevices();
  }

  // * Memuat status Bluetooth dan koneksi saat widget diinisialisasi
  Future<void> _loadBluetoothStatus() async {
    bool enabled = await PrintBluetoothThermal.bluetoothEnabled;
    bool connection = await PrintBluetoothThermal.connectionStatus;

    setState(() {
      _infoBluetooth =
          enabled
              ? Icon(ZondIcons.bluetooth, color: Colors.blue)
              : Icon(Clarity.bluetooth_off_solid, color: Colors.red);
      _infoConnection =
          "Status Koneksi Bluetooth: ${connection ? "Tersambung" : "Tidak Tersambung"}";
      connected = connection;
    });
  }

  // * Mendapatkan perangkat Bluetooth yang terhubung
  Future<void> _getBondedDevices() async {
    setState(() {
      _progress = true;
      _msjprogress = "\tMemuat";
    });

    List<BluetoothInfo> devices = await printerService.getBondedDevices();

    setState(() {
      _progress = false;
      bluetoothItems = devices;
      _msj =
          devices.isEmpty
              ? "Tidak ada printer yang terhubung"
              : "Sentuh salah satu untuk menyambung";
    });
  }

  // * Menghubungkan ke printer Bluetooth berdasarkan alamat MAC
  Future<void> _connect(String mac) async {
    setState(() {
      _progress = true;
      _msjprogress = "\tMenyambungkan";
    });

    bool result = await printerService.connect(mac);

    setState(() {
      connected = result;
      _progress = false;
      _msj = result ? "Printer berhasil terhubung" : "Gagal terhubung";
    });

    _loadBluetoothStatus();
  }

  // * Memutuskan sambungan dari printer Bluetooth
  Future<void> _disconnect() async {
    await printerService.disconnect();
    setState(() {
      connected = false;
      _msj = "Printer terputus";
    });

    _loadBluetoothStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pengaturan Printer",
          style: TextStyle(
            color: Colors.black,
            fontSize: 50.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.backgroundColorPrimary,
        actions: [
          _infoBluetooth,
          IconButton(
            onPressed: _loadBluetoothStatus,
            icon: const Icon(Icons.refresh, color: AppColor.primary),
          ),
        ],
      ),
      backgroundColor: AppColor.backgroundColorPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_infoConnection),
            const SizedBox(height: 10),
            Text(_msj),
            const SizedBox(height: 10),
            Row(
              children: [

                Expanded(
                  child: SizedBox(
                    height: 60.h,

                    child: ElevatedButton(
                      onPressed: _getBondedDevices,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),

                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                        ),
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          if (_progress)
                            Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: LoadingAnimationWidget.threeArchedCircle(
                                color: Colors.white,
                                size: 18.sp,
                              ),
                            ),

                          Flexible(
                            child: Text(
                              _progress ? _msjprogress : "Cari",

                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          SizedBox(width: 8.w),

                          if (!_progress)
                            Icon(
                              Icons.search,
                              size: 30.sp,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                Expanded(
                  child: SizedBox(
                    height: 60.h,

                    child: ElevatedButton(
                      onPressed: connected ? _disconnect : null,

                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.grey,
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),

                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                        ),
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Flexible(
                            child: Text(
                              "Putuskan Sambungan",

                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          SizedBox(width: 8.w),

                          Icon(
                            Icons.link_off,
                            size: 30.sp,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                itemCount: bluetoothItems.length,
                itemBuilder: (context, index) {
                  final item = bluetoothItems[index];
                  return ListTile(
                    onTap: () => _connect(item.macAdress),
                    leading: const Icon(Icons.print),
                    title: Text("Name: ${item.name}"),
                    subtitle: Text("Mac: ${item.macAdress}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
