import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transaction_note/providers/auth_provider.dart';

class PeriodSetupDialog extends ConsumerStatefulWidget {
  final bool isDismissible;
  final int? initialValue;

  const PeriodSetupDialog({
    super.key,
    this.isDismissible = false,
    this.initialValue,
  });

  @override
  ConsumerState<PeriodSetupDialog> createState() => _PeriodSetupDialogState();
}

class _PeriodSetupDialogState extends ConsumerState<PeriodSetupDialog> {
  late TextEditingController _controller;
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text;
    final day = int.tryParse(text);

    if (day == null || day < 1 || day > 28) {
      setState(() {
        _errorText = 'Please enter a number between 1 and 28.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        final userService = ref.read(userServiceProvider);
        await userService.updatePeriodStartDay(user.uid, day);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() {
        _errorText = 'Failed to update. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isDismissible,
      child: AlertDialog(
        title: const Text('Setup Billing Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select the start date of your financial month (1-28). This prevents issues with February.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Start Day',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
        actions: [
          if (widget.isDismissible)
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
