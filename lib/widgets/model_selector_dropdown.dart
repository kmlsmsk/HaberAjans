import 'package:flutter/material.dart';
import '../models/gemini_model_config.dart';
import '../services/api_key_storage.dart';

class ModelSelectorDropdown extends StatefulWidget {
  final String selectedModelId;
  final ValueChanged<String> onChanged;
  final String moduleType;

  const ModelSelectorDropdown({
    super.key,
    required this.selectedModelId,
    required this.onChanged,
    this.moduleType = 'global',
  });

  @override
  State<ModelSelectorDropdown> createState() => _ModelSelectorDropdownState();
}

class _ModelSelectorDropdownState extends State<ModelSelectorDropdown> {
  List<GeminiModelOption> _models = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    final list = await ApiKeyStorage.getAllModels();
    final sanitizedInput = GeminiModelConfig.sanitizeModel(widget.selectedModelId);

    if (mounted) {
      setState(() {
        _models = list;
        _isLoading = false;
      });

      // Eğer gelen model ID geçersizse veya düzeltildiyse hemen parent'a bildir ve kaydet
      if (sanitizedInput != widget.selectedModelId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onChanged(sanitizedInput);
          ApiKeyStorage.saveModel(widget.moduleType, sanitizedInput);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 48,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final sanitizedId = GeminiModelConfig.sanitizeModel(widget.selectedModelId);
    final allItems = List<GeminiModelOption>.from(_models);

    // Eğer model listede yoksa ve geçersiz/pro değilse özel olarak ekle
    final exists = allItems.any((m) => m.id == sanitizedId);
    if (!exists && sanitizedId.isNotEmpty && !sanitizedId.contains('pro')) {
      allItems.add(
        GeminiModelOption(
          id: sanitizedId,
          name: '$sanitizedId (Özel)',
          description: 'Kullanıcı tanımlı model',
          isCustom: true,
        ),
      );
    }

    final currentValue = allItems.any((m) => m.id == sanitizedId)
        ? sanitizedId
        : GeminiModelConfig.defaultGlobalModel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.bolt, color: Color(0xFF003366), size: 20),
          items: allItems.map((model) {
            final isDefault = model.id == GeminiModelConfig.defaultGlobalModel;
            return DropdownMenuItem<String>(
              value: model.id,
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: isDefault ? Colors.green : (model.isCustom ? Colors.orange : const Color(0xFF00A3E0)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              model.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: const Text(
                                  'Varsayılan',
                                  style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (model.description.isNotEmpty)
                          Text(
                            model.description,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              final clean = GeminiModelConfig.sanitizeModel(val);
              widget.onChanged(clean);
              ApiKeyStorage.saveModel(widget.moduleType, clean);
            }
          },
        ),
      ),
    );
  }
}
