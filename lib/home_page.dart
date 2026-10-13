import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'book_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  int _selectedIndex = 0;

  static const List<NavigationDrawerDestination> _destinations = [
    NavigationDrawerDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: Text('Browse books'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.shopping_bag_outlined),
      selectedIcon: Icon(Icons.shopping_bag),
      label: Text('Buy books'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.autorenew_outlined),
      selectedIcon: Icon(Icons.autorenew),
      label: Text('Rent books'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.recommend_outlined),
      selectedIcon: Icon(Icons.recommend),
      label: Text('Recommendations'),
    ),
    NavigationDrawerDestination(
      icon: Icon(Icons.history),
      selectedIcon: Icon(Icons.history),
      label: Text('My activity'),
    ),
  ];

  String get _title {
    switch (_selectedIndex) {
      case 1:
        return 'Browse books';
      case 2:
        return 'Buy books';
      case 3:
        return 'Rent books';
      case 4:
        return 'Recommendations';
      case 5:
        return 'My activity';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildContent() {
    // ========================================================
    // BROWSE BOOKS
    // ========================================================

    if (_selectedIndex == 1) {
      return const BookSearchSection();
    }

    // ========================================================
    // BUY BOOKS
    // ========================================================

    if (_selectedIndex == 2) {
      return const _ContainedSection(
        title: 'Buy books',
        icon: Icons.shopping_bag,
        child: ListTile(
          leading: Icon(Icons.sell_outlined),
          title: Text('Find books to own'),
          subtitle: Text('Build your personal collection with new favourites.'),
          trailing: Icon(Icons.arrow_forward),
        ),
      );
    }

    // ========================================================
    // RENT BOOKS
    // ========================================================

    if (_selectedIndex == 3) {
      return const _ContainedSection(
        title: 'Rent books',
        icon: Icons.autorenew,
        child: ListTile(
          leading: Icon(Icons.event_available),
          title: Text('Read more for less'),
          subtitle: Text('Rent books for flexible, affordable reading.'),
          trailing: Icon(Icons.arrow_forward),
        ),
      );
    }

    // ========================================================
    // RECOMMENDATIONS
    // ========================================================

    if (_selectedIndex == 4) {
      return const _ContainedSection(
        title: 'Recommended for you',
        icon: Icons.recommend,
        child: ListTile(
          leading: Icon(Icons.auto_stories),
          title: Text('Curated reading picks'),
          subtitle: Text('Discover a book matched to your reading interests.'),
          trailing: Icon(Icons.arrow_forward),
        ),
      );
    }

    // ========================================================
    // MY ACTIVITY
    // ========================================================

    if (_selectedIndex == 5) {
      return const _ContainedSection(
        title: 'Your activity',
        icon: Icons.history,
        child: ListTile(
          leading: Icon(Icons.receipt_long),
          title: Text('No recent activity'),
          subtitle: Text('Your purchases and rentals will appear here.'),
        ),
      );
    }

    // ========================================================
    // DASHBOARD
    // ========================================================

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),

        const SizedBox(height: 8),

        Text(
          user?.email ?? 'Reader',
          style: Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _ServiceCard(
                icon: Icons.autorenew,
                title: 'Rent a book',
                description: 'Read more for less.',
                onTap: () {
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _ServiceCard(
                icon: Icons.shopping_bag,
                title: 'Buy a book',
                description: 'Own your next favourite read.',
                onTap: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        const _ContainedSection(
          title: 'Recommended reading',
          icon: Icons.recommend,
          child: ListTile(
            leading: Icon(Icons.auto_stories),
            title: Text('A pick for your next chapter'),
            subtitle: Text('Browse recommendations based on your interests.'),
            trailing: Icon(Icons.arrow_forward),
          ),
        ),

        const SizedBox(height: 20),

        const _ContainedSection(
          title: 'Quick updates',
          icon: Icons.notifications_none,
          child: ListTile(
            leading: Icon(Icons.local_library_outlined),
            title: Text('Your library is ready'),
            subtitle: Text('Buy, rent, or discover a recommended book today.'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),

      // ======================================================
      // NAVIGATION DRAWER
      // ======================================================
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          Navigator.pop(context);
        },

        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 16, 12),
            child: Text(
              'Bookin & Bookout',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(28, 0, 16, 12),
            child: Text('Library products and services'),
          ),

          ..._destinations,

          const Divider(indent: 16, endIndent: 16),

          // ==================================================
          // SIGN OUT
          // ==================================================
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),

            onTap: () async {
              Navigator.pop(context);

              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildContent(),
        ),
      ),

      // ======================================================
      // RENT BUTTON
      // ======================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _selectedIndex = 3;
          });
        },

        backgroundColor: Theme.of(context).colorScheme.primaryContainer,

        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,

        icon: const Icon(Icons.autorenew),

        label: const Text('Rent a book'),

        tooltip: 'Rent a book',
      ),
    );
  }
}

// ==========================================================
// GOOGLE BOOKS SEARCH SECTION
// ==========================================================

class BookSearchSection extends StatefulWidget {
  const BookSearchSection({super.key});

  @override
  State<BookSearchSection> createState() => _BookSearchSectionState();
}

