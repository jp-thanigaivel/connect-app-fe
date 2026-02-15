import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connect/models/expert.dart';
import 'package:connect/services/expert_api_service.dart';
import 'package:connect/core/api/token_manager.dart';
import 'package:connect/core/utils/jwt_utils.dart';
import 'package:connect/core/utils/ui_utils.dart';
import 'package:connect/pages/multi_select_page.dart';
import 'package:connect/components/menu_item.dart';
import 'package:connect/core/config/currency_config.dart';
import 'package:connect/services/document_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer' as developer;

class ExpertDetailsPage extends StatefulWidget {
  const ExpertDetailsPage({super.key});

  @override
  State<ExpertDetailsPage> createState() => _ExpertDetailsPageState();
}

class _ExpertDetailsPageState extends State<ExpertDetailsPage> {
  final ExpertApiService _expertApiService = ExpertApiService();
  final DocumentService _documentService = DocumentService();
  final ImagePicker _picker = ImagePicker();
  Expert? _expert;
  bool _isLoading = true;
  bool _isUploading = false;
  int _imageVersion = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _fetchExpertDetails();
  }

  Future<void> _fetchExpertDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await TokenManager.getAccessToken();
      if (token == null) return;

      final userId = JwtUtils.getUserId(token);
      if (userId == null) return;

      final response = await _expertApiService.getExpertByUserId(userId);
      if (mounted) {
        setState(() {
          _expert = response.data;
          _imageVersion = DateTime.now().millisecondsSinceEpoch;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error fetching expert details: $e',
          name: 'ExpertDetailsPage');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        UiUtils.showErrorSnackBar('Failed to load expert details');
      }
    }
  }

  Future<void> _editLanguages() async {
    try {
      final response = await _expertApiService.getAvailableLanguages();
      final availableLanguages = response.data;

      if (!mounted || availableLanguages == null) return;

      // Map values in expert profile to displays for MultiSelectPage
      final initialSelectedDisplays = availableLanguages
          .where((l) => _expert?.languages.contains(l.value) ?? false)
          .map((l) => l.display)
          .toList();

      final result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (context) => MultiSelectPage(
            title: 'Select Languages',
            options: availableLanguages.map((l) => l.display).toList(),
            initialSelected: initialSelectedDisplays,
            showSearch: false,
          ),
        ),
      );

      if (result != null && mounted) {
        // Map selected displays back to values for API update
        final selectedValues = availableLanguages
            .where((l) => result.contains(l.display))
            .map((l) => l.value as String)
            .toList();

        final updateResponse = await _expertApiService.updateExpert(
          _expert!.expertId,
          {'languages': selectedValues},
        );
        setState(() {
          _expert = updateResponse.data;
        });
        UiUtils.showSuccessSnackBar('Languages updated successfully');
      }
    } catch (e) {
      developer.log('Error updating languages: $e', name: 'ExpertDetailsPage');
      UiUtils.showErrorSnackBar('Failed to update languages');
    }
  }

  Future<void> _editExpertiseTags() async {
    try {
      final response = await _expertApiService.getAvailableExpertiseTags();
      final availableTags = response.data;

      if (!mounted || availableTags == null) return;

      // Map values in expert profile to displays for MultiSelectPage
      final initialSelectedDisplays = availableTags
          .where((t) => _expert?.expertiseTags.contains(t.value) ?? false)
          .map((t) => t.display)
          .toList();

      final result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (context) => MultiSelectPage(
            title: 'Select Expertise',
            options: availableTags.map((t) => t.display).toList(),
            initialSelected: initialSelectedDisplays,
            showSearch: false,
            icon: Icons.badge_outlined,
          ),
        ),
      );

      if (result != null && mounted) {
        // Map selected displays back to values for API update
        final selectedValues = availableTags
            .where((t) => result.contains(t.display))
            .map((t) => t.value as String)
            .toList();

        final updateResponse = await _expertApiService.updateExpert(
          _expert!.expertId,
          {'expertiseTags': selectedValues},
        );
        setState(() {
          _expert = updateResponse.data;
        });
        UiUtils.showSuccessSnackBar('Expertise tags updated successfully');
      }
    } catch (e) {
      developer.log('Error updating tags: $e', name: 'ExpertDetailsPage');
      UiUtils.showErrorSnackBar('Failed to update expertise tags');
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final file = File(image.path);
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      final contentType =
          image.path.endsWith('.png') ? 'image/png' : 'image/jpeg';

      // 1. Get Presigned URL
      final presignResponse = await _documentService.getPresignedUrl(
        documentType: 'PROFILE_IMAGE',
        fileName: fileName,
        contentType: contentType,
      );

      if (presignResponse.data == null)
        throw Exception('Failed to get upload URL');

      final uploadData = presignResponse.data!;
      final uploadUrl = uploadData['url'] as String;
      final fields = uploadData['fields'] as Map<String, dynamic>;
      final publicUrl = uploadData['publicUrl'] as String;

      // 2. Upload to S3
      await _documentService.uploadToS3(
        url: uploadUrl,
        fields: fields,
        file: file,
        contentType: contentType,
      );

      // 3. Update Expert Profile
      final updateResponse = await _expertApiService.updateExpert(
        _expert!.expertId,
        {'photoUrl': publicUrl},
      );

      if (mounted) {
        setState(() {
          _expert = updateResponse.data;
          _isUploading = false;
        });
        UiUtils.showSuccessSnackBar('Profile picture updated successfully');
      }
    } catch (e) {
      developer.log('Error uploading image: $e', name: 'ExpertDetailsPage');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        UiUtils.showErrorSnackBar('Failed to update profile picture');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_expert == null) {
      return const Scaffold(
          body: Center(child: Text('Failed to load expert details')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Expert Profile',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchExpertDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Main Profile Card (Expert specific)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _expert!.photoUrl != null &&
                                      _expert!.photoUrl!.isNotEmpty
                                  ? Opacity(
                                      opacity: _isUploading ? 0.3 : 1.0,
                                      child: Image.network(
                                        '${_expert!.photoUrl!}${_expert!.photoUrl!.contains('?') ? '&' : '?'}v=$_imageVersion',
                                        key: ValueKey('$_imageVersion'),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                              if (_isUploading)
                                const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLowest,
                                width: 3,
                              ),
                            ),
                            child: IconButton(
                              onPressed:
                                  _isUploading ? null : _pickAndUploadImage,
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _expert!.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        if (_expert!.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              color: Colors.blue, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Expert ID
                    Text(
                      'Expert ID: ${_expert!.expertId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 32),
                    Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.2),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Edit Expert Profile',
                            onPressed: () async {
                              final updatedExpert = await Navigator.pushNamed(
                                context,
                                'EditExpertProfilePage',
                                arguments: {
                                  'expert': _expert,
                                },
                              );
                              if (updatedExpert != null && mounted) {
                                setState(() {
                                  _expert = updatedExpert as Expert;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Stats Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _StatItem(
                        label: 'Age',
                        value: '${_expert!.age}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.2),
                    ),
                    Expanded(
                      flex: 6,
                      child: _StatItem(
                        label: 'Rate',
                        value:
                            '${CurrencyConfig.coinIconText} ${_expert!.pricePerMinute.price}/m',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Menu Items
              MenuItem(
                icon: Icons.translate_outlined,
                label: 'Languages',
                onTap: _editLanguages,
              ),
              const SizedBox(height: 12),
              MenuItem(
                icon: Icons.badge_outlined,
                label: 'Expert Tags',
                onTap: _editExpertiseTags,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
