import 'package:aquality_arduino_based_water_quality_monitoring/models/threshold.dart';
import 'package:flutter/material.dart' hide Threshold;
import '../models/threshold.dart' hide Threshold;
import '../services/threshold_service.dart';
import '../utils/format_utils.dart';
import '../utils/color_utils.dart';

class ThresholdsPage extends StatefulWidget {
  const ThresholdsPage({super.key});

  @override
  State<ThresholdsPage> createState() => _ThresholdsPageState();
}

class _ThresholdsPageState extends State<ThresholdsPage> {
  late Future<List<Threshold>> _thresholdsFuture;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  void _loadThresholds() {
    setState(() {
      _thresholdsFuture = ThresholdService.getAllThresholds() as Future<List<Threshold>>;
    });
  }

  void _showEditThreshold(Threshold? threshold) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EditThresholdSheet(
        threshold: threshold,
        onSave: (updatedThreshold) {
          _saveThreshold(updatedThreshold);
        },
      ),
    );
  }

  Future<void> _saveThreshold(Threshold threshold) async {
    final success = await ThresholdService.saveThreshold(threshold as Threshold);
    if (success) {
      _loadThresholds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${threshold.parameterName} threshold updated'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will restore all parameters to their default safe ranges.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ThresholdService.resetToDefaults();
              if (success) {
                _loadThresholds();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thresholds reset to defaults'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parameter Thresholds'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.done : Icons.edit),
            onPressed: () {
              setState(() => _isEditMode = !_isEditMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: FutureBuilder<List<Threshold>>(
        future: _thresholdsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  const Text('Failed to load thresholds'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadThresholds,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final thresholds = snapshot.data ?? [];
          if (thresholds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tune,
                    size: 48,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text('No thresholds configured'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _resetToDefaults,
                    child: const Text('Load Defaults'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: thresholds.length,
            itemBuilder: (context, index) {
              final threshold = thresholds[index];
              return ThresholdCard(
                threshold: threshold,
                onEdit: () => _showEditThreshold(threshold),
                isDark: isDark,
                isEditMode: _isEditMode,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditThreshold(null),
        tooltip: 'Add Custom Threshold',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Card widget for displaying a single threshold
class ThresholdCard extends StatelessWidget {
  final Threshold threshold;
  final VoidCallback onEdit;
  final bool isDark;
  final bool isEditMode;

  const ThresholdCard({
    super.key,
    required this.threshold,
    required this.onEdit,
    required this.isDark,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEditMode ? onEdit : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    threshold.parameterName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isEditMode)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.blue,
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: threshold.enableAlerts
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      threshold.enableAlerts ? 'Alerts On' : 'Alerts Off',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: threshold.enableAlerts
                            ? Colors.green.shade600
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildThresholdRow(
              label: 'Safe Range',
              value:
                  '${FormatUtils.formatParamValue(threshold.minSafeValue)} - ${FormatUtils.formatParamValue(threshold.maxSafeValue)}',
              color: Colors.green,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            if (threshold.warningMinValue != null ||
                threshold.warningMaxValue != null)
              Column(
                children: [
                  _buildThresholdRow(
                    label: 'Warning Range',
                    value:
                        '${FormatUtils.formatParamValue(threshold.warningMinValue ?? threshold.minSafeValue)} - ${FormatUtils.formatParamValue(threshold.warningMaxValue ?? threshold.maxSafeValue)}',
                    color: Colors.orange,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            _buildThresholdRow(
              label: 'Notifications',
              value: threshold.enableNotifications ? 'Enabled' : 'Disabled',
              color: threshold.enableNotifications ? Colors.blue : Colors.grey,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Text(
              'Modified: ${FormatUtils.formatDateTime(threshold.lastModified)}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdRow({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet for editing a threshold
class EditThresholdSheet extends StatefulWidget {
  final Threshold? threshold;
  final Function(Threshold) onSave;

  const EditThresholdSheet({
    super.key,
    this.threshold,
    required this.onSave,
  });

  @override
  State<EditThresholdSheet> createState() => _EditThresholdSheetState();
}

class _EditThresholdSheetState extends State<EditThresholdSheet> {
  late TextEditingController _parameterNameController;
  late TextEditingController _minSafeController;
  late TextEditingController _maxSafeController;
  late TextEditingController _warningMinController;
  late TextEditingController _warningMaxController;
  late bool _enableAlerts;
  late bool _enableNotifications;

  @override
  void initState() {
    super.initState();
    final threshold = widget.threshold;
    _parameterNameController =
        TextEditingController(text: threshold?.parameterName ?? '');
    _minSafeController =
        TextEditingController(text: threshold?.minSafeValue.toString() ?? '');
    _maxSafeController =
        TextEditingController(text: threshold?.maxSafeValue.toString() ?? '');
    _warningMinController = TextEditingController(
        text: threshold?.warningMinValue?.toString() ?? '');
    _warningMaxController = TextEditingController(
        text: threshold?.warningMaxValue?.toString() ?? '');
    _enableAlerts = threshold?.enableAlerts ?? true;
    _enableNotifications = threshold?.enableNotifications ?? true;
  }

  @override
  void dispose() {
    _parameterNameController.dispose();
    _minSafeController.dispose();
    _maxSafeController.dispose();
    _warningMinController.dispose();
    _warningMaxController.dispose();
    super.dispose();
  }

  void _saveThreshold() {
    if (_parameterNameController.text.isEmpty ||
        _minSafeController.text.isEmpty ||
        _maxSafeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final minSafe = double.tryParse(_minSafeController.text);
    final maxSafe = double.tryParse(_maxSafeController.text);

    if (minSafe == null || maxSafe == null || minSafe >= maxSafe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your min/max values')),
      );
      return;
    }

    final threshold = Threshold(
      parameterId: widget.threshold?.parameterId ??
          _parameterNameController.text.toLowerCase().replaceAll(' ', '_'),
      parameterName: _parameterNameController.text,
      minSafeValue: minSafe,
      maxSafeValue: maxSafe,
      warningMinValue: double.tryParse(_warningMinController.text),
      warningMaxValue: double.tryParse(_warningMaxController.text),
      enableAlerts: _enableAlerts,
      enableNotifications: _enableNotifications,
      lastModified: DateTime.now(),
    );

    widget.onSave(threshold);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: mediaQuery.viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.threshold == null
                      ? 'New Threshold'
                      : 'Edit ${widget.threshold!.parameterName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Parameter Name*',
              controller: _parameterNameController,
              hint: 'e.g., Temperature',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Min Safe*',
                    controller: _minSafeController,
                    hint: '0.0',
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Max Safe*',
                    controller: _maxSafeController,
                    hint: '100.0',
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Min Warning',
                    controller: _warningMinController,
                    hint: 'Optional',
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Max Warning',
                    controller: _warningMaxController,
                    hint: 'Optional',
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _enableAlerts,
              onChanged: (value) =>
                  setState(() => _enableAlerts = value ?? true),
              title: const Text('Enable Alerts for this parameter'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _enableNotifications,
              onChanged: (value) =>
                  setState(() => _enableNotifications = value ?? true),
              title: const Text('Enable Notifications'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveThreshold,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
          ),
        ),
      ],
    );
  }
}