class _BookSearchSectionState extends State<BookSearchSection> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _books = [];

  bool _isLoading = false;

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Automatically show books when Browse Books opens.
    _searchBooks('fiction');
  }

  // ========================================================
  // SEARCH GOOGLE BOOKS
  // ========================================================

  Future<void> _searchBooks(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await BookService.searchBooks(query);

      if (!mounted) return;

      setState(() {
        _books = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _books = [];
        _isLoading = false;
        _errorMessage =
            'Unable to load books.\n'
            'Please check your internet connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // ====================================================
        // TITLE
        // ====================================================
        Text(
          'Book collection',
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: 8),

        Text(
          'Search books from the online catalogue.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 20),

        // ====================================================
        // SEARCH BAR
        // ====================================================
        TextField(
          controller: _searchController,

          textInputAction: TextInputAction.search,

          onSubmitted: (value) {
            _searchBooks(value);
          },

          decoration: InputDecoration(
            hintText: 'Search books...',

            prefixIcon: const Icon(Icons.search),

            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),

              onPressed: () {
                _searchBooks(_searchController.text);
              },
            ),

            filled: true,

            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),

              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ====================================================
        // LOADING
        // ====================================================
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),

              child: CircularProgressIndicator(),
            ),
          )
        // ====================================================
        // ERROR
        // ====================================================
        else if (_errorMessage.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  const Icon(Icons.cloud_off, size: 50),

                  const SizedBox(height: 10),

                  Text(_errorMessage, textAlign: TextAlign.center),

                  const SizedBox(height: 10),

                  FilledButton.icon(
                    onPressed: () {
                      _searchBooks(
                        _searchController.text.isEmpty
                            ? 'fiction'
                            : _searchController.text,
                      );
                    },

                    icon: const Icon(Icons.refresh),

                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          )
        // ====================================================
        // NO BOOKS
        // ====================================================
        else if (_books.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),

              child: Text('No books found.'),
            ),
          )
        // ====================================================
        // BOOK RESULTS
        // ====================================================
        else
          ListView.builder(
            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),

            itemCount: _books.length,

            itemBuilder: (context, index) {
              final item = _books[index];

              final Map<String, dynamic> book =
                  item['volumeInfo'] as Map<String, dynamic>? ?? {};

              return BookCard(book: book);
            },
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }
}

// ==========================================================
// BOOK CARD
// ==========================================================

class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final String title = book['title'] ?? 'Unknown Title';

    final List<dynamic> authors = book['authors'] ?? ['Unknown Author'];

    final String author = authors.join(', ');

    final String description =
        book['description'] ?? 'No description available.';

    String? imageUrl = book['imageLinks']?['thumbnail'];

    // Convert HTTP to HTTPS.
    if (imageUrl != null) {
      imageUrl = imageUrl.replaceFirst('http://', 'https://');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      clipBehavior: Clip.antiAlias,

      child: InkWell(
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
              // =================================================
              // BOOK COVER
              // =================================================
              ClipRRect(
                borderRadius: BorderRadius.circular(8),

                child: imageUrl != null
                    ? Image.network(
                        imageUrl,

                        width: 90,
                        height: 130,

                        fit: BoxFit.cover,

                        errorBuilder: (context, error, stackTrace) {
                          return _BookPlaceholder(width: 90, height: 130);
                        },
                      )
                    : _BookPlaceholder(width: 90, height: 130),
              ),

              const SizedBox(width: 14),

              // =================================================
              // INFORMATION
              // =================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // TITLE
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

                    // AUTHOR
                    Text(
                      author,

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(color: Colors.grey[700]),
                    ),

                    const SizedBox(height: 8),

                    // DESCRIPTION
                    Text(
                      description,

                      maxLines: 4,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(color: Colors.grey[600], height: 1.3),
                    ),

                    const SizedBox(height: 8),

                    // DETAILS
                    Text(
                      'View Details →',

                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,

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
}

// ==========================================================
// BOOK DETAILS PAGE
// ==========================================================

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
      appBar: AppBar(title: const Text('Book Details')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            // =================================================
            // COVER
            // =================================================
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),

                child: Image.network(
                  imageUrl!,

                  width: 180,
                  height: 260,

                  fit: BoxFit.cover,

                  errorBuilder: (context, error, stackTrace) {
                    return const _BookPlaceholder(width: 180, height: 260);
                  },
                ),
              )
            else
              const _BookPlaceholder(width: 180, height: 260),

            const SizedBox(height: 20),

            // =================================================
            // TITLE
            // =================================================
            Text(
              title,

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // =================================================
            // AUTHOR
            // =================================================
            Text(
              'by $author',

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),

            const SizedBox(height: 25),

            // =================================================
            // DESCRIPTION
            // =================================================
            const Align(
              alignment: Alignment.centerLeft,

              child: Text(
                'Description',

                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,

              child: Text(
                description,

                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),

            const SizedBox(height: 30),

            // =================================================
            // RENT
            // =================================================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Book added to Rent.')),
                  );
                },

                icon: const Icon(Icons.autorenew),

                label: const Text('Rent Book'),
              ),
            ),

            const SizedBox(height: 10),

            // =================================================
            // BUY
            // =================================================
            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Book added to Buy.')),
                  );
                },

                icon: const Icon(Icons.shopping_bag),

                label: const Text('Buy Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// BOOK IMAGE PLACEHOLDER
// ==========================================================

class _BookPlaceholder extends StatelessWidget {
  final double width;
  final double height;

  const _BookPlaceholder({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,

      color: Colors.deepPurple.shade100,

      child: const Icon(Icons.menu_book, size: 45, color: Colors.deepPurple),
    );
  }
}

// ==========================================================
// SERVICE CARD
// ==========================================================

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,

      child: InkWell(
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),

              const SizedBox(height: 16),

              Text(title, style: Theme.of(context).textTheme.titleMedium),

              const SizedBox(height: 6),

              Text(description),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// CONTAINED SECTION
// ==========================================================

class _ContainedSection extends StatelessWidget {
  const _ContainedSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),

            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),

                const SizedBox(width: 12),

                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),

          child,
        ],
      ),
    );
  }
}
