import 'package:flutter/material.dart';

import '../../../shared/widgets/greencrew_button.dart';
import '../data/catalog_repository.dart';
import '../domain/entities/catalog_device.dart';
import '../domain/services/catalog_duplicate_detector.dart';
import '../domain/services/catalog_duplicate_merge_service.dart';

/// Lets the user resolve each flagged pair from `CatalogDuplicateDetector`:
/// dismiss it as a false positive, or merge the two devices into one. Never
/// acts automatically - every pair needs an explicit decision.
class CatalogDuplicateReviewDialog extends StatefulWidget {
  const CatalogDuplicateReviewDialog({
    required this.pairs,
    required this.repository,
    required this.mergeService,
    super.key,
  });

  final List<CatalogDuplicatePair> pairs;
  final CatalogRepository repository;
  final CatalogDuplicateMergeService mergeService;

  @override
  State<CatalogDuplicateReviewDialog> createState() =>
      _CatalogDuplicateReviewDialogState();
}

class _CatalogDuplicateReviewDialogState
    extends State<CatalogDuplicateReviewDialog> {
  late List<CatalogDuplicatePair> _pairs;
  var _changed = false;
  String? _busyPairKey;

  @override
  void initState() {
    super.initState();
    _pairs = List.of(widget.pairs);
  }

  String _pairKey(CatalogDuplicatePair pair) =>
      CatalogDuplicateDetector.pairKey(pair.deviceA.id, pair.deviceB.id);

  Future<void> _dismiss(CatalogDuplicatePair pair) async {
    final key = _pairKey(pair);
    setState(() => _busyPairKey = key);
    await widget.repository.dismissDuplicatePair(
      pair.deviceA.id,
      pair.deviceB.id,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _pairs.removeWhere((candidate) => _pairKey(candidate) == key);
      _busyPairKey = null;
      _changed = true;
    });
  }

  Future<void> _merge(CatalogDuplicatePair pair, CatalogDevice keep) async {
    final discard = keep.id == pair.deviceA.id ? pair.deviceB : pair.deviceA;
    final key = _pairKey(pair);
    setState(() => _busyPairKey = key);
    await widget.mergeService.merge(
      keepDeviceId: keep.id,
      discardDeviceId: discard.id,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _pairs.removeWhere((candidate) => _pairKey(candidate) == key);
      _busyPairKey = null;
      _changed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Możliwe duplikaty'),
      content: SizedBox(
        width: 480,
        child: _pairs.isEmpty
            ? const Text('Brak par do przejrzenia.')
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 480),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _pairs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) => _PairTile(
                    pair: _pairs[index],
                    busy: _busyPairKey == _pairKey(_pairs[index]),
                    onDismiss: () => _dismiss(_pairs[index]),
                    onMerge: (keep) => _merge(_pairs[index], keep),
                  ),
                ),
              ),
      ),
      actions: [
        GreenCrewButton(
          label: 'Zamknij',
          secondary: true,
          onPressed: () => Navigator.of(context).pop(_changed),
        ),
      ],
    );
  }
}

class _PairTile extends StatefulWidget {
  const _PairTile({
    required this.pair,
    required this.busy,
    required this.onDismiss,
    required this.onMerge,
  });

  final CatalogDuplicatePair pair;
  final bool busy;
  final VoidCallback onDismiss;
  final ValueChanged<CatalogDevice> onMerge;

  @override
  State<_PairTile> createState() => _PairTileState();
}

class _PairTileState extends State<_PairTile> {
  late CatalogDevice _keep;

  @override
  void initState() {
    super.initState();
    _keep =
        widget.pair.deviceA.createdAt.isBefore(widget.pair.deviceB.createdAt)
        ? widget.pair.deviceA
        : widget.pair.deviceB;
  }

  @override
  Widget build(BuildContext context) {
    final pair = widget.pair;
    final similarityPercent = (pair.similarity * 100).round();

    return Opacity(
      opacity: widget.busy ? 0.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Podobieństwo nazwy: $similarityPercent%'),
          const SizedBox(height: 8),
          _DeviceRadioRow(
            device: pair.deviceA,
            selected: _keep.id == pair.deviceA.id,
            onSelected: widget.busy
                ? null
                : () => setState(() => _keep = pair.deviceA),
          ),
          _DeviceRadioRow(
            device: pair.deviceB,
            selected: _keep.id == pair.deviceB.id,
            onSelected: widget.busy
                ? null
                : () => setState(() => _keep = pair.deviceB),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              GreenCrewButton(
                label: 'To nie duplikat',
                secondary: true,
                onPressed: widget.busy ? null : widget.onDismiss,
              ),
              GreenCrewButton(
                label: 'Scal (zachowaj zaznaczone)',
                onPressed: widget.busy ? null : () => widget.onMerge(_keep),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceRadioRow extends StatelessWidget {
  const _DeviceRadioRow({
    required this.device,
    required this.selected,
    required this.onSelected,
  });

  final CatalogDevice device;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(device.name),
      subtitle: Text(
        '${device.manufacturer ?? 'Brak producenta'} - dodano '
        '${device.createdAt.toLocal()}',
      ),
      onTap: onSelected,
    );
  }
}
