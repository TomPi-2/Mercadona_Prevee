import 'package:flutter/material.dart';
import 'profile.dart';
import 'colors.dart';

class Header extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigate;

  const Header({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          children: [
            // Logo a la izquierda
            InkWell(
              onTap: () => onNavigate(0),
              child: Row(
                children: [
                  SizedBox(
                    width: 300,
                    height: 60,
                    child: Image.asset('assets/mercaLista.png'),
                  ),
                ],
              ),
            ),

            // Espaciador
            const Spacer(),

            // Buscador centrado
            Expanded(
              flex: 2,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar productos, tiendas...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            // Espaciador
            const Spacer(),

            // Botón de Inicio
            TextButton(
              onPressed: () => onNavigate(0),
              style: TextButton.styleFrom(
                backgroundColor: selectedIndex == 0
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Inicio",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: selectedIndex == 0
                      ? AppColors.primary
                      : Colors.black87,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Botón de Recetas
            TextButton(
              onPressed: () => onNavigate(1),
              style: TextButton.styleFrom(
                backgroundColor: selectedIndex == 1
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Recetas",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: selectedIndex == 1
                      ? AppColors.primary
                      : Colors.black87,
                ),
              ),
            ),

            const SizedBox(width: 24),

            // Botón de perfil a la derecha
            const ProfileButton(),
          ],
        ),
      ),
    );
  }
}