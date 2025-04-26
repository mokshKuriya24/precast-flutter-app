import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQRPage extends StatefulWidget {
  const ScanQRPage({Key? key}) : super(key: key);

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  Map<String, dynamic>? componentData;
  bool isFetching = false;
  bool isStatusChanged = false;
  String? newStatus;

  Future<void> fetchComponentDetails(String componentId) async {
    setState(() {
      isFetching = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Pre-Cast Components')
          .doc(componentId)
          .get();

      if (doc.exists) {
        setState(() {
          componentData = doc.data();
          isFetching = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Component not found!')),
        );
        setState(() {
          isFetching = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching component: $e')),
      );
      setState(() {
        isFetching = false;
      });
    }
  }

  Future<void> updateStatus(String componentId) async {
    if (newStatus == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('Pre-Cast Components')
          .doc(componentId)
          .update({'Current_Status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully!')),
      );

      // Refresh component data after updating
      fetchComponentDetails(componentId);
      setState(() {
        isStatusChanged = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: isFetching
          ? const Center(child: CircularProgressIndicator())
          : componentData == null
              ? MobileScanner(
                  onDetect: (capture) {
                    if (capture.barcodes.isNotEmpty) {
                      final barcode = capture.barcodes.first;
                      final String? code = barcode.rawValue;
                      if (code != null) {
                        fetchComponentDetails(code);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to scan QR code')),
                        );
                      }
                    }
                  },
                )
              : buildComponentDetails(),
      floatingActionButton: componentData != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  componentData = null;
                  newStatus = null;
                  isStatusChanged = false;
                });
              },
              child: const Icon(Icons.camera_alt),
            )
          : null,
    );
  }

  Widget buildComponentDetails() {
    if (componentData == null) {
      return const Center(child: Text('No component scanned.'));
    }

    final componentId = componentData!['Component_ID'] ?? '';
    final componentType = componentData!['Component_Type'] ?? '';
    final manufacturingDate = componentData!['Manufacturing_Date'] ?? '';
    final factoryLocation = componentData!['Factory_Location'] ?? '';
    final currentStatus = componentData!['Current_Status'] ?? '';
    final destination = componentData!['Destination'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDetailRow('Component ID', componentId),
              buildDetailRow('Component Type', componentType),
              buildDetailRow('Manufacturing Date', manufacturingDate),
              buildDetailRow('Factory Location', factoryLocation),
              buildDetailRow('Current Status', currentStatus),
              buildDetailRow('Destination', destination),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "Update Status",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: newStatus ?? currentStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: ['Manufactured', 'Delivered', 'Assembled']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    newStatus = value;
                    isStatusChanged = (newStatus != currentStatus);
                  });
                },
              ),
              const SizedBox(height: 20),
              if (isStatusChanged)
                ElevatedButton(
                  onPressed: () => updateStatus(componentId),
                  child: const Text('Submit'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(
                "$label:",
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
          Expanded(
              flex: 5,
              child: Text(
                value,
                style: const TextStyle(fontSize: 16),
              )),
        ],
      ),
    );
  }
}
