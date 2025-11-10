import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

/// Servicio para poblar la base de datos con datos de prueba
class DatabaseSeeder {
  final SupabaseClient _client = Supabase.instance.client;
  final Random _random = Random();

  /// Poblar toda la base de datos (tiendas y productos)
  Future<void> seedAll() async {
    print('🚀 Iniciando población de base de datos...\n');
    
    try {
      await seedShops();
      await seedProducts();
      print('\n✨ ¡Base de datos poblada exitosamente!');
    } catch (e) {
      print('❌ Error al poblar la base de datos: $e');
      rethrow;
    }
  }

  /// Poblar solo las tiendas
  Future<void> seedShops() async {
    print('📍 Creando tiendas Mercadona por barrios...');
    
    final tiendas = _getTiendasData();
    int contador = 0;

    for (var tienda in tiendas) {
      await _client.from('Mercadona_shop').insert(tienda);
      contador++;
      if (contador % 10 == 0) {
        print('  ✓ [$contador/${tiendas.length}] tiendas creadas...');
      }
    }

    // Mostrar resumen
    final zonasAreaMetropolitana = [
      'Alboraya', 'Burjassot', 'Godella', 'Tavernes',
      'Sedaví', 'Alfafar', 'Benetússer', 'Massanassa', 'Catarroja',
      'Mislata', 'Quart', 'Xirivella', 'Aldaia', 'Torrent',
      'Albal', 'Beniparrell', 'Silla',
      'Saler', 'Pinedo', 'Perellonet'
    ];

    final tiendasValenciaCapital = tiendas.where((t) {
      final zona = t['zone'] as String;
      return !zonasAreaMetropolitana.any((area) => zona.contains(area));
    }).length;

    print('\n📊 Resumen de tiendas:');
    print('   • Total: ${tiendas.length}');
    print('   • Valencia capital: $tiendasValenciaCapital');
    print('   • Área metropolitana: ${tiendas.length - tiendasValenciaCapital}');
  }

  /// Poblar solo los productos
  Future<void> seedProducts() async {
    print('\n🛒 Creando productos Mercadona...');

    // Obtener IDs de tiendas
    final tiendas = await _client
        .from('Mercadona_shop')
        .select('id')
        .order('id');

    if (tiendas.isEmpty) {
      print('❌ Error: No hay tiendas en la base de datos. Ejecuta seedShops() primero.');
      return;
    }

    final tiendasIds = (tiendas as List).map((t) => t['id'] as int).toList();
    
    // Filtrar solo los IDs 43, 44 y 45
    final tiendasSeleccionadas = tiendasIds.where((id) => id >= 43 && id <= 45).toList();
    
    if (tiendasSeleccionadas.isEmpty) {
      print('❌ Error: No se encontraron tiendas con IDs 43, 44 o 45.');
      return;
    }

    final productos = _getProductosData();

    int contador = 0;
    for (var producto in productos) {
      // Asignar tienda ALEATORIA entre 43, 44 y 45
      final shopId = tiendasSeleccionadas[_random.nextInt(tiendasSeleccionadas.length)];

      final productoCompleto = {
        ...producto,
        'shop_id': shopId,
      };

      await _client.from('Products').insert(productoCompleto);

      contador++;
      if (contador % 50 == 0) {
        print('  📦 [$contador/${productos.length}] productos insertados...');
      }
    }

    print('  ✅ Total: $contador productos insertados');
    print('  📍 Productos distribuidos entre tiendas ID: ${tiendasSeleccionadas.join(", ")}');
  }

  /// Limpiar toda la base de datos
  Future<void> clearAll() async {
    print('🗑️  Limpiando base de datos...');
    
    try {
      // Eliminar productos primero (por la foreign key)
      await _client.from('Products').delete().neq('id', 0);
      print('  ✓ Productos eliminados');
      
      // Eliminar tiendas
      await _client.from('Mercadona_shop').delete().neq('id', 0);
      print('  ✓ Tiendas eliminadas');
      
      print('✨ Base de datos limpiada exitosamente');
    } catch (e) {
      print('❌ Error al limpiar la base de datos: $e');
      rethrow;
    }
  }

  Future<void> clearProducts() async {
    print('🗑️  Limpiando productos...');
    try {
      await _client.from('Products').delete().neq('id', 0);
      print('  ✓ Productos eliminados');
    } catch (e) {
      print('❌ Error al limpiar los productos: $e');
      rethrow;
    }
  }

  /// Verificar si la base de datos ya está poblada
  Future<bool> isDatabasePopulated() async {
    try {
      final shops = await _client.from('Mercadona_shop').select('id').limit(1);
      final products = await _client.from('Products').select('id').limit(1);
      
      return (shops as List).isNotEmpty && (products as List).isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar la base de datos: $e');
      return false;
    }
  }

