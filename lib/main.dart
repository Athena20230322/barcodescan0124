import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BarcodeScannerPage(),
    );
  }
}
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}
class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String _barcodeData = '';
  File? _file; // 儲存檔案的變數
  String? _fileName; // 儲存檔案名稱
  @override
  void initState() {
    super.initState();
    _requestPermissions(); // 在初始化時請求權限
  }
  // 請求存儲權限
  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      print("Storage permission granted.");
    } else {
      print("Storage permission denied.");
    }
  }
  // 掃描條碼
  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        setState(() {
          _barcodeData = result.rawContent;
        });
        await _saveToFile(result.rawContent); // 儲存條碼數據
      }
    } catch (e) {
      setState(() {
        _barcodeData = '掃描失敗: $e';
      });
    }
  }
  // 儲存條碼數據到檔案
  Future<void> _saveToFile(String data) async {
    try {
      // 獲取內部儲存空間中的 Download 資料夾路徑
      final directory = Directory('/storage/emulated/0/Download');
      // 確認資料夾是否存在
      if (!directory.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法訪問 Download 資料夾')),
        );
        return;
      }
      // 如果檔案名稱尚未生成，則以當前日期時間生成檔案名稱
      if (_fileName == null) {
        final now = DateTime.now();
        _fileName = 'barcode${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.txt';
        _file = File('${directory.path}/$_fileName');
      }
      // 如果檔案尚未建立，則創建
      if (!(_file?.existsSync() ?? false)) {
        await _file?.create();
      }
      // 追加寫入數據
      await _file?.writeAsString('$data\n', mode: FileMode.append);
      // 顯示已保存的提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('條碼已保存到 Download 資料夾: $_fileName')),
      );
    } catch (e) {
      // 如果儲存失敗，顯示錯誤提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('條碼掃描器'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _barcodeData.isEmpty ? '尚未掃描條碼' : '掃描結果: \n\n$_barcodeData',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scanBarcode, // 按鈕點擊後啟動條碼掃描
              child: const Text('掃描條碼'),
            ),
          ],
        ),
      ),
    );
  }
}