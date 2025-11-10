import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de datos para Customer
class Customer {
  final int? id;
  final DateTime? createdAt;
  final String? name;
  final String? email;
  final String? phoneNumber;

  Customer({
    this.id,
    this.createdAt,
    this.name,
    this.email,
    this.phoneNumber,
  });

  /// Crear Customer desde JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
    );
  }

  /// Convertir Customer a JSON (para insert/update)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      // created_at se genera automáticamente, no lo incluimos
    };
  }

  /// Convertir a JSON solo con campos modificables
  Map<String, dynamic> toJsonForUpdate() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };
  }

  /// Copiar con nuevos valores
  Customer copyWith({
    int? id,
    DateTime? createdAt,
    String? name,
    String? email,
    String? phoneNumber,
  }) {
    return Customer(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, email: $email, phone: $phoneNumber, createdAt: $createdAt)';
  }
}

/// Servicio para gestionar usuarios (Customers)
class UserService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'Customers';

  // ============================================
  // OBTENER USUARIOS
  // ============================================

  /// Obtener todos los usuarios
  Future<List<Customer>> getAllUsers() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error al obtener usuarios: $e');
      rethrow;
    }
  }

  /// Obtener un usuario por ID
  Future<Customer?> getUserById(int id) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Customer.fromJson(response);
    } catch (e) {
      print('❌ Error al obtener usuario con ID $id: $e');
      rethrow;
    }
  }

  /// Obtener un usuario por email
  Future<Customer?> getUserByEmail(String email) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) return null;
      return Customer.fromJson(response);
    } catch (e) {
      print('❌ Error al obtener usuario con email $email: $e');
      rethrow;
    }
  }

  /// Obtener un usuario por teléfono
  Future<Customer?> getUserByPhone(String phone) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('phone_number', phone)
          .maybeSingle();

      if (response == null) return null;
      return Customer.fromJson(response);
    } catch (e) {
      print('❌ Error al obtener usuario con teléfono $phone: $e');
      rethrow;
    }
  }

  /// Buscar usuarios por nombre (búsqueda parcial)
  Future<List<Customer>> searchUsersByName(String name) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .ilike('name', '%$name%')
          .order('name');

      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error al buscar usuarios por nombre "$name": $e');
      rethrow;
    }
  }

  /// Buscar usuarios por email (búsqueda parcial)
  Future<List<Customer>> searchUsersByEmail(String email) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .ilike('email', '%$email%')
          .order('email');

      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error al buscar usuarios por email "$email": $e');
      rethrow;
    }
  }

  /// Buscar usuarios por cualquier campo
  Future<List<Customer>> searchUsers(String query) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%,phone_number.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error al buscar usuarios con query "$query": $e');
      rethrow;
    }
  }

  /// Obtener usuarios creados después de una fecha
  Future<List<Customer>> getUsersCreatedAfter(DateTime date) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .gte('created_at', date.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error al obtener usuarios creados después de $date: $e');
      rethrow;
    }
  }

  /// Obtener usuarios creados entre dos fechas
  Future<List<Customer>> getUsersCreatedBetween(DateTime start, DateTime end) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error al obtener usuarios creados entre $start y $end: $e');
      rethrow;
    }
  }

  /// Obtener usuarios con paginación
  Future<List<Customer>> getUsersPaginated({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      final response = await _client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false)
          .range(from, to);

      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error al obtener usuarios paginados (página $page): $e');
      rethrow;
    }
  }

  /// Obtener usuarios con emails registrados
  Future<List<Customer>> getUsersWithEmail() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .not('email', 'is', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error al obtener usuarios con email: $e');
      rethrow;
    }
  }

  /// Obtener usuarios sin email registrado
  Future<List<Customer>> getUsersWithoutEmail() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .isFilter('email', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error al obtener usuarios sin email: $e');
      rethrow;
    }
  }

  // ============================================
  // INSERTAR USUARIOS
  // ============================================

  /// Insertar un nuevo usuario
  Future<Customer> insertUser({
    required String name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final userData = {
        'name': name,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };

      final response = await _client
          .from(_tableName)
          .insert(userData)
          .select()
          .single();

      print('✅ Usuario creado: ${response['name']} (ID: ${response['id']})');
      return Customer.fromJson(response);
    } catch (e) {
      print('❌ Error al insertar usuario "$name": $e');
      rethrow;
    }
  }

  /// Insertar usuario desde objeto Customer
  Future<Customer> insertUserFromObject(Customer customer) async {
    try {
      final response = await _client
          .from(_tableName)
          .insert(customer.toJson())
          .select()
          .single();

      print('✅ Usuario creado: ${response['name']} (ID: ${response['id']})');
      return Customer.fromJson(response);
    } catch (e) {
      print('❌ Error al insertar usuario: $e');
      rethrow;
    }
  }

  /// Insertar múltiples usuarios
  Future<List<Customer>> insertUsers(List<Customer> customers) async {
    try {
      final usersData = customers.map((c) => c.toJson()).toList();

      final response = await _client
          .from(_tableName)
          .insert(usersData)
          .select();

      print('✅ ${customers.length} usuarios creados');
      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error al insertar múltiples usuarios: $e');
      rethrow;
    }
  }

  // ============================================
  // MODIFICAR USUARIOS
  // ============================================

  /// Actualizar un usuario por ID
  Future<Customer> updateUser({
    required int id,
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;

      if (updateData.isEmpty) {
        throw Exception('No hay datos para actualizar');
      }

      final response = await _client
          .from(_tableName)
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      print('✅ Usuario actualizado: ID $id');
      return Customer.fromJson(response);
    } catch (e) {
      print('❌ Error al actualizar usuario con ID $id: $e');
      rethrow;
    }
  }

  /// Actualizar usuario con objeto Customer
  Future<Customer> updateUserFromObject(Customer customer) async {
    if (customer.id == null) {
      throw Exception('El usuario debe tener un ID para ser actualizado');
    }

    try {
      final response = await _client
          .from(_tableName)
          .update(customer.toJsonForUpdate())
          .eq('id', customer.id!)
          .select()
          .single();

      print('✅ Usuario actualizado: ID ${customer.id}');
      return Customer.fromJson(response);
    } catch (e) {
      print('❌ Error al actualizar usuario: $e');
      rethrow;
    }
  }

  /// Actualizar solo el nombre
  Future<Customer> updateUserName(int id, String name) async {
    try {
      final response = await _client
          .from(_tableName)
          .update({'name': name})
          .eq('id', id)
          .select()
          .single();

      print('✅ Nombre actualizado: ID $id -> "$name"');
      return Customer.fromJson(response);
    } catch (e) {
      print('❌ Error al actualizar nombre del usuario con ID $id: $e');
      rethrow;
    }
  }

  /// Actualizar solo el email
  Future<Customer> updateUserEmail(int id, String email) async {
    try {
      final response = await _client
          .from(_tableName)
          .update({'email': email})
          .eq('id', id)
          .select()
          .single();

      print('✅ Email actualizado: ID $id -> "$email"');
      return Customer.fromJson(response);
    } catch (e) {
      print('❌ Error al actualizar email del usuario con ID $id: $e');
      rethrow;
    }
  }

  /// Actualizar solo el teléfono
  Future<Customer> updateUserPhone(int id, String phoneNumber) async {
    try {
      final response = await _client
          .from(_tableName)
          .update({'phone_number': phoneNumber})
          .eq('id', id)
          .select()
          .single();

      print('✅ Teléfono actualizado: ID $id -> "$phoneNumber"');
      return Customer.fromJson(response);
    } catch (e) {
      print('❌ Error al actualizar teléfono del usuario con ID $id: $e');
      rethrow;
    }
  }

  // ============================================
  // ELIMINAR USUARIOS
  // ============================================

  /// Eliminar un usuario por ID
  Future<void> deleteUser(int id) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('id', id);

      print('✅ Usuario eliminado: ID $id');
    } catch (e) {
      print('❌ Error al eliminar usuario con ID $id: $e');
      rethrow;
    }
  }

  /// Eliminar múltiples usuarios por IDs
  Future<void> deleteUsers(List<int> ids) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .inFilter('id', ids);

      print('✅ ${ids.length} usuarios eliminados');
    } catch (e) {
      print('❌ Error al eliminar múltiples usuarios: $e');
      rethrow;
    }
  }

  /// Eliminar usuario por email
  Future<void> deleteUserByEmail(String email) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('email', email);

      print('✅ Usuario eliminado: email $email');
    } catch (e) {
      print('❌ Error al eliminar usuario con email $email: $e');
      rethrow;
    }
  }

  /// Eliminar usuarios sin email
  Future<void> deleteUsersWithoutEmail() async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .isFilter('email', null);

      print('✅ Usuarios sin email eliminados');
    } catch (e) {
      print('❌ Error al eliminar usuarios sin email: $e');
      rethrow;
    }
  }

  /// Eliminar usuarios creados antes de una fecha
  Future<void> deleteUsersCreatedBefore(DateTime date) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .lt('created_at', date.toIso8601String());

      print('✅ Usuarios creados antes de $date eliminados');
    } catch (e) {
      print('❌ Error al eliminar usuarios creados antes de $date: $e');
      rethrow;
    }
  }

  /// Eliminar todos los usuarios (¡CUIDADO!)
  Future<void> deleteAllUsers() async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .neq('id', 0); // Elimina todos los registros

      print('✅ Todos los usuarios eliminados');
    } catch (e) {
      print('❌ Error al eliminar todos los usuarios: $e');
      rethrow;
    }
  }

  // ============================================
  // MÉTODOS AUXILIARES
  // ============================================

  /// Verificar si existe un usuario por ID
  Future<bool> userExists(int id) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('id')
          .eq('id', id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error al verificar existencia de usuario con ID $id: $e');
      rethrow;
    }
  }

  /// Verificar si existe un usuario con el mismo nombre
  Future<bool> userNameExists(String name) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('id')
          .eq('name', name)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error al verificar existencia de nombre "$name": $e');
      rethrow;
    }
  }

  /// Verificar si existe un usuario con el mismo email
  Future<bool> emailExists(String email) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('id')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error al verificar existencia de email "$email": $e');
      rethrow;
    }
  }

  /// Verificar si existe un usuario con el mismo teléfono
  Future<bool> phoneExists(String phoneNumber) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('id')
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error al verificar existencia de teléfono "$phoneNumber": $e');
      rethrow;
    }
  }

  /// Obtener estadísticas de usuarios
  Future<Map<String, dynamic>> getUsersStats() async {
    try {
      final withEmail = await getUsersWithEmail();
      final withoutEmail = await getUsersWithoutEmail();

      return {
        'total': withEmail.length + withoutEmail.length,
        'with_email': withEmail.length,
        'without_email': withoutEmail.length,
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas de usuarios: $e');
      rethrow;
    }
  }
}