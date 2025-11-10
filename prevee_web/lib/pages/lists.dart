import 'package:flutter/material.dart';
import 'package:prevee_web/services/user_service.dart';
import '../services/supabase_service.dart';
import '../widgets/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CombinedListsPage extends StatefulWidget {
  const CombinedListsPage({super.key});

  @override
  State<CombinedListsPage> createState() => _CombinedListsPageState();
}

class _CombinedListsPageState extends State<CombinedListsPage> {
  final SupabaseClient _client = Supabase.instance.client;
  final UserService _userService = UserService();
  final SupabaseService _supabaseService = SupabaseService();
  
  // Para la lista inteligente unificada
  // Map: productId -> {product: {...}, quantity: int, needScore: double?, isRecommended: bool}
  final Map<int, Map<String, dynamic>> _shoppingList = {};
  
  int? _currentCustomerId;
  double _minNeedScore = 0.5;
  bool _isLoadingList = true;
  
  // Para todos los productos con paginación
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoadingProducts = true;
  bool _isLoadingMoreProducts = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreProducts = true;

  // Para el carrito de productos manuales temporales (antes de añadir)
  final Map<int, int> _manualCart = {}; // productId -> quantity

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Inicializa la carga de datos de forma optimizada
  Future<void> _initializeData() async {
    await Future.wait([
      _loadShoppingList(),
      _loadProducts(reset: true),
    ]);
  }

  void _updateManualCart(int productId, int quantity) {
    setState(() {
      if (quantity > 0) {
        _manualCart[productId] = quantity;
      } else {
        _manualCart.remove(productId);
      }
    });
  }

  int _getTotalManualItems() {
    return _manualCart.values.fold(0, (sum, qty) => sum + qty);
  }

  double _getTotalManualPrice() {
    double total = 0;
    for (var entry in _manualCart.entries) {
      final product = _allProducts.firstWhere(
        (p) => p['id'] == entry.key,
        orElse: () => {},
      );
      if (product.isNotEmpty) {
        total += (product['price'] as num).toDouble() * entry.value;
      }
    }
    return total;
  }

