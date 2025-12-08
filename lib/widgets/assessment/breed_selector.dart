import 'package:flutter/material.dart';
import 'package:pupshape/config/theme.dart';

class BreedSelector extends StatefulWidget {
  final String? selectedBreed;
  final Function(String) onBreedSelected;

  const BreedSelector({
    super.key,
    this.selectedBreed,
    required this.onBreedSelected,
  });

  @override
  State<BreedSelector> createState() => _BreedSelectorState();
}

class _BreedSelectorState extends State<BreedSelector> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customBreedController = TextEditingController();
  List<String> _filteredBreeds = [];
  bool _showCustomInput = false;

  // Top 100 most popular dog breeds
  final List<String> _allBreeds = [
    'Mixed Breed / Mutt',
    'Labrador Retriever',
    'Golden Retriever',
    'German Shepherd',
    'French Bulldog',
    'Bulldog',
    'Beagle',
    'Poodle',
    'Rottweiler',
    'Yorkshire Terrier',
    'Boxer',
    'Dachshund',
    'Shih Tzu',
    'Siberian Husky',
    'Pembroke Welsh Corgi',
    'Australian Shepherd',
    'Great Dane',
    'Doberman Pinscher',
    'Cavalier King Charles Spaniel',
    'Miniature Schnauzer',
    'Shiba Inu',
    'Boston Terrier',
    'Pomeranian',
    'Havanese',
    'English Springer Spaniel',
    'Shetland Sheepdog',
    'Brittany',
    'Cocker Spaniel',
    'Border Collie',
    'Pug',
    'Chihuahua',
    'Maltese',
    'Mastiff',
    'Basset Hound',
    'Collie',
    'Bernese Mountain Dog',
    'Bichon Frise',
    'Akita',
    'Bullmastiff',
    'Cane Corso',
    'Saint Bernard',
    'Rhodesian Ridgeback',
    'Bloodhound',
    'Newfoundland',
    'Chesapeake Bay Retriever',
    'Weimaraner',
    'Vizsla',
    'Belgian Malinois',
    'West Highland White Terrier',
    'Dalmatian',
    'Samoyed',
    'Portuguese Water Dog',
    'Australian Cattle Dog',
    'Soft Coated Wheaten Terrier',
    'Airedale Terrier',
    'Chinese Shar-Pei',
    'Papillon',
    'Italian Greyhound',
    'Jack Russell Terrier',
    'Alaskan Malamute',
    'Border Terrier',
    'Bull Terrier',
    'Cairn Terrier',
    'Chow Chow',
    'English Cocker Spaniel',
    'English Setter',
    'Great Pyrenees',
    'Irish Setter',
    'Lhasa Apso',
    'Old English Sheepdog',
    'Pekingese',
    'Scottish Terrier',
    'Staffordshire Bull Terrier',
    'American Pit Bull Terrier',
    'American Staffordshire Terrier',
    'Basenji',
    'Whippet',
    'Brussels Griffon',
    'Chinese Crested',
    'Affenpinscher',
    'Afghan Hound',
    'American Eskimo Dog',
    'Anatolian Shepherd',
    'Australian Terrier',
    'Bearded Collie',
    'Bedlington Terrier',
    'Belgian Tervuren',
    'Black Russian Terrier',
    'Borzoi',
    'Bouvier des Flandres',
    'Briard',
    'Cardigan Welsh Corgi',
    'Clumber Spaniel',
    'English Toy Spaniel',
    'Field Spaniel',
    'Finnish Spitz',
    'Flat-Coated Retriever',
    'German Pinscher',
  ];

  @override
  void initState() {
    super.initState();
    _filteredBreeds = _allBreeds;
    if (widget.selectedBreed != null) {
      _searchController.text = widget.selectedBreed!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customBreedController.dispose();
    super.dispose();
  }

  void _filterBreeds(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBreeds = _allBreeds;
      } else {
        _filteredBreeds = _allBreeds
            .where((breed) => breed.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showBreedPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Breed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: _filterBreeds,
                      decoration: InputDecoration(
                        hintText: 'Search breeds...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterBreeds('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      autofocus: true,
                    ),
                  ],
                ),
              ),

              // Breed list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredBreeds.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _filteredBreeds.length) {
                      // "Other / Custom" option at the end
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: AppTheme.accentColor,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Other / Enter Custom Breed',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        subtitle: const Text('Type your own breed name'),
                        onTap: () {
                          Navigator.pop(context);
                          _showCustomBreedInput();
                        },
                      );
                    }

                    final breed = _filteredBreeds[index];
                    final isSelected = widget.selectedBreed == breed;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.pets,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        breed,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                          : null,
                      onTap: () {
                        widget.onBreedSelected(breed);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomBreedInput() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Breed Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Can\'t find your dog\'s breed? Enter it below:',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customBreedController,
              decoration: InputDecoration(
                labelText: 'Breed Name',
                hintText: 'e.g., Labradoodle, Mixed',
                prefixIcon: const Icon(Icons.pets),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_customBreedController.text.trim().isNotEmpty) {
                widget.onBreedSelected(_customBreedController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showBreedPicker,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Breed',
          prefixIcon: const Icon(Icons.pets),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.selectedBreed ?? 'Select breed',
          style: TextStyle(
            fontSize: 16,
            color: widget.selectedBreed != null
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}