  // ============================================
  // DATOS DE TIENDAS
  // ============================================

  List<Map<String, dynamic>> _getTiendasData() {
    return [
      // VALENCIA - CENTRO HISTÓRICO Y ALREDEDORES
      {'name': 'Mercadona Ciutat Vella', 'zone': 'Ciutat Vella', 'address': 'Calle Colón, 45, Valencia'},
      {'name': 'Mercadona El Carmen', 'zone': 'El Carmen', 'address': 'Plaza del Tossal, 3, Valencia'},
      {'name': 'Mercadona La Xerea', 'zone': 'La Xerea', 'address': 'Calle Nàquera, 12, Valencia'},
      
      // VALENCIA - ENSANCHE
      {'name': 'Mercadona Ruzafa', 'zone': 'Ruzafa', 'address': 'Calle Sueca, 32, Valencia'},
      {'name': 'Mercadona Gran Vía', 'zone': 'Gran Vía', 'address': 'Gran Vía Marqués del Turia, 67, Valencia'},
      {'name': 'Mercadona Pla del Remei', 'zone': 'Pla del Remei', 'address': 'Calle Jorge Juan, 18, Valencia'},
      
      // VALENCIA - NORTE
      {'name': 'Mercadona Benimaclet', 'zone': 'Benimaclet', 'address': 'Avenida Primado Reig, 112, Valencia'},
      {'name': 'Mercadona Campanar', 'zone': 'Campanar', 'address': 'Calle Ramón Llull, 8, Valencia'},
      {'name': 'Mercadona Tendetes', 'zone': 'Tendetes', 'address': 'Avenida Burjassot, 54, Valencia'},
      {'name': 'Mercadona Marxalenes', 'zone': 'Marxalenes', 'address': 'Calle Sagunto, 123, Valencia'},
      
      // VALENCIA - SUR
      {'name': 'Mercadona Malilla', 'zone': 'Malilla', 'address': 'Avenida Ausias March, 45, Valencia'},
      {'name': 'Mercadona Nazaret', 'zone': 'Nazaret', 'address': 'Calle del Puerto, 234, Valencia'},
      {'name': 'Mercadona La Torre', 'zone': 'La Torre', 'address': 'Avenida al Vedat, 78, Valencia'},
      
      // VALENCIA - ESTE
      {'name': 'Mercadona El Cabanyal', 'zone': 'El Cabanyal', 'address': 'Calle Reina, 89, Valencia'},
      {'name': 'Mercadona La Malvarrosa', 'zone': 'La Malvarrosa', 'address': 'Paseo Marítimo, 23, Valencia'},
      {'name': 'Mercadona Algirós', 'zone': 'Algirós', 'address': 'Avenida de los Naranjos, 56, Valencia'},
      
      // VALENCIA - OESTE
      {'name': 'Mercadona Benicalap', 'zone': 'Benicalap', 'address': 'Calle Pérez Galdós, 92, Valencia'},
      {'name': 'Mercadona Trinitat', 'zone': 'Trinitat', 'address': 'Avenida Constitución, 145, Valencia'},
      {'name': 'Mercadona Patraix', 'zone': 'Patraix', 'address': 'Calle San Vicente Mártir, 234, Valencia'},
      {'name': 'Mercadona Jesús', 'zone': 'Jesús', 'address': 'Avenida de la Plata, 67, Valencia'},
      
      // ÁREA METROPOLITANA NORTE
      {'name': 'Mercadona Alboraya Centro', 'zone': 'Alboraya Centro', 'address': 'Carrer de la Democràcia, 23, Alboraya'},
      {'name': 'Mercadona Port Saplaya', 'zone': 'Port Saplaya', 'address': 'Avenida del Mediterraneo, 45, Alboraya'},
      {'name': 'Mercadona Tavernes Blanques', 'zone': 'Tavernes Blanques', 'address': 'Calle Mayor, 12, Tavernes Blanques'},
      {'name': 'Mercadona Burjassot', 'zone': 'Burjassot Centro', 'address': 'Avenida Primero de Mayo, 78, Burjassot'},
      {'name': 'Mercadona Godella', 'zone': 'Godella', 'address': 'Calle San Roc, 34, Godella'},
      
      // ÁREA METROPOLITANA SUR
      {'name': 'Mercadona Sedaví', 'zone': 'Sedaví', 'address': 'Avenida Ausiàs March, 56, Sedaví'},
      {'name': 'Mercadona Alfafar', 'zone': 'Alfafar', 'address': 'Calle Valencia, 89, Alfafar'},
      {'name': 'Mercadona Benetússer', 'zone': 'Benetússer', 'address': 'Avenida del Cid, 123, Benetússer'},
      {'name': 'Mercadona Massanassa', 'zone': 'Massanassa', 'address': 'Calle Major, 45, Massanassa'},
      {'name': 'Mercadona Catarroja', 'zone': 'Catarroja', 'address': 'Avenida Rambleta, 67, Catarroja'},
      
      // ÁREA METROPOLITANA OESTE
      {'name': 'Mercadona Mislata Centro', 'zone': 'Mislata Centro', 'address': 'Avenida Gregorio Gea, 23, Mislata'},
      {'name': 'Mercadona Quart de Poblet', 'zone': 'Quart de Poblet', 'address': 'Calle San Onofre, 45, Quart de Poblet'},
      {'name': 'Mercadona Xirivella', 'zone': 'Xirivella', 'address': 'Avenida del Cid, 78, Xirivella'},
      {'name': 'Mercadona Aldaia', 'zone': 'Aldaia', 'address': 'Calle Valencia, 123, Aldaia'},
      {'name': 'Mercadona Torrent Centro', 'zone': 'Torrent Centro', 'address': 'Calle San Pascual, 56, Torrent'},
      
      // ÁREA METROPOLITANA ESTE
      {'name': 'Mercadona Albal', 'zone': 'Albal', 'address': 'Avenida Hispanidad, 34, Albal'},
      {'name': 'Mercadona Beniparrell', 'zone': 'Beniparrell', 'address': 'Calle Mayor, 23, Beniparrell'},
      {'name': 'Mercadona Silla', 'zone': 'Silla', 'address': 'Avenida Blasco Ibáñez, 67, Silla'},
      
      // POBLACIONES COSTERAS
      {'name': 'Mercadona El Saler', 'zone': 'El Saler', 'address': 'Avenida de los Pinares, 12, El Saler'},
      {'name': 'Mercadona Pinedo', 'zone': 'Pinedo', 'address': 'Calle del Mar, 45, Pinedo'},
      {'name': 'Mercadona El Perellonet', 'zone': 'El Perellonet', 'address': 'Avenida Mediterráneo, 23, El Perellonet'},
    ];
  }