  /// Añadir productos manuales a la lista unificada
  void _addManualProductsToList() {
    if (_manualCart.isEmpty) return;

    setState(() {
      for (var entry in _manualCart.entries) {
        final productId = entry.key;
        final quantity = entry.value;
        
        // Buscar el producto en _allProducts
        final product = _allProducts.firstWhere(
          (p) => p['id'] == productId,
          orElse: () => {},
        );
        
        if (product.isNotEmpty) {
          if (_shoppingList.containsKey(productId)) {
            // Si ya existe, sumar la cantidad
            _shoppingList[productId]!['quantity'] += quantity;
          } else {
            // Si no existe, añadirlo como producto manual
            _shoppingList[productId] = {
              'product': product,
              'quantity': quantity,
              'needScore': null, // No tiene need_score porque es manual
              'isRecommended': false,
              'daysSinceLast': null,
              'avgDaysBetween': null,
            };
          }
        }
      }
      
      // Limpiar el carrito temporal
      _manualCart.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ ${_getTotalManualItems()} productos añadidos a tu lista',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Obtener lista ordenada de productos (recomendados primero, luego manuales)
  List<MapEntry<int, Map<String, dynamic>>> get _sortedShoppingList {
    final entries = _shoppingList.entries.toList();
    
    entries.sort((a, b) {
      final aIsRecommended = a.value['isRecommended'] as bool;
      final bIsRecommended = b.value['isRecommended'] as bool;
      
      // Primero los recomendados
      if (aIsRecommended && !bIsRecommended) return -1;
      if (!aIsRecommended && bIsRecommended) return 1;
      
      // Entre recomendados, ordenar por needScore
      if (aIsRecommended && bIsRecommended) {
        final aScore = (a.value['needScore'] as num?)?.toDouble() ?? 0;
        final bScore = (b.value['needScore'] as num?)?.toDouble() ?? 0;
        return bScore.compareTo(aScore);
      }
      
      // Entre manuales, ordenar por nombre
      final aName = (a.value['product'] as Map<String, dynamic>)['name'] as String? ?? '';
      final bName = (b.value['product'] as Map<String, dynamic>)['name'] as String? ?? '';
      return aName.compareTo(bName);
    });
    
    return entries;
  }

  Future<void> _loadShoppingList() async {
    if (!mounted) return;
    setState(() => _isLoadingList = true);
    
    try {
      final customers = await _userService.getAllUsers();
      if (customers.isEmpty) {
        if (mounted) setState(() => _isLoadingList = false);
        return;
      }
      
      _currentCustomerId = customers.first.id;
      
      if (_currentCustomerId == null) {
        if (mounted) setState(() => _isLoadingList = false);
        return;
      }

      final response = await _client
          .from('CustomerProductStats')
          .select('''
            customer_id,
            product_id,
            last_purchase_at,
            avg_days_between,
            days_since_last,
            need_score,
            Products!inner (
              id,
              name,
              category,
              price,
              stock
            )
          ''')
          .eq('customer_id', _currentCustomerId!)
          .gte('need_score', _minNeedScore)
          .order('need_score', ascending: false)
          .limit(50);

      if (!mounted) return;

      setState(() {
        // Limpiar productos recomendados anteriores
        _shoppingList.removeWhere((key, value) => value['isRecommended'] == true);
        
        // Añadir nuevos productos recomendados
        for (var item in response as List) {
          final itemMap = item as Map<String, dynamic>;
          final productId = itemMap['product_id'] as int;
          final product = itemMap['Products'] as Map<String, dynamic>;
          
          _shoppingList[productId] = {
            'product': product,
            'quantity': 1, // Cantidad por defecto
            'needScore': (itemMap['need_score'] as num?)?.toDouble(),
            'isRecommended': true,
            'daysSinceLast': (itemMap['days_since_last'] as num?)?.toDouble(),
            'avgDaysBetween': (itemMap['avg_days_between'] as num?)?.toDouble(),
          };
        }
        
        _isLoadingList = false;
      });
    } catch (e) {
      debugPrint('❌ Error al cargar lista: $e');
      if (mounted) {
        setState(() => _isLoadingList = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar la lista: ${e.toString().substring(0, 100)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _allProducts.clear();
      _hasMoreProducts = true;
      if (mounted) setState(() => _isLoadingProducts = true);
    } else {
      if (!_hasMoreProducts || _isLoadingMoreProducts) return;
      if (mounted) setState(() => _isLoadingMoreProducts = true);
    }
    
    try {
      final int from = _currentPage * _pageSize;
      final int to = from + _pageSize - 1;

      final response = await _client
          .from('Products')
          .select('id, name, category, price, stock')
          .order('name')
          .range(from, to);

      if (!mounted) return;

      final List<Map<String, dynamic>> newProducts = (response as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();

      setState(() {
        _allProducts.addAll(newProducts);
        _hasMoreProducts = newProducts.length == _pageSize;
        _currentPage++;
        _isLoadingProducts = false;
        _isLoadingMoreProducts = false;
      });
    } catch (e) {
      debugPrint('❌ Error al cargar productos: $e');
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _isLoadingMoreProducts = false;
        });
      }
    }
  }

  Color _getNeedScoreColor(double score) {
    if (score >= 0.9) return Colors.red[700]!;
    if (score >= 0.7) return Colors.orange[700]!;
    if (score >= 0.5) return Colors.amber[700]!;
    return Colors.green[700]!;
  }

  String _getNeedScoreLabel(double score) {
    if (score >= 0.9) return 'MUY URGENTE';
    if (score >= 0.7) return 'URGENTE';
    if (score >= 0.5) return 'PRONTO';
    return 'NORMAL';
  }

  IconData _getNeedScoreIcon(double score) {
    if (score >= 0.9) return Icons.warning_amber_rounded;
    if (score >= 0.7) return Icons.schedule;
    if (score >= 0.5) return Icons.access_time;
    return Icons.check_circle_outline;
  }

  int get _totalItems => _shoppingList.values.fold(0, (sum, item) => sum + (item['quantity'] as int));

  double get _totalPrice {
    double total = 0;
    for (var item in _shoppingList.values) {
      final product = item['product'] as Map<String, dynamic>;
      final quantity = item['quantity'] as int;
      total += (product['price'] as num).toDouble() * quantity;
    }
    return total;
  }

  int get _recommendedCount => _shoppingList.values.where((item) => item['isRecommended'] == true).length;
  int get _manualCount => _shoppingList.values.where((item) => item['isRecommended'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ============ SECCIÓN 1: LISTA INTELIGENTE UNIFICADA ============
            if (_isLoadingList)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generando tu lista personalizada...'),
                      ],
                    ),
                  ),
                ),
              )
            else if (_shoppingList.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tu lista está vacía',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Añade productos manualmente o reduce el umbral para ver recomendaciones',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() => _minNeedScore = 0.3);
                                _loadShoppingList();
                              },
                              icon: const Icon(Icons.tune),
                              label: const Text('Reducir umbral (30%)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _loadShoppingList,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Recargar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // Header de la lista inteligente
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            size: 32,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mi Lista de Compra',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Productos recomendados + añadidos manualmente',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Text('Umbral: '),
                                DropdownButton<double>(
                                  value: _minNeedScore,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: 0.3, child: Text('Bajo (30%)')),
                                    DropdownMenuItem(value: 0.5, child: Text('Medio (50%)')),
                                    DropdownMenuItem(value: 0.7, child: Text('Alto (70%)')),
                                    DropdownMenuItem(value: 0.9, child: Text('Urgente (90%)')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _minNeedScore = value);
                                      _loadShoppingList();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadShoppingList,
                            tooltip: 'Actualizar recomendaciones',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildSummaryCard(
                            'Recomendados',
                            '$_recommendedCount',
                            Icons.auto_awesome,
                            Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard(
                            'Añadidos',
                            '$_manualCount',
                            Icons.add_circle_outline,
                            Colors.orange,
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard(
                            'Total items',
                            '$_totalItems',
                            Icons.shopping_basket,
                            AppColors.primary,
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard(
                            'Total',
                            '${_totalPrice.toStringAsFixed(2)} €',
                            Icons.euro,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Lista unificada de productos
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = _sortedShoppingList[index];
                    final productId = entry.key;
                    final itemData = entry.value;
                    final product = itemData['product'] as Map<String, dynamic>;
                    final quantity = itemData['quantity'] as int;
                    final isRecommended = itemData['isRecommended'] as bool;
                    final needScore = (itemData['needScore'] as num?)?.toDouble();
                    final daysSinceLast = (itemData['daysSinceLast'] as num?)?.toDouble();
                    final avgDaysBetween = (itemData['avgDaysBetween'] as num?)?.toDouble();

                    return Padding(
                      padding: EdgeInsets.fromLTRB(24, index == 0 ? 24 : 0, 24, 12),
                      child: _UnifiedListProductCard(
                        product: product,
                        productId: productId,
                        quantity: quantity,
                        isRecommended: isRecommended,
                        needScore: needScore,
                        daysSinceLast: daysSinceLast,
                        avgDaysBetween: avgDaysBetween,
                        onQuantityChanged: (newQuantity) {
                          setState(() {
                            if (newQuantity > 0) {
                              _shoppingList[productId]!['quantity'] = newQuantity;
                            } else {
                              _shoppingList.remove(productId);
                            }
                          });
                        },
                        onRemove: () {
                          setState(() {
                            _shoppingList.remove(productId);
                          });
                        },
                        getNeedScoreColor: _getNeedScoreColor,
                        getNeedScoreIcon: _getNeedScoreIcon,
                        getNeedScoreLabel: _getNeedScoreLabel,
                      ),
                    );
                  },
                  childCount: _sortedShoppingList.length,
                ),
              ),

              // Footer de la lista
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                      bottom: BorderSide(color: Colors.grey[400]!, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _shoppingList.isNotEmpty
                              ? () {
                                  setState(() {
                                    _shoppingList.clear();
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Vaciar lista'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _shoppingList.isNotEmpty
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Lista guardada: $_totalItems productos (${_totalPrice.toStringAsFixed(2)} €)',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.save),
                          label: Text(
                            'Guardar Lista ($_totalItems) - ${_totalPrice.toStringAsFixed(2)} €',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ============ SECCIÓN 2: TODOS LOS PRODUCTOS ============
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 28,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Todos los Productos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Añade productos manualmente a tu lista',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoadingProducts)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(50.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ProductCard(
                        key: ValueKey(_allProducts[index]['id']),
                        product: _allProducts[index],
                        initialQuantity: _manualCart[_allProducts[index]['id']] ?? 0,
                        onQuantityChanged: (quantity) {
                          _updateManualCart(_allProducts[index]['id'], quantity);
                        },
                      );
                    },
                    childCount: _allProducts.length,
                  ),
                ),
              ),

              // Botón "Cargar más"
              if (_hasMoreProducts || _isLoadingMoreProducts)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: _isLoadingMoreProducts
                          ? const Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Cargando más productos...'),
                              ],
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _loadProducts(reset: false),
                              icon: const Icon(Icons.arrow_downward),
                              label: const Text('Cargar más productos'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

              // Mensaje final si no hay más productos
              if (!_hasMoreProducts && !_isLoadingMoreProducts && _allProducts.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: _manualCart.isNotEmpty ? 120 : 24,
                    ),
                    child: Center(
                      child: Text(
                        '✓ Has visto todos los productos disponibles',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),

        // ============ BARRA FLOTANTE DEL CARRITO MANUAL ============
        if (_manualCart.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_getTotalManualItems()} ${_getTotalManualItems() == 1 ? 'producto' : 'productos'} seleccionados',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total: ${_getTotalManualPrice().toStringAsFixed(2)} €',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _addManualProductsToList,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Añadir a la lista'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _manualCart.clear();
                        });
                      },
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                      tooltip: 'Limpiar selección',
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para la lista unificada
class _UnifiedListProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int productId;
  final int quantity;
  final bool isRecommended;
  final double? needScore;
  final double? daysSinceLast;
  final double? avgDaysBetween;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final Color Function(double) getNeedScoreColor;
  final IconData Function(double) getNeedScoreIcon;
  final String Function(double) getNeedScoreLabel;

