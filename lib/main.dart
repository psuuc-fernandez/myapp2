import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Product {
  String sku;
  String name;
  String description;
  double price;
  double discountedPrice;
  int quantity;
  String manufacturer;
  String imageUrl;

  Product({
    required this.sku,
    required this.name,
    required this.description,
    required this.price,
    required this.discountedPrice,
    required this.quantity,
    required this.manufacturer,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'name': name,
      'description': description,
      'price': price,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'manufacturer': manufacturer,
      'imageUrl': imageUrl,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      sku: map['sku'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      discountedPrice: map['discountedPrice'],
      quantity: map['quantity'],
      manufacturer: map['manufacturer'],
      imageUrl: map['imageUrl'],
    );
  }
}

class DatabaseHelper {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) {
      return _database!;
    }

    _database = await openDatabase(
      join(await getDatabasesPath(), 'products.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE products(sku TEXT PRIMARY KEY, name TEXT, description TEXT, price REAL, discountedPrice REAL, quantity INTEGER, manufacturer TEXT, imageUrl TEXT)',
        );
      },
      version: 1,
    );
    return _database!;
  }

  static Future<void> insertProduct(Product product) async {
    final db = await getDatabase();
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Product>> getProducts() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  static Future<void> updateProduct(Product product) async {
    final db = await getDatabase();
    await db.update(
      'products',
      product.toMap(),
      where: 'sku = ?',
      whereArgs: [product.sku],
    );
  }

  static Future<void> deleteProduct(String sku) async {
    final db = await getDatabase();
    await db.delete(
      'products',
      where: 'sku = ?',
      whereArgs: [sku],
    );
  }
}

void main() {
  runApp(ProductManagementApp());
}

class ProductManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Management',
      debugShowCheckedModeBanner: false,
      home: ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    List<Product> loadedProducts = await DatabaseHelper.getProducts();
    setState(() {
      products = loadedProducts;
    });
  }

  void _navigateToAddProductScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddProductScreen(onAddProduct: _addProduct),
      ),
    );
  }

  void _addProduct(Product product) {
    DatabaseHelper.insertProduct(product);
    _loadProducts();
  }

  void _editProduct(int index, Product product) {
    DatabaseHelper.updateProduct(product);
    _loadProducts();
  }

  void _deleteProduct(String sku) {
    DatabaseHelper.deleteProduct(sku);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product List'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _navigateToAddProductScreen(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('SKU: ${product.sku}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  color: Colors.orange,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddProductScreen(
                          onAddProduct: (newProduct) {
                            _editProduct(index, newProduct);
                          },
                          product: product,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () => _deleteProduct(product.sku),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AddProductScreen extends StatefulWidget {
  final Function(Product) onAddProduct;
  final Product? product;

  AddProductScreen({required this.onAddProduct, this.product});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  late TextEditingController skuController;
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController discountedPriceController;
  late TextEditingController quantityController;
  late TextEditingController manufacturerController;
  late TextEditingController imageUrlController;

  @override
  void initState() {
    super.initState();
    skuController = TextEditingController(text: widget.product?.sku);
    nameController = TextEditingController(text: widget.product?.name);
    descriptionController = TextEditingController(text: widget.product?.description);
    priceController = TextEditingController(text: widget.product?.price.toString());
    discountedPriceController = TextEditingController(text: widget.product?.discountedPrice.toString());
    quantityController = TextEditingController(text: widget.product?.quantity.toString());
    manufacturerController = TextEditingController(text: widget.product?.manufacturer);
    imageUrlController = TextEditingController(text: widget.product?.imageUrl);
  }

  void saveProduct(BuildContext context) {
    final String sku = skuController.text;
    final String name = nameController.text;
    final String description = descriptionController.text;
    final double price = double.tryParse(priceController.text) ?? 0.0;
    final double discountedPrice = double.tryParse(discountedPriceController.text) ?? 0.0;
    final int quantity = int.tryParse(quantityController.text) ?? 0;
    final String manufacturer = manufacturerController.text;
    final String imageUrl = imageUrlController.text;

    if (sku.isNotEmpty && name.isNotEmpty && description.isNotEmpty) {
      final Product newProduct = Product(
        sku: sku,
        name: name,
        description: description,
        price: price,
        discountedPrice: discountedPrice,
        quantity: quantity,
        manufacturer: manufacturer,
        imageUrl: imageUrl,
      );
      widget.onAddProduct(newProduct);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: Colors.purple,
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: skuController,
              decoration: InputDecoration(
                labelText: 'SKU',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: discountedPriceController,
              decoration: InputDecoration(
                labelText: 'Discounted Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: manufacturerController,
              decoration: InputDecoration(
                labelText: 'Manufacturer',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: imageUrlController,
              decoration: InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => saveProduct(context),
              child: Text(widget.product == null ? 'Add Product' : 'Update Product'),
            ),
          ],
        ),
      ),
    );
  }
}
