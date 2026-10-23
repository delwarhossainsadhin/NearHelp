import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class PaymentScreen extends StatefulWidget {
  final String taskId;
  final double amount;
  final String providerName;

  const PaymentScreen({
    super.key,
    required this.taskId,
    required this.amount,
    required this.providerName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedMethod = 'bKash';
  bool _isProcessing = false;
  final TextEditingController _pinController = TextEditingController();

  String _generateTransactionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(10, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  void _processPayment() async {
    if (_pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid PIN')),
      );
      return;
    }

    setState(() => _isProcessing = true);


    await Future.delayed(const Duration(seconds: 2));

    try {
      String trxId = _generateTransactionId();
      

      await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
        'paymentStatus': 'paid',
        'transactionId': trxId,
      });

      // Add a notification for the provider
      final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).get();
      final providerId = taskDoc.data()?['acceptedBy'];
      
      if (providerId != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': providerId,
          'title': 'Payment Received!',
          'body': 'You have received ৳${widget.amount} for task: ${taskDoc.data()?['title']}. TrxID: $trxId',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Payment Successful!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('TrxID: $trxId'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 16)),
                    Text('৳${widget.amount}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Paying to:'),
                        Text(widget.providerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _methodIcon('bKash', 'https://logos-download.com/wp-content/uploads/2022/01/BKash_Logo.png'),
                const SizedBox(width: 16),
                _methodIcon('Nagad', 'https://logos-download.com/wp-content/uploads/2022/01/Nagad_Logo.png'),
              ],
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter $selectedMethod PIN',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedMethod == 'bKash' ? Colors.pink : Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text('Pay ৳${widget.amount} Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodIcon(String method, String url) {
    bool isSelected = selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = method),
      child: Container(
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.deepPurple : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Center(
          child: Text(method, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.deepPurple : Colors.grey)),
        ),
      ),
    );
  }
}