  const _UnifiedListProductCard({
    required this.product,
    required this.productId,
    required this.quantity,
    required this.isRecommended,
    this.needScore,
    this.daysSinceLast,
    this.avgDaysBetween,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.getNeedScoreColor,
    required this.getNeedScoreIcon,
    required this.getNeedScoreLabel,
  });

  String _getProductImagePath(int id) {
    return 'assets/comida/$id.png';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRecommended 
              ? Colors.blue.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Badge de tipo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isRecommended ? Colors.blue[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRecommended ? Icons.auto_awesome : Icons.add_circle,
                    size: 16,
                    color: isRecommended ? Colors.blue[700] : Colors.orange[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isRecommended ? 'Recomendado' : 'Manual',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isRecommended ? Colors.blue[700] : Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Imagen
            _buildImage(),
            const SizedBox(width: 16),
            
            // Info del producto
            Expanded(
              child: _buildProductInfo(),
            ),
            
            // Indicador de necesidad (solo para recomendados)
            if (isRecommended && needScore != null) ...[
              _buildNeedScoreIndicator(),
              const SizedBox(width: 16),
            ],
            
            // Selector de cantidad
            _buildQuantitySelector(),
            const SizedBox(width: 16),
            
            // Precio
            _buildPriceTag(),
            const SizedBox(width: 16),
            
            // Botón eliminar
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              color: Colors.red[400],
              tooltip: 'Eliminar de la lista',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(int productId, {double width = 80, double height = 80}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[100]!,
            Colors.grey[200]!,
            Colors.green[50]!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          _getProductImagePath(productId),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Si no existe la imagen, mostrar placeholder
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[200]!,
                    Colors.grey[100]!,
                    Colors.green[50]!,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.4),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.shopping_basket_outlined,
                      size: width * 0.4,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[100]!,
            Colors.grey[200]!,
            Colors.green[50]!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          _getProductImagePath(productId),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[200]!,
                    Colors.grey[100]!,
                    Colors.green[50]!,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.4),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.shopping_basket_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageSimple() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.shopping_basket_outlined,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product['name'] ?? 'Sin nombre',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                product['category'] ?? 'Sin categoría',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Stock: ${product['stock']} ud',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        if (daysSinceLast != null && daysSinceLast! > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Última compra: hace ${daysSinceLast!.toInt()} días',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
        if (avgDaysBetween != null && avgDaysBetween! > 0)
          Text(
            'Compras cada ~${avgDaysBetween!.toInt()} días',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _buildNeedScoreIndicator() {
    if (needScore == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: getNeedScoreColor(needScore!).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: getNeedScoreColor(needScore!),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            getNeedScoreIcon(needScore!),
            color: getNeedScoreColor(needScore!),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            getNeedScoreLabel(needScore!),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: getNeedScoreColor(needScore!),
            ),
          ),
          Text(
            '${(needScore! * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: getNeedScoreColor(needScore!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => onQuantityChanged(quantity - 1),
            color: AppColors.primary,
            iconSize: 20,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onQuantityChanged(quantity + 1),
            color: AppColors.primary,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTag() {
    final unitPrice = (product['price'] as num).toDouble();
    final totalPrice = unitPrice * quantity;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${unitPrice.toStringAsFixed(2)} € / ud',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${totalPrice.toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ),
      ],
    );
  }
}

// ProductCard (mantener igual)
class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final int initialQuantity;
  final Function(int) onQuantityChanged;

  const ProductCard({
    super.key,
    required this.product,
    this.initialQuantity = 0,
    required this.onQuantityChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late int _quantity;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuantity != oldWidget.initialQuantity) {
      _quantity = widget.initialQuantity;
    }
  }

  void _updateQuantity(int newQuantity) {
    setState(() {
      _quantity = newQuantity;
    });
    widget.onQuantityChanged(newQuantity);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
        child: Card(
          elevation: _isHovered ? 12 : 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isHovered 
                  ? AppColors.primary.withOpacity(0.5) 
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.green[50]!,
                  Colors.green[100]!.withOpacity(0.6),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildImage(),
                ),
                Expanded(
                  flex: 3,
                  child: _buildProductDetails(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[100]!,
                  Colors.grey[200]!,
                  Colors.green[50]!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: _buildPlaceholder(),
          ),
        ),
        if (widget.product['category'] != null)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.product['category'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        if ((widget.product['stock'] ?? 0) < 10 && (widget.product['stock'] ?? 0) > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange[400]!,
                    Colors.orange[600]!,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        // Efecto de brillo sutil en hover
        if (_isHovered)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductDetails() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product['name'] ?? 'Sin nombre',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: Color(0xFF2C3E50),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (widget.product['stock'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: (widget.product['stock'] ?? 0) < 10
                      ? [Colors.orange[100]!, Colors.orange[50]!]
                      : [Colors.grey[100]!, Colors.grey[50]!],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Stock: ${widget.product['stock']} ud',
                style: TextStyle(
                  fontSize: 10,
                  color: (widget.product['stock'] ?? 0) < 10
                      ? Colors.orange[800]
                      : Colors.grey[700],
                  fontWeight: (widget.product['stock'] ?? 0) < 10
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green[50]!,
                  Colors.green[100]!,
                  Colors.green[50]!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.green[200]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.euro,
                  size: 14,
                  color: Colors.green[800],
                ),
                const SizedBox(width: 2),
                Text(
                  '${(widget.product['price'] ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildQuantitySelector(),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
            Colors.grey[50]!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.remove_circle,
              color: _quantity > 0 ? AppColors.primary : Colors.grey[400],
            ),
            onPressed: _quantity > 0
                ? () => _updateQuantity(_quantity - 1)
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 24,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: _quantity > 0
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.08),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$_quantity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _quantity > 0 ? AppColors.primary : Colors.grey[700],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: () => _updateQuantity(_quantity + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[100]!,
            Colors.grey[200]!,
            Colors.green[50]!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.4),
                ],
              ),
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Sin imagen',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}