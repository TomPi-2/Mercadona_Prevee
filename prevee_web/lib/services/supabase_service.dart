import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para gestionar las operaciones de base de datos con Supabase
/// para Productos y Tiendas de Mercadona
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==================== MÉTODOS PARA TIENDAS ====================

  /// Obtener todas las tiendas
  Future<List<Map<String, dynamic>>> getAllShops() async {
    try {
      final response = await _client
          .from('Mercadona_shop')
          .select()
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener tiendas: $e');
    }
  }

  /// Obtener una tienda por ID
  Future<Map<String, dynamic>?> getShopById(int id) async {
    try {
      final response = await _client
          .from('Mercadona_shop')
          .select()
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al obtener tienda: $e');
    }
  }

  /// Obtener tiendas por zona
  Future<List<Map<String, dynamic>>> getShopsByZone(String zone) async {
    try {
      final response = await _client
          .from('Mercadona_shop')
          .select()
          .eq('zone', zone)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener tiendas por zona: $e');
    }
  }

  /// Insertar una nueva tienda
  Future<Map<String, dynamic>> insertShop({
    required String name,
    String? zone,
    String? address,
  }) async {
    try {
      final response = await _client
          .from('Mercadona_shop')
          .insert({
            'name': name,
            'zone': zone,
            'address': address,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al insertar tienda: $e');
    }
  }

  /// Actualizar una tienda existente
  Future<Map<String, dynamic>> updateShop({
    required int id,
    String? name,
    String? zone,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (zone != null) updates['zone'] = zone;
      if (address != null) updates['address'] = address;

      final response = await _client
          .from('Mercadona_shop')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al actualizar tienda: $e');
    }
  }

  /// Eliminar una tienda
  Future<void> deleteShop(int id) async {
    try {
      await _client
          .from('Mercadona_shop')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar tienda: $e');
    }
  }

  // ==================== MÉTODOS PARA PRODUCTOS ====================

  /// Obtener todos los productos
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final response = await _client
          .from('Products')
          .select('*, Mercadona_shop(*)')
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  /// Obtener un producto por ID
  Future<Map<String, dynamic>?> getProductById(int id) async {
    try {
      final response = await _client
          .from('Products')
          .select('*, Mercadona_shop(*)')
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  /// Obtener productos por categoría
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    try {
      final response = await _client
          .from('Products')
          .select('*, Mercadona_shop(*)')
          .eq('category', category)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener productos por categoría: $e');
    }
  }

  /// Obtener productos por tienda
  Future<List<Map<String, dynamic>>> getProductsByShop(int shopId) async {
    try {
      final response = await _client
          .from('Products')
          .select('*, Mercadona_shop(*)')
          .eq('shop_id', shopId)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener productos por tienda: $e');
    }
  }

  /// Obtener productos con stock bajo (opcional: threshold)
  Future<List<Map<String, dynamic>>> getProductsWithLowStock({int threshold = 10}) async {
    try {
      final response = await _client
          .from('Products')
          .select('*, Mercadona_shop(*)')
          .lt('stock', threshold)
          .order('stock', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener productos con stock bajo: $e');
    }
  }

  /// Insertar un nuevo producto
  Future<Map<String, dynamic>> insertProduct({
    required String name,
    String? category,
    int? stock,
    int? shopId,
  }) async {
    try {
      final response = await _client
          .from('Products')
          .insert({
            'name': name,
            'category': category,
            'stock': stock,
            'shop_id': shopId,
          })
          .select('*, Mercadona_shop(*)')
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al insertar producto: $e');
    }
  }

  /// Actualizar un producto existente
  Future<Map<String, dynamic>> updateProduct({
    required int id,
    String? name,
    String? category,
    int? stock,
    int? shopId,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (category != null) updates['category'] = category;
      if (stock != null) updates['stock'] = stock;
      if (shopId != null) updates['shop_id'] = shopId;

      final response = await _client
          .from('Products')
          .update(updates)
          .eq('id', id)
          .select('*, Mercadona_shop(*)')
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  /// Eliminar un producto
  Future<void> deleteProduct(int id) async {
    try {
      await _client
          .from('Products')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  /// Buscar productos por nombre (búsqueda parcial)
  Future<List<Map<String, dynamic>>> searchProductsByName(String searchTerm) async {
    try {
      final response = await _client
          .from('Products')
          .select('*, Mercadona_shop(*)')
          .ilike('name', '%$searchTerm%')
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al buscar productos: $e');
    }
  }

  /// Incrementar stock de un producto
  Future<Map<String, dynamic>> incrementStock(int productId, int amount) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Producto no encontrado');
      }
      
      final currentStock = (product['stock'] as int?) ?? 0;
      final newStock = currentStock + amount;
      
      return await updateProduct(id: productId, stock: newStock);
    } catch (e) {
      throw Exception('Error al incrementar stock: $e');
    }
  }

  /// Decrementar stock de un producto
  Future<Map<String, dynamic>> decrementStock(int productId, int amount) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Producto no encontrado');
      }
      
      final currentStock = (product['stock'] as int?) ?? 0;
      final newStock = (currentStock - amount).clamp(0, currentStock);
      
      return await updateProduct(id: productId, stock: newStock);
    } catch (e) {
      throw Exception('Error al decrementar stock: $e');
    }
  }
}
