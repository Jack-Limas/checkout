import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';

class PaymentScreen extends StatefulWidget {
  final double total;

  const PaymentScreen({super.key, required this.total});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<Map<String, dynamic>> cards = [];
  final TextEditingController promoController = TextEditingController();
  double discount = 0;
  int? selectedCardId;

  final Color primaryBlue = const Color(0xFF4A6CF7);
  final Color lightBlue = const Color(0xFF6C8EFF);
  final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    promoController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    final data = await DatabaseHelper.instance.getCards();
    final selectedExists = data.any((card) => card['id'] == selectedCardId);

    setState(() {
      cards = data;
      if (data.isEmpty) {
        selectedCardId = null;
      } else if (!selectedExists) {
        selectedCardId = data.first['id'] as int;
      }
    });
  }

  Future<void> _deleteCard(int id) async {
    await DatabaseHelper.instance.deleteCard(id);
    await _loadCards();
  }

  String _maskCardNumber(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length <= 4) return cleaned;
    return '**** **** **** ${cleaned.substring(cleaned.length - 4)}';
  }

  Future<void> _confirmDeleteCard(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: const Text('Esta accion no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteCard(id);
    }
  }

  Future<void> _editCardDialog(Map<String, dynamic> card) async {
    final number = TextEditingController(text: card['cardNumber'] as String);
    final holder = TextEditingController(text: card['holderName'] as String);
    final expiry = TextEditingController(text: card['expiryDate'] as String);
    final cvv = TextEditingController(text: card['cvv'] as String);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar tarjeta'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: number,
                  decoration: const InputDecoration(labelText: 'Card Number'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final cleaned = (value ?? '').replaceAll(
                      RegExp(r'\s+'),
                      '',
                    );
                    if (cleaned.length < 13 || cleaned.length > 19) {
                      return 'Numero invalido';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: holder,
                  decoration: const InputDecoration(labelText: 'Holder Name'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return 'Nombre requerido';
                    return null;
                  },
                ),
                TextFormField(
                  controller: expiry,
                  decoration: const InputDecoration(labelText: 'Expiry Date'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return 'Fecha requerida';
                    return null;
                  },
                ),
                TextFormField(
                  controller: cvv,
                  decoration: const InputDecoration(labelText: 'CVV'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final safe = (value ?? '').trim();
                    if (safe.length < 3 || safe.length > 4) {
                      return 'CVV invalido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await DatabaseHelper.instance.updateCard(card['id'] as int, {
                'cardNumber': number.text.trim(),
                'holderName': holder.text.trim(),
                'expiryDate': expiry.text.trim(),
                'cvv': cvv.text.trim(),
              });

              if (!mounted) return;
              Navigator.pop(context);
              await _loadCards();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    number.dispose();
    holder.dispose();
    expiry.dispose();
    cvv.dispose();
  }

  Future<void> _applyPromo() async {
    final promoCode = promoController.text.trim().toUpperCase();
    final promo = await DatabaseHelper.instance.validatePromo(promoCode);
    if (!mounted) return;

    if (promo != null) {
      if (widget.total >= promo['minAmount']) {
        setState(() {
          discount = promo['discount'] as double;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promocion aplicada correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No alcanzas el monto minimo')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codigo promocional invalido')),
      );
    }
  }

  Widget _buildPaymentCard(Map<String, dynamic> card) {
    final id = card['id'] as int;
    final selected = selectedCardId == id;

    return GestureDetector(
      onTap: () {
        setState(() => selectedCardId = id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primaryBlue : const Color(0xFFE5E8F2),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFA031), Color(0xFFFF5F5F)],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['holderName'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF303952),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Master Card ending ${_maskCardNumber(card['cardNumber'] as String)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D96AB),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF4A6CF7)),
              onPressed: () => _editCardDialog(card),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDeleteCard(id),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finalTotal = widget.total - discount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Payment', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, lightBlue, const Color(0xFF7A5FFF)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x334A6CF7),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NIKE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '\$50 off',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'On your first order',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '* Promo code valid for orders over \$150',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: cards.isEmpty
                      ? null
                      : () => _editCardDialog(cards.first),
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (cards.isEmpty)
              const Text(
                'No hay tarjetas guardadas',
                style: TextStyle(color: Colors.grey),
              ),
            ...cards.map(_buildPaymentCard),
            const SizedBox(height: 25),
            const Text(
              'Use promo code',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: promoController,
              decoration: InputDecoration(
                hintText: 'PROMO20-08',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE4E8F2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE4E8F2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF9D42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _applyPromo,
                child: const Text('Apply'),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4E8F2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subtotal: ${currency.format(widget.total)}',
                    style: const TextStyle(color: Color(0xFF707B93)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Descuento: - ${currency.format(discount)}',
                    style: const TextStyle(color: Color(0xFF707B93)),
                  ),
                  const Divider(height: 18),
                  Text(
                    'Total: ${currency.format(finalTotal)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryBlue, lightBlue]),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextButton(
                onPressed: selectedCardId == null
                    ? null
                    : () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment successful')),
                        );

                        await Future.delayed(const Duration(seconds: 1));
                        if (!context.mounted) return;
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                child: const Text(
                  'Pay',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
