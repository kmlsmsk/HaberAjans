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
    if (mounted) {
      setState(() {
        _models = list;
        _isLoading = false;
      });
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

    final isCustom = !_models.any((m) => m.id == widget.selectedModelId);
    final allItems = List<GeminiModelOption>.from(_models);
    if (isCustom && widget.selectedModelId.isNotEmpty) {
      allItems.add(
        GeminiModelOption(
          id: widget.selectedModelId,
          name: '${widget.selectedModelId} (Özel)',
          description: 'Kullanıcı tanımlı model',
          isCustom: true,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: allItems.any((m) => m.id == widget.selectedModelId) ? widget.selectedModelId : allItems.first.id,
          isExpanded: true,
          icon: const Icon(Icons.auto_awesome, color: Color(0xFF003366), size: 20),
          items: allItems.map((model) {
            return DropdownMenuItem<String>(
              value: model.id,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: model.isCustom ? Colors.orange : const Color(0xFF00A3E0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          model.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (model.description.isNotEmpty)
                          Text(
                            model.description,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
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
              widget.onChanged(val);
            }
          },
        ),
      ),
    );
  }
}
