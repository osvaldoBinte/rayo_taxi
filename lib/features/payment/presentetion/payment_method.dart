import 'package:flutter/material.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/pagos/animated_modal_bottom.dart';
import 'package:rayo_taxi/main.dart';

class PaymentMethodPage extends StatefulWidget {
  @override
  _PaymentMethodPageState createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  // Lista de métodos de pago agregados. Puedes reemplazar esto con tu lógica de datos.
  List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      type: 'Tarjeta de Crédito',
      details: '**** **** **** 1234',
      icon: Icons.credit_card,
    ),
     PaymentMethod(
      type: 'Tarjeta de Crédito',
      details: '**** **** **** 1234',
      icon: Icons.credit_card,
    ),
     PaymentMethod(
      type: 'Tarjeta de devito',
      details: '**** **** **** 1234',
      icon: Icons.credit_card,
    ),
     PaymentMethod(
      type: 'Tarjeta de devito',
      details: '**** **** **** 1234',
      icon: Icons.credit_card,
    ),  PaymentMethod(
      type: 'Tarjeta de devito',
      details: '**** **** **** 1234',
      icon: Icons.credit_card,
    ),  PaymentMethod(
      type: 'Tarjeta de devito',
      details: '**** **** **** 1234',
      icon: Icons.credit_card,
    ),
     PaymentMethod(
      type: 'Tarjeta de devito',
      details: '**** **** **** 1234',
      icon: Icons.credit_card,
    ), PaymentMethod(
      type: 'Tarjeta de devito',
      details: '**** **** **** 1234',
      icon: Icons.credit_card,
    ),PaymentMethod(
      type: 'Tarjeta de devito',
      details: '**** **** **** 1234',
      icon: Icons.credit_card,
    ),PaymentMethod(
      type: 'Tarjeta de devito',
      details: '**** **** **** 1234',
      icon: Icons.credit_card,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Métodos de Pago'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _paymentMethods.isNotEmpty
                  ? ListView.builder(
                      itemCount: _paymentMethods.length,
                      itemBuilder: (context, index) {
                        final method = _paymentMethods[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(method.icon, color: Theme.of(context).primaryColor),
                            title: Text(method.type),
                            subtitle: Text(method.details),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _removePaymentMethod(index);
                              },
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'No hay métodos de pago agregados.',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showAddPaymentMethodSheet,
              style: ElevatedButton.styleFrom(
               backgroundColor:
                          Theme.of(context).colorScheme.buttonColor,
                      foregroundColor:
                          Theme.of(context).colorScheme.buttontext,
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Agregar método de pago',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removePaymentMethod(int index) {
    setState(() {
      _paymentMethods.removeAt(index);
    });
  }

  void _showAddPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AnimatedModalBottomSheet();
      },
    );
  }
}

class PaymentMethod {
  final String type;
  final String details;
  final IconData icon;

  PaymentMethod({
    required this.type,
    required this.details,
    required this.icon,
  });
}
