import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookSearchPage extends StatefulWidget {
  const BookSearchPage({super.key});

  @override
  State<BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> books = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Load some books when the page opens
    searchBooks('fiction');
  }

  Future<void> searchBooks(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final encodedQuery = Uri.encodeQueryComponent(query.trim());

      final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes'
        '?q=$encodedQuery'
        '&maxResults=20'
        '&printType=books',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          books = data['items'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load books.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Unable to connect to the internet.';
      });
    }
  }

  String getTitle(Map<String, dynamic> info) {
    return info['title'] ?? 'Unknown Title';
  }

  String getAuthors(Map<String, dynamic> info) {
    final authors = info['authors'];

    if (authors is List && authors.isNotEmpty) {
      return authors.join(', ');
    }

    return 'Unknown Author';
  }

  String getDescription(Map<String, dynamic> info) {
    final description = info['description'];

    if (description == null || description.toString().isEmpty) {
      return 'No description available.';
    }

    return description.toString();
  }

  String? getCoverImage(Map<String, dynamic> info) {
    final imageLinks = info['imageLinks'];

    if (imageLinks == null) {
      return null;
    }

    return imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FA),
      appBar: AppBar(
        title: const Text(
          'Bookin & Bookout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,

              onSubmitted: (value) {
                searchBooks(value);
              },

              decoration: InputDecoration(
                hintText: 'Search for a book...',
                prefixIcon: const Icon(Icons.search),

                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    searchBooks(_searchController.text);
                  },
                ),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // RESULTS
          Expanded(child: _buildBookList()),
        ],
      ),
    );
  }

  Widget _buildBookList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    if (books.isEmpty) {
      return const Center(
        child: Text('No books found.', style: TextStyle(fontSize: 18)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final info = book['volumeInfo'] ?? {};

        return _buildBookCard(info);
      },
    );
  }

  Widget _buildBookCard(Map<String, dynamic> info) {
    final title = getTitle(info);
    final author = getAuthors(info);
    final description = getDescription(info);
    final imageUrl = getCoverImage(info);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

      child: InkWell(
        borderRadius: BorderRadius.circular(15),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsPage(
                title: title,
                author: author,
                description: description,
                imageUrl: imageUrl,
              ),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BOOK COVER
              ClipRRect(
                borderRadius: BorderRadius.circular(8),

                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 90,
                        height: 130,
                        fit: BoxFit.cover,

                        errorBuilder: (context, error, stackTrace) {
                          return _placeholderCover();
                        },
                      )
                    : _placeholderCover(),
              ),

              const SizedBox(width: 14),

              // BOOK INFORMATION
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      author,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'View Details →',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      width: 90,
      height: 130,
      color: Colors.deepPurple.shade100,

      child: const Icon(Icons.menu_book, size: 40, color: Colors.deepPurple),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ============================================================
// BOOK DETAILS PAGE
// ============================================================

class BookDetailsPage extends StatelessWidget {
  final String title;
  final String author;
  final String description;
  final String? imageUrl;

  const BookDetailsPage({
    super.key,
    required this.title,
    required this.author,
    required this.description,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FA),

      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            // COVER
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),

                child: Image.network(
                  imageUrl!,
                  width: 180,
                  height: 260,
                  fit: BoxFit.cover,

                  errorBuilder: (context, error, stackTrace) {
                    return _largePlaceholder();
                  },
                ),
              )
            else
              _largePlaceholder(),

            const SizedBox(height: 20),

            // TITLE
            Text(
              title,
              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // AUTHOR
            Text(
              'by $author',
              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),

            const SizedBox(height: 25),

            // DESCRIPTION
            Align(
              alignment: Alignment.centerLeft,

              child: const Text(
                'Description',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,

              child: Text(
                description,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),

            const SizedBox(height: 30),

            // RENT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Book added to Rent!')),
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: const Text(
                  'Rent Book',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // BUY BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,

              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Book added to Buy!')),
                  );
                },

                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,

                  side: const BorderSide(color: Colors.deepPurple),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: const Text(
                  'Buy Book',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _largePlaceholder() {
    return Container(
      width: 180,
      height: 260,

      decoration: BoxDecoration(
        color: Colors.deepPurple.shade100,
        borderRadius: BorderRadius.circular(12),
      ),

      child: const Icon(Icons.menu_book, size: 80, color: Colors.deepPurple),
    );
  }
}
