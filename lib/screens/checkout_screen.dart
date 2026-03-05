import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final double total;
  const CheckoutScreen({super.key, required this.total});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _holderController = TextEditingController();

  String paymentMethod = "Credit";
  bool saveCardForFuture = true;
  bool isSaving = false;

  final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

  final Color primaryBlue = const Color(0xFF4A6CF7);
  final Color lightBlue = const Color(0xFF6C8EFF);

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Widget paymentButton(String text) {
    bool selected = paymentMethod == text;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            paymentMethod = text;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(colors: [primaryBlue, lightBlue])
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? null
                : Border.all(color: const Color(0xFFE4E8F2)),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF6A7288),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB3BACB)),
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
    );
  }

  String _normalizeCardNumber(String value) {
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  Future<void> _saveCardIfNeeded() async {
    if (!saveCardForFuture || paymentMethod != 'Credit') {
      return;
    }

    await DatabaseHelper.instance.insertCard({
      'cardNumber': _normalizeCardNumber(_cardNumberController.text.trim()),
      'holderName': _holderController.text.trim(),
      'expiryDate': _expiryController.text.trim(),
      'cvv': _cvvController.text.trim(),
    });
  }

  Future<void> _proceedToPayment() async {
    if (paymentMethod == 'Credit' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isSaving = true);
    try {
      await _saveCardIfNeeded();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaymentScreen(total: widget.total)),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Payment data",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total price",
                style: TextStyle(
                  color: Color(0xFF8D96AB),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                currency.format(widget.total),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Payment Method",
                style: TextStyle(
                  color: Color(0xFF8D96AB),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  paymentButton("PayPal"),
                  const SizedBox(width: 10),
                  paymentButton("Credit"),
                  const SizedBox(width: 10),
                  paymentButton("Wallet"),
                ],
              ),

              const SizedBox(height: 25),

              const Text("Card number"),
              const SizedBox(height: 5),

              TextFormField(
                controller: _cardNumberController,
                decoration: inputStyle("**** **** **** ****"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = _normalizeCardNumber(value ?? '');
                  if (paymentMethod != 'Credit') return null;
                  if (number.length < 13 || number.length > 19) {
                    return 'Ingresa un numero de tarjeta valido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: inputStyle("Month / Year"),
                      validator: (value) {
                        if (paymentMethod != 'Credit') return null;
                        if ((value ?? '').trim().isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: inputStyle("***"),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (paymentMethod != 'Credit') return null;
                        final cvv = (value ?? '').trim();
                        if (cvv.length < 3 || cvv.length > 4) {
                          return 'CVV invalido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              const Text("Card holder"),
              const SizedBox(height: 5),

              TextFormField(
                controller: _holderController,
                decoration: inputStyle("Your name and surname"),
                validator: (value) {
                  if (paymentMethod != 'Credit') return null;
                  if ((value ?? '').trim().isEmpty) {
                    return 'Nombre requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Save card data for future payments",
                      style: TextStyle(
                        color: Color(0xFF444E64),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: saveCardForFuture,
                    onChanged: (value) {
                      setState(() => saveCardForFuture = value);
                    },
                    activeThumbColor: primaryBlue,
                  ),
                ],
              ),

              const Spacer(),

              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryBlue, lightBlue]),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextButton(
                  onPressed: isSaving ? null : _proceedToPayment,
                  child: Text(
                    isSaving ? "Guardando..." : "Proceed to confirm",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
