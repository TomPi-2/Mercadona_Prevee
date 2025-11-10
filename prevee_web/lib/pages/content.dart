import 'package:flutter/material.dart';

class ProductGridView extends StatelessWidget {
  const ProductGridView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de la Compra')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            if (constraints.maxWidth > 1200) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth > 800) {
              crossAxisCount = 3;
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: sampleProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(product: sampleProducts[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                product.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${product.price.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    product.suggestion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Product {
  final String name;
  final double price;
  final String imageUrl;
  final String suggestion;

  Product({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.suggestion,
  });
}

// Datos de ejemplo
final List<Product> sampleProducts = [
  Product(
    name: 'Leche Entera',
    price: 1.20,
    imageUrl: 'https://via.placeholder.com/300x300',
    suggestion: 'Comprado por última vez hace 3 días',
  ),
  Product(
    name: 'Pan de Molde',
    price: 1.50,
    imageUrl: 'https://via.placeholder.com/300x300',
    suggestion: 'Basado en productos que te gustan',
  ),
  Product(
    name: 'Manzanas Golden',
    price: 2.30,
    imageUrl: 'https://via.placeholder.com/300x300',
    suggestion: 'Comprado por última vez hace 7 días',
  ),
  Product(
    name: 'Yogur Natural',
    price: 3.45,
    imageUrl: 'https://via.placeholder.com/300x300',
    suggestion: 'Basado en productos que te gustan',
  ),
];
