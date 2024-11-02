import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'welcome_page.dart';


void main() {
  runApp(const DictionaryApp());
}
class DictionaryApp extends StatelessWidget {
  const DictionaryApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dictionary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
      ),
      home: const WelcomePage(),
    );
  }
}

class DictionaryHomePage extends StatefulWidget {
  final String? initialQuery;
  
  const DictionaryHomePage({
    super.key,
    this.initialQuery,
  });

  @override
  State<DictionaryHomePage> createState() => _DictionaryHomePageState();
}

class _DictionaryHomePageState extends State<DictionaryHomePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _wordData;
  List<String> _suggestions = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _searchController.text = widget.initialQuery!;
          _searchDictionary(widget.initialQuery!);
        }
      });
    }
  }

  Future<void> _searchDictionary(String word) async {
    if (word.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _wordData = null;
      _suggestions = [];
      _searchController.clear();
    });

    try {
      // Fetch dictionary data
      final dictionaryResponse = await http.get(
        Uri.parse('https://dictionaryapi.com/api/v3/references/learners/json/$word?key=29386e93-11d3-4bc7-a008-2d4307669cf6'),
      );

      // Fetch image data
      final imageUrl = await _fetchImageData(word);

      if (dictionaryResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(dictionaryResponse.body);
        if (data.isNotEmpty && data[0] is Map<String, dynamic>) {
          setState(() {
            _wordData = {
              'word': word,
              'dictionary': data[0],
              'imageUrl': imageUrl,
            };
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Word not found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch word data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<String?> _fetchImageData(String word) async {
    const baseUrl = "https://content2.mcqstudy.com/ba2/";
    final imageUrl = "$baseUrl${word.toUpperCase()}.JPG.webp";
    
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return imageUrl;
      }
    } catch (e) {
      print('Error fetching image: $e');
    }
    return null;
  }

  Future<void> _fetchSuggestions(String prefix) async {
    if (prefix.length < 2) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.datamuse.com/sug?s=$prefix&max=5'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _suggestions = data.map<String>((item) => item['word'] as String).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      if (mounted) setState(() => _suggestions = []);
    }
  }

  void _debounceSearch(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(value);
    });
  }

  // Add a field to store the image provider
  final NetworkImage _profileImage = const NetworkImage('https://avatars.githubusercontent.com/u/94497807?v=4');

  void _showDeveloperInfo() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image(
                        image: _profileImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.blue.shade100,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade800,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.code_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Mamun Abdullah',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              Text(
                'Developer',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.rocket_launch_rounded,
                      'Version 1.0.0',
                      'Latest Release',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    _buildInfoRow(
                      Icons.email_outlined,
                      'a.a.mamun595@gmail.com',
                      'Contact Email',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.blue.shade800,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomePage()),
                (route) => false,
              );
            },
          ),
          title: const Text(
            'Dictionary',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: _showDeveloperInfo,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: _buildSearchBar(),
              ),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Expanded(child: _buildErrorWidget())
              else if (_wordData != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildWordDetails(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.length < 2) {
            return const Iterable<String>.empty();
          }
          return _suggestions.where((String option) {
            return option.toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          _searchDictionary(selection);
          _searchController.clear();
        },
        optionsViewBuilder: (context, onSelected, options) {
          if (options.isEmpty) return const SizedBox.shrink();

          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width - 48,
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.shade50,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.blue.shade50,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: Colors.blue.shade300,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.north_west_rounded,
                                size: 16,
                                color: Colors.blue.shade200,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade900,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search for a word...',
              hintStyle: TextStyle(
                color: Colors.blue.shade200,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(
                  color: Colors.blue.shade50,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(
                  color: Colors.blue.shade200,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              _debounceSearch(value);
              controller.value = TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              );
            },
            onSubmitted: (value) {
              _searchDictionary(value.trim());
              controller.clear();
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordDetails() {
    final wordData = _wordData!;
    final dictionary = wordData['dictionary'];
    
    if (dictionary == null) {
      return const Center(
        child: Text('No dictionary data available'),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        wordData['word'].toString().toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 30,
                          color: const Color(0xFF1A237E),
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.blue.withOpacity(0.2),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        color: Colors.blue.shade800,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                if (dictionary['fl'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dictionary['fl'].toString(),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue.shade900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Definitions
          if (dictionary['shortdef'] != null) ...[
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.white,
                    Colors.blue.shade50.withOpacity(0.5),
                  ],
                  stops: const [0.2, 1.0],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.blue.shade50.withOpacity(0.5),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(-15, -15),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade800,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'EN',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List<String>.from(dictionary['shortdef'])
                            .asMap()
                            .entries
                            .map((entry) => Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        margin: const EdgeInsets.only(right: 14),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white,
                                              Colors.blue.shade50,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.blue.shade100.withOpacity(0.5),
                                            width: 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.shade100.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${entry.key + 1}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: TextStyle(
                                            fontSize: 16,
                                            height: 1.6,
                                            color: Colors.blue.shade900,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Image Section
          if (wordData['imageUrl'] != null) ...[
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.shade50,
                  width: 1.5,
                ),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.white,
                    spreadRadius: 5,
                    blurRadius: 15,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade800,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100,
                            spreadRadius: 1,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'bn',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        wordData['imageUrl']!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Examples Section
          if (dictionary['def'] != null && 
              dictionary['def'][0]['sseq'] != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.shade50,
                  width: 1.5,
                ),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.white,
                    spreadRadius: 5,
                    blurRadius: 15,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade800,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100,
                            spreadRadius: 1,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Example',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List<dynamic>.from(dictionary['def'][0]['sseq'])
                          .where((seq) => 
                            seq[0][1]['dt'] != null && 
                            seq[0][1]['dt'].any((dt) => dt[0] == 'vis'))
                          .map((seq) {
                            final examples = seq[0][1]['dt']
                              .where((dt) => dt[0] == 'vis')
                              .map((dt) => dt[1][0]['t'])
                              .toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: examples.map<Widget>((example) => 
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    example.toString()
                                      .replaceAll('{it}', '')
                                      .replaceAll('{/it}', '')
                                      .replaceAll('{ldquo}', '"')
                                      .replaceAll('{rdquo}', '"'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue.shade900,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ).toList(),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
