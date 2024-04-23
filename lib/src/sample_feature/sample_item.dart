import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class Book {
  String id;
  String title;
  String author;
  int year;
  String category;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.year,
    required this.category,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      year: json['year'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'year': year,
      'category': category,
    };
  }
}

class BookManager {
  static const String _keyBooks = 'books';

  static Future<List<Book>> getBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String booksJson = prefs.getString(_keyBooks) ?? '[]';
    List<dynamic> decoded = json.decode(booksJson);
    return decoded.map((item) => Book.fromJson(item)).toList();
  }

  static Future<void> saveBooks(List<Book> books) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String booksJson = json.encode(books.map((book) => book.toJson()).toList());
    await prefs.setString(_keyBooks, booksJson);
  }

  static Future<void> deleteBook(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Book> books = await getBooks();
    books.removeWhere((book) => book.id == id);
    String booksJson = json.encode(books.map((book) => book.toJson()).toList());
    await prefs.setString(_keyBooks, booksJson);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Book Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SampleItemListView(),
    );
  }
}

class SampleItemListView extends StatefulWidget {
  const SampleItemListView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SampleItemListViewState createState() => _SampleItemListViewState();
}

class _SampleItemListViewState extends State<SampleItemListView> {
  late List<Book> books;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    List<Book> loadedBooks = await BookManager.getBooks();
    setState(() {
      books = loadedBooks;
    });
  }

  Future<void> addBook(Book newBook) async {
    books.add(newBook);
    await BookManager.saveBooks(books);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: BookSearchDelegate(books));
            },
          ),
        ],
      ),
      body: books.isNotEmpty
          ? ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  title: Text(book.title),
                  subtitle: Text('${book.author} - ${book.year}'),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SampleItemDetailsView(books: books, book: book)),
                    );
                    if (result == true) {
                      loadData(); // Cập nhật lại danh sách sau khi quay lại từ trang chi tiết
                    }
                  },
                );
              },
            )
          : const Center(
              child: Text('Chưa có dữ liệu'),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SampleItemUpdate()),
          );
          if (result != null && result is Book) {
            addBook(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SampleItemDetailsView extends StatelessWidget {
  final List<Book> books;
  final Book book;

  const SampleItemDetailsView({super.key, required this.books, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SampleItemUpdate(book: book)),
              );
              if (result != null && result is Book) {
                book.title = result.title;
                book.author = result.author;
                book.year = result.year;
                book.category = result.category;
                await BookManager.saveBooks(books);
                // ignore: use_build_context_synchronously
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: const Text('Are you sure you want to delete this book?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );
              if (confirmed == true) {
                await BookManager.deleteBook(book.id);
                // ignore: use_build_context_synchronously
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${book.title}'),
            Text('Author: ${book.author}'),
            Text('Year: ${book.year}'),
            Text('Category: ${book.category}'),
          ],
        ),
      ),
    );
  }
}

class SampleItemUpdate extends StatefulWidget {
  final Book? book;

  const SampleItemUpdate({super.key, this.book});

  @override
  // ignore: library_private_types_in_public_api
  _SampleItemUpdateState createState() => _SampleItemUpdateState();
}

class _SampleItemUpdateState extends State<SampleItemUpdate> {
  late TextEditingController titleController;
  late TextEditingController authorController;
  late TextEditingController yearController;
  late TextEditingController categoryController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.book?.title ?? '');
    authorController = TextEditingController(text: widget.book?.author ?? '');
    yearController = TextEditingController(text: widget.book?.year.toString() ?? '');
    categoryController = TextEditingController(text: widget.book?.category ?? '');
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    yearController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book != null ? 'Edit Book' : 'Add New Book'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextFormField(
              controller: authorController,
              decoration: const InputDecoration(labelText: 'Author'),
            ),
            TextFormField(
              controller: yearController,
              decoration: const InputDecoration(labelText: 'Year'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final newBook = Book(
                  id: widget.book?.id ?? generateUuid(),
                  title: titleController.text,
                  author: authorController.text,
                  year: int.tryParse(yearController.text) ?? 0,
                  category: categoryController.text,
                );
                Navigator.pop(context, newBook);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class BookSearchDelegate extends SearchDelegate<Book> {
  final List<Book> books;

  BookSearchDelegate(this.books);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, Book(id: '', title: '', author: '', year: 0, category: ''));
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = books.where((book) => book.title.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index].title),
          subtitle: Text('${results[index].author} - ${results[index].year}'),
          onTap: () {
            close(context, results[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = books.where((book) => book.title.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index].title),
          subtitle: Text('${results[index].author} - ${results[index].year}'),
          onTap: () {
            close(context, results[index]);
          },
        );
      },
    );
  }
}

String generateUuid() {
  return int.parse('${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(100000)}').toRadixString(35).substring(0, 9);
}
