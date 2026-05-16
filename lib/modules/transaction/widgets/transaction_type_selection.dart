import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stategetx/modules/transaction/transaction_controller.dart';

class TransactionTypeSelector extends GetView<TransactionController> {
  const TransactionTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SegmentedButton<String>(
        segments: [
          ButtonSegment(
            value: 'expense',
            label: const Text('Gider'),
            icon: const Icon(Icons.arrow_upward, color: Colors.red),
          ),
          ButtonSegment(
            value: 'income',
            label: const Text('Gelir'),
            icon: const Icon(Icons.arrow_downward, color: Colors.green),
          ),
          ButtonSegment(
            value: 'card-payment',
            label: const Text('Kart İşlemleri'),
            icon: const Icon(Icons.credit_card, color: Colors.blue),
          ),
        ],
        selected: {controller.operationType.value},
        onSelectionChanged: (newSelection) {
          if (newSelection.isNotEmpty) {
            controller.operationType.value = newSelection.first;
            controller.paymentMethod.value = null;
            controller.selectedCardForPaymentId.value = null;
          }
        },
      ),
    );
  }
}
