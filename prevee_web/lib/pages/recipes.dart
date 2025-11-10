import 'package:flutter/material.dart';

class Recipe {
  final String name;
  final String imageUrl;
  final List<String> ingredients;
  final String procedure;

  Recipe({
    required this.name,
    required this.imageUrl,
    required this.ingredients,
    required this.procedure,
  });
}

class RecipesPage extends StatelessWidget {
  RecipesPage({super.key});

  final List<Recipe> _recipes = [
    Recipe(
      name: 'Paella Valenciana',
      imageUrl: 'assets/paella-valenciana-tradicional.jpg',
      ingredients: [
        'Arroz',
        'Pollo',
        'Conejo',
        'Judías verdes',
        'Garrofón',
        'Azafrán',
        'Aceite de oliva',
      ],
      procedure:
          '1. Sofríe el pollo y conejo\n2. Añade las verduras\n3. Agrega el arroz y el caldo\n4. Cocina a fuego lento 18 minutos',
    ),
    Recipe(
      name: 'Tortilla de Patatas',
      imageUrl: 'assets/tortilla-de-patatas-1.jpg',
      ingredients: ['Patatas', 'Huevos', 'Cebolla', 'Aceite de oliva', 'Sal'],
      procedure:
          '1. Pela y corta las patatas\n2. Fríe en aceite abundante\n3. Bate los huevos\n4. Mezcla y cuaja en la sartén',
    ),
    Recipe(
      name: 'Gazpacho Andaluz',
      imageUrl: 'assets/gazpacho-andaluz.jpg',
      ingredients: [
        'Tomates',
        'Pepino',
        'Pimiento',
        'Ajo',
        'Pan',
        'Aceite',
        'Vinagre',
      ],
      procedure:
          '1. Trocea todas las verduras\n2. Tritura con el pan remojado\n3. Añade aceite y vinagre\n4. Refrigera antes de servir',
    ),
    Recipe(
      name: 'Croquetas de Jamón',
      imageUrl: 'assets/croquetas-de-jamon-y-queso.jpg',
      ingredients: [
        'Jamón serrano',
        'Leche',
        'Harina',
        'Mantequilla',
        'Huevo',
        'Pan rallado',
      ],
      procedure:
          '1. Prepara la bechamel espesa\n2. Añade el jamón picado\n3. Deja enfriar y forma croquetas\n4. Reboza y fríe',
    ),
  ];

  void _showRecipeDetail(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                child: Image.network(
                  recipe.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ingredientes:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...recipe.ingredients.map(
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $i'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Procedimiento:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(recipe.procedure),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Aquí añadirías los ingredientes a la lista de la compra
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingredientes añadidos a la lista'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Añadir a la lista de la compra'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showRecipeDetail(context, recipe),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Image.network(
                      recipe.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