  // ============================================
  // DATOS DE PRODUCTOS
  // ============================================

  List<Map<String, dynamic>> _getProductosData() {
    return [
      // LÁCTEOS Y HUEVOS (30 productos)
      {'name': 'Leche Entera Hacendado 1L', 'category': 'Lácteos', 'stock': 120, 'price': 0.85},
      {'name': 'Leche Semidesnatada Hacendado 1L', 'category': 'Lácteos', 'stock': 185, 'price': 0.85},
      {'name': 'Leche Desnatada Hacendado 1L', 'category': 'Lácteos', 'stock': 15, 'price': 0.85},
      {'name': 'Leche Sin Lactosa Hacendado 1L', 'category': 'Lácteos', 'stock': 88, 'price': 1.15},
      {'name': 'Leche de Avena Hacendado 1L', 'category': 'Lácteos', 'stock': 92, 'price': 1.25},
      {'name': 'Leche de Soja Hacendado 1L', 'category': 'Lácteos', 'stock': 200, 'price': 1.20},
      {'name': 'Leche de Almendras Hacendado 1L', 'category': 'Lácteos', 'stock': 154, 'price': 1.35},
      {'name': 'Yogur Natural Hacendado Pack 8', 'category': 'Lácteos', 'stock': 210, 'price': 1.50},
      {'name': 'Yogur Griego Hacendado Pack 4', 'category': 'Lácteos', 'stock': 98, 'price': 1.80},
      {'name': 'Yogur 0% Hacendado Pack 8', 'category': 'Lácteos', 'stock': 7, 'price': 1.60},
      {'name': 'Yogur Bifidus Hacendado Pack 8', 'category': 'Lácteos', 'stock': 130, 'price': 1.70},
      {'name': 'Yogur con Frutas Hacendado Pack 8', 'category': 'Lácteos', 'stock': 175, 'price': 1.65},
      {'name': 'Yogur Liquido Hacendado Pack 6', 'category': 'Lácteos', 'stock': 40, 'price': 1.90},
      {'name': 'Queso Tierno Hacendado 500g', 'category': 'Lácteos', 'stock': 65, 'price': 3.50},
      {'name': 'Queso Semicurado Hacendado 500g', 'category': 'Lácteos', 'stock': 12, 'price': 4.20},
      {'name': 'Queso Curado Hacendado 500g', 'category': 'Lácteos', 'stock': 55, 'price': 4.80},
      {'name': 'Queso Rallado Hacendado 200g', 'category': 'Lácteos', 'stock': 90, 'price': 1.95},
      {'name': 'Queso en Lonchas Hacendado 200g', 'category': 'Lácteos', 'stock': 110, 'price': 1.75},
      {'name': 'Queso Fresco 0% Hacendado 250g', 'category': 'Lácteos', 'stock': 25, 'price': 1.25},
      {'name': 'Queso Mozzarella Hacendado 125g', 'category': 'Lácteos', 'stock': 140, 'price': 0.95},
      {'name': 'Queso Parmesano Hacendado 200g', 'category': 'Lácteos', 'stock': 10, 'price': 3.20},
      {'name': 'Mantequilla Hacendado 250g', 'category': 'Lácteos', 'stock': 77, 'price': 1.85},
      {'name': 'Margarina Hacendado 500g', 'category': 'Lácteos', 'stock': 83, 'price': 1.30},
      {'name': 'Nata para Cocinar Hacendado 200ml', 'category': 'Lácteos', 'stock': 100, 'price': 0.75},
      {'name': 'Nata para Montar Hacendado 200ml', 'category': 'Lácteos', 'stock': 60, 'price': 0.85},
      {'name': 'Huevos Camperos Pack 12', 'category': 'Lácteos', 'stock': 190, 'price': 2.85},
      {'name': 'Huevos Blancos Pack 12', 'category': 'Lácteos', 'stock': 22, 'price': 1.95},
      {'name': 'Huevos Ecológicos Pack 6', 'category': 'Lácteos', 'stock': 49, 'price': 2.40},
      {'name': 'Flan de Huevo Hacendado Pack 4', 'category': 'Lácteos', 'stock': 160, 'price': 1.35},
      {'name': 'Natillas Hacendado Pack 4', 'category': 'Lácteos', 'stock': 33, 'price': 1.25},

      // CARNES Y EMBUTIDOS (25 productos)
      {'name': 'Pollo Entero Fresco', 'category': 'Carnes', 'stock': 8, 'price': 4.50},
      {'name': 'Pechuga de Pollo Fileteada', 'category': 'Carnes', 'stock': 51, 'price': 5.80},
      {'name': 'Muslos de Pollo', 'category': 'Carnes', 'stock': 12, 'price': 3.20},
      {'name': 'Alitas de Pollo', 'category': 'Carnes', 'stock': 35, 'price': 2.95},
      {'name': 'Carne Picada de Ternera', 'category': 'Carnes', 'stock': 18, 'price': 6.50},
      {'name': 'Filete de Ternera', 'category': 'Carnes', 'stock': 0, 'price': 9.80},
      {'name': 'Solomillo de Cerdo', 'category': 'Carnes', 'stock': 10, 'price': 7.20},
      {'name': 'Chuletas de Cerdo', 'category': 'Carnes', 'stock': 29, 'price': 5.40},
      {'name': 'Costillas de Cerdo', 'category': 'Carnes', 'stock': 44, 'price': 4.80},
      {'name': 'Carne Picada de Cerdo', 'category': 'Carnes', 'stock': 58, 'price': 4.90},
      {'name': 'Jamón Serrano Loncheado Hacendado 100g', 'category': 'Embutidos', 'stock': 75, 'price': 2.85},
      {'name': 'Jamón York Loncheado Hacendado 180g', 'category': 'Embutidos', 'stock': 91, 'price': 1.95},
      {'name': 'Pavo Loncheado Hacendado 180g', 'category': 'Embutidos', 'stock': 11, 'price': 2.10},
      {'name': 'Chorizo Extra Hacendado', 'category': 'Embutidos', 'stock': 33, 'price': 3.45},
      {'name': 'Salchichón Extra Hacendado', 'category': 'Embutidos', 'stock': 68, 'price': 3.60},
      {'name': 'Fuet Catalán Hacendado', 'category': 'Embutidos', 'stock': 82, 'price': 2.95},
      {'name': 'Salchichas Frankfurt Hacendado Pack 8', 'category': 'Embutidos', 'stock': 125, 'price': 1.65},
      {'name': 'Bacon Loncheado Hacendado 200g', 'category': 'Embutidos', 'stock': 22, 'price': 2.45},
      {'name': 'Lomo Embuchado Hacendado', 'category': 'Embutidos', 'stock': 45, 'price': 4.20},
      {'name': 'Mortadela Hacendado', 'category': 'Embutidos', 'stock': 99, 'price': 1.35},
      {'name': 'Salami Italiano Hacendado', 'category': 'Embutidos', 'stock': 14, 'price': 3.75},
      {'name': 'Paté de Hígado Hacendado', 'category': 'Embutidos', 'stock': 5, 'price': 1.20},
      {'name': 'Sobrasada Mallorquina Hacendado', 'category': 'Embutidos', 'stock': 28, 'price': 2.85},
      {'name': 'Morcilla de Burgos', 'category': 'Embutidos', 'stock': 39, 'price': 2.40},
      {'name': 'Butifarra Catalana', 'category': 'Embutidos', 'stock': 16, 'price': 2.95},

      // PESCADOS Y MARISCOS (20 productos)
      {'name': 'Salmón Fresco Noruego', 'category': 'Pescados', 'stock': 15, 'price': 12.50},
      {'name': 'Merluza en Filetes Congelada', 'category': 'Pescados', 'stock': 42, 'price': 7.80},
      {'name': 'Dorada Fresca', 'category': 'Pescados', 'stock': 9, 'price': 8.90},
      {'name': 'Lubina Fresca', 'category': 'Pescados', 'stock': 31, 'price': 9.40},
      {'name': 'Atún Claro en Aceite Hacendado Pack 3', 'category': 'Pescados', 'stock': 145, 'price': 2.95},
      {'name': 'Atún Claro al Natural Hacendado Pack 3', 'category': 'Pescados', 'stock': 0, 'price': 2.85},
      {'name': 'Sardinas en Aceite Hacendado', 'category': 'Pescados', 'stock': 88, 'price': 1.45},
      {'name': 'Mejillones al Natural Hacendado', 'category': 'Pescados', 'stock': 50, 'price': 1.85},
      {'name': 'Berberechos al Natural Hacendado', 'category': 'Pescados', 'stock': 12, 'price': 2.95},
      {'name': 'Gambas Cocidas Congeladas 400g', 'category': 'Pescados', 'stock': 28, 'price': 6.50},
      {'name': 'Langostinos Cocidos Congelados 400g', 'category': 'Pescados', 'stock': 19, 'price': 8.90},
      {'name': 'Calamares Congelados 400g', 'category': 'Pescados', 'stock': 45, 'price': 4.95},
      {'name': 'Sepia Congelada 400g', 'category': 'Pescados', 'stock': 17, 'price': 5.80},
      {'name': 'Pulpo Cocido Congelado 500g', 'category': 'Pescados', 'stock': 6, 'price': 9.95},
      {'name': 'Bacalao Salado Desalado', 'category': 'Pescados', 'stock': 30, 'price': 11.50},
      {'name': 'Anchoas en Aceite Hacendado', 'category': 'Pescados', 'stock': 110, 'price': 3.45},
      {'name': 'Caballa en Aceite Hacendado', 'category': 'Pescados', 'stock': 75, 'price': 1.95},
      {'name': 'Palitos de Cangrejo Hacendado', 'category': 'Pescados', 'stock': 55, 'price': 2.65},
      {'name': 'Surimi Hacendado 200g', 'category': 'Pescados', 'stock': 99, 'price': 1.85},
      {'name': 'Gulas del Norte Hacendado', 'category': 'Pescados', 'stock': 14, 'price': 3.95},

      // FRUTAS Y VERDURAS (30 productos)
      {'name': 'Plátanos de Canarias 1kg', 'category': 'Frutas', 'stock': 70, 'price': 1.45},
      {'name': 'Manzanas Golden 1kg', 'category': 'Frutas', 'stock': 85, 'price': 1.65},
      {'name': 'Manzanas Fuji 1kg', 'category': 'Frutas', 'stock': 12, 'price': 1.75},
      {'name': 'Peras Conference 1kg', 'category': 'Frutas', 'stock': 40, 'price': 1.85},
      {'name': 'Naranjas de Valencia 2kg', 'category': 'Frutas', 'stock': 110, 'price': 2.50},
      {'name': 'Mandarinas 1kg', 'category': 'Frutas', 'stock': 28, 'price': 1.95},
      {'name': 'Limones 500g', 'category': 'Frutas', 'stock': 60, 'price': 0.95},
      {'name': 'Kiwis Pack 6', 'category': 'Frutas', 'stock': 5, 'price': 2.45},
      {'name': 'Fresas 500g', 'category': 'Frutas', 'stock': 0, 'price': 2.95},
      {'name': 'Uvas Blancas 500g', 'category': 'Frutas', 'stock': 35, 'price': 2.35},
      {'name': 'Uvas Negras 500g', 'category': 'Frutas', 'stock': 18, 'price': 2.40},
      {'name': 'Sandía (unidad)', 'category': 'Frutas', 'stock': 50, 'price': 3.50},
      {'name': 'Melón (unidad)', 'category': 'Frutas', 'stock': 42, 'price': 2.80},
      {'name': 'Aguacate Pack 2', 'category': 'Frutas', 'stock': 8, 'price': 2.25},
      {'name': 'Piña (unidad)', 'category': 'Frutas', 'stock': 22, 'price': 1.95},
      {'name': 'Tomates 1kg', 'category': 'Verduras', 'stock': 75, 'price': 1.85},
      {'name': 'Tomates Cherry 250g', 'category': 'Verduras', 'stock': 10, 'price': 1.45},
      {'name': 'Lechuga Iceberg (unidad)', 'category': 'Verduras', 'stock': 55, 'price': 0.65},
      {'name': 'Lechuga Romana (unidad)', 'category': 'Verduras', 'stock': 33, 'price': 0.75},
      {'name': 'Espinacas Frescas 300g', 'category': 'Verduras', 'stock': 48, 'price': 1.25},
      {'name': 'Brócoli (unidad)', 'category': 'Verduras', 'stock': 14, 'price': 1.35},
      {'name': 'Coliflor (unidad)', 'category': 'Verduras', 'stock': 29, 'price': 1.45},
      {'name': 'Zanahorias 1kg', 'category': 'Verduras', 'stock': 95, 'price': 0.95},
      {'name': 'Calabacín 500g', 'category': 'Verduras', 'stock': 25, 'price': 1.15},
      {'name': 'Berenjena (unidad)', 'category': 'Verduras', 'stock': 6, 'price': 0.85},
      {'name': 'Pimientos Rojos 500g', 'category': 'Verduras', 'stock': 38, 'price': 1.65},
      {'name': 'Pimientos Verdes 500g', 'category': 'Verduras', 'stock': 45, 'price': 1.45},
      {'name': 'Pepino (unidad)', 'category': 'Verduras', 'stock': 51, 'price': 0.55},
      {'name': 'Cebolla 1kg', 'category': 'Verduras', 'stock': 130, 'price': 0.85},
      {'name': 'Patatas 2kg', 'category': 'Verduras', 'stock': 150, 'price': 1.95},

      // PANADERÍA Y PASTELERÍA (20 productos)
      {'name': 'Pan de Molde Integral Hacendado', 'category': 'Panadería', 'stock': 160, 'price': 0.95},
      {'name': 'Pan de Molde Blanco Hacendado', 'category': 'Panadería', 'stock': 195, 'price': 0.85},
      {'name': 'Pan Barra Rústica', 'category': 'Panadería', 'stock': 12, 'price': 0.65},
      {'name': 'Panecillos Integrales Pack 6', 'category': 'Panadería', 'stock': 88, 'price': 1.35},
      {'name': 'Pan de Hamburguesa Pack 4', 'category': 'Panadería', 'stock': 90, 'price': 1.15},
      {'name': 'Pan de Perrito Pack 6', 'category': 'Panadería', 'stock': 75, 'price': 1.25},
      {'name': 'Pan de Ajo Congelado Hacendado', 'category': 'Panadería', 'stock': 35, 'price': 1.45},
      {'name': 'Baguette Tradicional', 'category': 'Panadería', 'stock': 5, 'price': 0.75},
      {'name': 'Pan Sin Gluten Hacendado', 'category': 'Panadería', 'stock': 18, 'price': 2.95},
      {'name': 'Croissant Pack 4', 'category': 'Pastelería', 'stock': 110, 'price': 1.65},
      {'name': 'Napolitanas Chocolate Pack 4', 'category': 'Pastelería', 'stock': 82, 'price': 1.75},
      {'name': 'Ensaimada Mallorquina', 'category': 'Pastelería', 'stock': 42, 'price': 2.45},
      {'name': 'Magdalenas Hacendado Pack 10', 'category': 'Pastelería', 'stock': 130, 'price': 1.85},
      {'name': 'Sobaos Pasiegos Pack 6', 'category': 'Pastelería', 'stock': 14, 'price': 2.15},
      {'name': 'Bizcocho Natural Hacendado', 'category': 'Pastelería', 'stock': 55, 'price': 1.95},
      {'name': 'Palmeras de Chocolate Pack 4', 'category': 'Pastelería', 'stock': 29, 'price': 1.55},
      {'name': 'Donuts Hacendado Pack 4', 'category': 'Pastelería', 'stock': 45, 'price': 1.65},
      {'name': 'Galletas María Hacendado 800g', 'category': 'Pastelería', 'stock': 170, 'price': 1.35},
      {'name': 'Galletas Digestive Hacendado 400g', 'category': 'Pastelería', 'stock': 68, 'price': 1.45},
      {'name': 'Galletas Príncipe Hacendado Pack 6', 'category': 'Pastelería', 'stock': 0, 'price': 1.95},

      // PASTA, ARROZ Y LEGUMBRES (25 productos)
      {'name': 'Pasta Macarrones Hacendado 500g', 'category': 'Pasta', 'stock': 115, 'price': 0.75},
      {'name': 'Pasta Espaguetis Hacendado 500g', 'category': 'Pasta', 'stock': 140, 'price': 0.75},
      {'name': 'Pasta Espirales Hacendado 500g', 'category': 'Pasta', 'stock': 70, 'price': 0.75},
      {'name': 'Pasta Lazos Hacendado 500g', 'category': 'Pasta', 'stock': 25, 'price': 0.75},
      {'name': 'Pasta Penne Hacendado 500g', 'category': 'Pasta', 'stock': 98, 'price': 0.75},
      {'name': 'Pasta Integral Hacendado 500g', 'category': 'Pasta', 'stock': 40, 'price': 0.95},
      {'name': 'Pasta Fettuccine Hacendado 500g', 'category': 'Pasta', 'stock': 10, 'price': 0.85},
      {'name': 'Pasta Cannelloni Hacendado', 'category': 'Pasta', 'stock': 58, 'price': 1.15},
      {'name': 'Lasaña Placas Hacendado', 'category': 'Pasta', 'stock': 82, 'price': 1.25},
      {'name': 'Arroz Largo Hacendado 1kg', 'category': 'Arroz', 'stock': 160, 'price': 1.15},
      {'name': 'Arroz Redondo Hacendado 1kg', 'category': 'Arroz', 'stock': 185, 'price': 1.15},
      {'name': 'Arroz Basmati Hacendado 500g', 'category': 'Arroz', 'stock': 99, 'price': 1.45},
      {'name': 'Arroz Integral Hacendado 1kg', 'category': 'Arroz', 'stock': 12, 'price': 1.35},
      {'name': 'Arroz Bomba Hacendado 500g', 'category': 'Arroz', 'stock': 44, 'price': 1.85},
      {'name': 'Lentejas Hacendado 1kg', 'category': 'Legumbres', 'stock': 130, 'price': 1.25},
      {'name': 'Garbanzos Hacendado 1kg', 'category': 'Legumbres', 'stock': 175, 'price': 1.35},
      {'name': 'Alubias Blancas Hacendado 1kg', 'category': 'Legumbres', 'stock': 8, 'price': 1.45},
      {'name': 'Alubias Pintas Hacendado 1kg', 'category': 'Legumbres', 'stock': 35, 'price': 1.45},
      {'name': 'Judías Verdes Hacendado 1kg', 'category': 'Legumbres', 'stock': 55, 'price': 1.55},
      {'name': 'Lentejas Cocidas Hacendado Bote', 'category': 'Legumbres', 'stock': 100, 'price': 0.85},
      {'name': 'Garbanzos Cocidos Hacendado Bote', 'category': 'Legumbres', 'stock': 77, 'price': 0.85},
      {'name': 'Alubias Cocidas Hacendado Bote', 'category': 'Legumbres', 'stock': 28, 'price': 0.85},
      {'name': 'Quinoa Hacendado 500g', 'category': 'Cereales', 'stock': 49, 'price': 2.45},
      {'name': 'Cous Cous Hacendado 500g', 'category': 'Cereales', 'stock': 15, 'price': 1.65},
      {'name': 'Bulgur Hacendado 500g', 'category': 'Cereales', 'stock': 65, 'price': 1.85},

      // SALSAS Y CONDIMENTOS (20 productos)
      {'name': 'Tomate Frito Hacendado 400g', 'category': 'Salsas', 'stock': 122, 'price': 0.85},
      {'name': 'Tomate Triturado Hacendado 400g', 'category': 'Salsas', 'stock': 98, 'price': 0.75},
      {'name': 'Mayonesa Hacendado 450ml', 'category': 'Salsas', 'stock': 15, 'price': 1.45},
      {'name': 'Ketchup Hacendado 560g', 'category': 'Salsas', 'stock': 80, 'price': 1.25},
      {'name': 'Mostaza Hacendado 290g', 'category': 'Salsas', 'stock': 5, 'price': 0.95},
      {'name': 'Salsa Barbacoa Hacendado', 'category': 'Salsas', 'stock': 45, 'price': 1.35},
      {'name': 'Salsa César Hacendado', 'category': 'Salsas', 'stock': 30, 'price': 1.65},
      {'name': 'Salsa de Soja Hacendado', 'category': 'Salsas', 'stock': 110, 'price': 1.15},
      {'name': 'Aceite de Oliva Virgen Extra Hacendado 1L', 'category': 'Aceites', 'stock': 75, 'price': 4.95},
      {'name': 'Aceite de Girasol Hacendado 1L', 'category': 'Aceites', 'stock': 140, 'price': 1.85},
      {'name': 'Vinagre de Vino Hacendado 500ml', 'category': 'Condimentos', 'stock': 65, 'price': 0.75},
      {'name': 'Vinagre de Manzana Hacendado 500ml', 'category': 'Condimentos', 'stock': 28, 'price': 0.95},
      {'name': 'Sal Marina Hacendado 1kg', 'category': 'Condimentos', 'stock': 190, 'price': 0.45},
      {'name': 'Pimienta Negra Hacendado', 'category': 'Condimentos', 'stock': 12, 'price': 1.25},
      {'name': 'Oregano Hacendado', 'category': 'Condimentos', 'stock': 50, 'price': 0.85},
      {'name': 'Albahaca Hacendado', 'category': 'Condimentos', 'stock': 99, 'price': 0.85},
      {'name': 'Ajo en Polvo Hacendado', 'category': 'Condimentos', 'stock': 33, 'price': 1.15},
      {'name': 'Caldo de Pollo Hacendado Pack 4', 'category': 'Caldos', 'stock': 77, 'price': 1.45},
      {'name': 'Caldo de Verduras Hacendado Pack 4', 'category': 'Caldos', 'stock': 49, 'price': 1.45},
      {'name': 'Caldo de Carne Hacendado Pack 4', 'category': 'Caldos', 'stock': 22, 'price': 1.45},

      // BEBIDAS (30 productos)
      {'name': 'Agua Mineral Hacendado 1.5L', 'category': 'Bebidas', 'stock': 25, 'price': 0.35},
      {'name': 'Agua con Gas Hacendado 1.5L', 'category': 'Bebidas', 'stock': 105, 'price': 0.40},
      {'name': 'Zumo de Naranja Hacendado 1L', 'category': 'Bebidas', 'stock': 170, 'price': 1.25},
      {'name': 'Zumo de Piña Hacendado 1L', 'category': 'Bebidas', 'stock': 60, 'price': 1.25},
      {'name': 'Zumo de Manzana Hacendado 1L', 'category': 'Bebidas', 'stock': 88, 'price': 1.25},
      {'name': 'Zumo Multifrutas Hacendado 1L', 'category': 'Bebidas', 'stock': 12, 'price': 1.25},
      {'name': 'Refresco de Cola Hacendado 2L', 'category': 'Bebidas', 'stock': 180, 'price': 0.85},
      {'name': 'Refresco de Naranja Hacendado 2L', 'category': 'Bebidas', 'stock': 145, 'price': 0.85},
      {'name': 'Refresco de Limón Hacendado 2L', 'category': 'Bebidas', 'stock': 7, 'price': 0.85},
      {'name': 'Cerveza Steinburg Pack 6', 'category': 'Bebidas', 'stock': 115, 'price': 2.45},
      {'name': 'Cerveza Alhambra Pack 6', 'category': 'Bebidas', 'stock': 40, 'price': 3.95},
      {'name': 'Cerveza Sin Alcohol Hacendado Pack 6', 'category': 'Bebidas', 'stock': 22, 'price': 2.25},
      {'name': 'Vino Tinto Tempranillo Hacendado', 'category': 'Bebidas', 'stock': 55, 'price': 2.95},
      {'name': 'Vino Blanco Verdejo Hacendado', 'category': 'Bebidas', 'stock': 18, 'price': 2.95},
      {'name': 'Vino Rosado Hacendado', 'category': 'Bebidas', 'stock': 35, 'price': 2.95},
      {'name': 'Cava Brut Nature Hacendado', 'category': 'Bebidas', 'stock': 8, 'price': 4.95},
      {'name': 'Café Molido Natural Hacendado 250g', 'category': 'Bebidas', 'stock': 95, 'price': 2.85},
      {'name': 'Café Molido Mezcla Hacendado 250g', 'category': 'Bebidas', 'stock': 130, 'price': 2.65},
      {'name': 'Café Descafeinado Hacendado 250g', 'category': 'Bebidas', 'stock': 15, 'price': 2.95},
      {'name': 'Café Soluble Hacendado 200g', 'category': 'Bebidas', 'stock': 49, 'price': 3.45},
      {'name': 'Cápsulas de Café Hacendado Pack 10', 'category': 'Bebidas', 'stock': 68, 'price': 2.95},
      {'name': 'Té Negro Hacendado Pack 25', 'category': 'Bebidas', 'stock': 77, 'price': 1.45},
      {'name': 'Té Verde Hacendado Pack 25', 'category': 'Bebidas', 'stock': 29, 'price': 1.45},
      {'name': 'Infusión Manzanilla Hacendado Pack 25', 'category': 'Bebidas', 'stock': 99, 'price': 1.25},
      {'name': 'Infusión Poleo-Menta Hacendado Pack 25', 'category': 'Bebidas', 'stock': 14, 'price': 1.25},
      {'name': 'Cola Cao Original 800g', 'category': 'Bebidas', 'stock': 82, 'price': 3.95},
      {'name': 'Nesquik Chocolate 800g', 'category': 'Bebidas', 'stock': 51, 'price': 4.25},
      {'name': 'Horchata de Chufa Valenciana 1L', 'category': 'Bebidas', 'stock': 10, 'price': 1.95},
      {'name': 'Granizado de Limón 1L', 'category': 'Bebidas', 'stock': 45, 'price': 1.75},
      {'name': 'Tónica Hacendado 1L', 'category': 'Bebidas', 'stock': 2, 'price': 0.95},
    ];
  }
}