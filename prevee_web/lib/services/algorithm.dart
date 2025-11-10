class Product {
  final int id;
  final String name;
  final String? category;
  final int stock;
  final int shopId;
  final double? price; // ref_price (price_numeric o media histórica)

  Product({
    required this.id,
    required this.name,
    this.category,
    required this.stock,
    required this.shopId,
    this.price,
  });
}

class Stat {
  final int productId;
  final double needScore; // 0..1
  final double avgDaysBetween; // días
  final double daysSinceLast; // días

  Stat({
    required this.productId,
    required this.needScore,
    required this.avgDaysBetween,
    required this.daysSinceLast,
  });
}

class SuggestedItem {
  final Product product;
  final double needScore; // para UI
  final int suggestedQty; // entero
  final String? explanation;

  SuggestedItem({
    required this.product,
    required this.needScore,
    required this.suggestedQty,
    this.explanation,
  });
}

/// Cantidad sugerida muy básica: cubrir ~avgDaysBetween días.
/// Aquí lo simplificamos a 1 o 2 unidades según lo "atrasado" que vaya.
int _suggestQty({
  required double avgDaysBetween,
  required double daysSinceLast,
}) {
  if (avgDaysBetween <= 0) return 1;
  final ratio = daysSinceLast / avgDaysBetween; // 0..>1
  if (ratio >= 1.5) return 2;
  return 1;
}

/// Construye la lista sugerida SIN sustituciones.
/// - needThreshold: umbral mínimo de necesidad (0.6 por defecto)
/// - budgetLimit: presupuesto opcional; si se supera, deja de añadir ítems.
List<SuggestedItem> buildSuggestedList({
  required List<Product> catalog, // productos de la tienda
  required Map<int, Stat> statsByProduct, // productId -> stats
  double needThreshold = 0.6,
  int maxItems = 20,
  double? budgetLimit,
}) {
  // Une producto + stat si supera umbral y hay stock
  final entries = <MapEntry<Product, Stat>>[];
  for (final p in catalog) {
    final st = statsByProduct[p.id];
    if (st == null) continue;
    if (st.needScore >= needThreshold && p.stock > 0) {
      entries.add(MapEntry(p, st));
    }
  }

  // Ordena por necesidad
  entries.sort((a, b) {
    final d = b.value.needScore.compareTo(a.value.needScore);
    if (d != 0) return d;
    return b.value.daysSinceLast.compareTo(a.value.daysSinceLast);
  });

  final result = <SuggestedItem>[];
  double runningCost = 0.0;

  for (final e in entries) {
    final product = e.key;
    final st = e.value;

    final qty = _suggestQty(
      avgDaysBetween: st.avgDaysBetween,
      daysSinceLast: st.daysSinceLast,
    );

    // Control de presupuesto simple
    final lineCost = (product.price ?? 0.0) * qty;
    if (budgetLimit != null) {
      if (runningCost + lineCost > budgetLimit && result.isNotEmpty) {
        break; // paramos si pasamos del límite y ya hay algo en la lista
      }
      runningCost += lineCost;
    }

    result.add(
      SuggestedItem(
        product: product,
        needScore: st.needScore,
        suggestedQty: qty,
        explanation:
            'Lo compras cada ~${st.avgDaysBetween.toStringAsFixed(0)} días; han pasado ${st.daysSinceLast.toStringAsFixed(0)}.',
      ),
    );

    if (result.length >= maxItems) break;
  }

  return result;
}
