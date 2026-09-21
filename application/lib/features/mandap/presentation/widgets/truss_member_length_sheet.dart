import 'package:flutter/material.dart';
import '../../application/mandap_editor_controller.dart';
import '../../domain/entities/edge_id.dart';

/// Compact floating CAD panel for editing the length of the selected Truss member independently.
class TrussMemberLengthSheet extends StatefulWidget {
  final MandapEditorController controller;
  final EdgeId edgeId;
  final VoidCallback onClose;

  const TrussMemberLengthSheet({
    super.key,
    required this.controller,
    required this.edgeId,
    required this.onClose,
  });

  @override
  State<TrussMemberLengthSheet> createState() => _TrussMemberLengthSheetState();
}

class _TrussMemberLengthSheetState extends State<TrussMemberLengthSheet> {
  late TextEditingController _textController;
  double _currentLength = 10.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _syncCurrentLength();
    _textController = TextEditingController(
      text: _formatLength(_currentLength),
    );
  }

  @override
  void didUpdateWidget(covariant TrussMemberLengthSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.edgeId != widget.edgeId) {
      _syncCurrentLength();
      _textController.text = _formatLength(_currentLength);
      _errorMessage = null;
    }
  }

  void _syncCurrentLength() {
    final len = widget.controller.selectedEdgeLength;
    if (len != null && len > 0.0) {
      _currentLength = len;
    }
  }

  String _formatLength(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _step(double direction) {
    double currentVal = double.tryParse(_textController.text.trim()) ?? _currentLength;
    double newVal;
    const double stepSize = 5.0;
    if (direction > 0) {
      // Step up to next multiple of 5 ft
      newVal = (currentVal / stepSize).floorToDouble() * stepSize + stepSize;
      if (newVal <= currentVal) newVal += stepSize;
    } else {
      // Step down to previous multiple of 5 ft
      newVal = (currentVal / stepSize).ceilToDouble() * stepSize - stepSize;
      if (newVal >= currentVal) newVal -= stepSize;
    }
    if (newVal < 5.0) newVal = 5.0;
    newVal = double.parse(newVal.toStringAsFixed(2));

    setState(() {
      _errorMessage = null;
      _textController.text = _formatLength(newVal);
    });

    final success = widget.controller.resizeSelectedEdgeLength(newVal);
    if (success) {
      setState(() {
        _syncCurrentLength();
      });
    }
  }

  void _apply() {
    final text = _textController.text.trim();
    final parsed = double.tryParse(text);

    if (parsed == null || !parsed.isFinite || parsed <= 0.0) {
      setState(() {
        _errorMessage = 'Enter valid positive length';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final success = widget.controller.resizeSelectedEdgeLength(parsed);
    if (success) {
      setState(() {
        _syncCurrentLength();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncCurrentLength();

    final edgeKeys = widget.controller.layout.edges.keys.toList();
    final edgeIdx = edgeKeys.indexOf(widget.edgeId);
    final trussNum = edgeIdx >= 0 ? edgeIdx + 1 : null;
    final titleText = trussNum != null ? 'TRUSS MEMBER #$trussNum' : 'TRUSS MEMBER';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.architecture,
                        size: 16,
                        color: Color(0xFF00F0FF),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          titleText,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Current Length Label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Current Length',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  '${_currentLength.toStringAsFixed(1)} ft',
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // [ - ] 10.0 ft [ + ] Stepper Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _step(-1.0),
                    icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    splashRadius: 18,
                  ),
                  Text(
                    '${_textController.text.trim().isEmpty ? _formatLength(_currentLength) : _textController.text.trim()} ft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _step(1.0),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Direct input field
            const Text(
              'Length',
              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 36,
              child: TextField(
                controller: _textController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  suffixText: 'ft',
                  suffixStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _apply(),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 10),
              ),
            ],

            const SizedBox(height: 10),

            // APPLY Button
            ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: const Color(0xFF0B0F19),
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'APPLY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
