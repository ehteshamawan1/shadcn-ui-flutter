import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ui/ska_card.dart';

/// Filter option for dropdowns and chips
class FilterOption {
  final String value;
  final String label;
  final int? count;
  final IconData? icon;
  final Color? color;

  const FilterOption({
    required this.value,
    required this.label,
    this.count,
    this.icon,
    this.color,
  });
}

/// Configuration for a single filter
class FilterConfig {
  final String id;
  final String label;
  final FilterType type;
  final dynamic initialValue;
  final List<FilterOption>? options;
  final String? hint;
  final bool showCount;
  final bool showAllOption;
  final String allOptionLabel;

  const FilterConfig({
    required this.id,
    required this.label,
    required this.type,
    this.initialValue,
    this.options,
    this.hint,
    this.showCount = true,
    this.showAllOption = true,
    this.allOptionLabel = 'Alle',
  });
}

enum FilterType {
  search,
  dropdown,
  chip,
  summaryCard,
  date,
  dateRange,
  checkbox,
  tristate,
}

/// Callback for filter changes
typedef FilterCallback = void Function(String filterId, dynamic value);

/// A standardized, reusable filter bar widget
class FilterBar extends StatelessWidget {
  final List<FilterConfig> filters;
  final Map<String, dynamic> values;
  final FilterCallback onFilterChanged;
  final VoidCallback? onReset;
  final bool showResetButton;
  final EdgeInsets padding;
  final double spacing;

  const FilterBar({
    super.key,
    required this.filters,
    required this.values,
    required this.onFilterChanged,
    this.onReset,
    this.showResetButton = true,
    this.padding = const EdgeInsets.all(12),
    this.spacing = 12,
  });

  bool get _hasActiveFilters {
    for (final filter in filters) {
      final value = values[filter.id];
      if (filter.type == FilterType.search && value != null && value.toString().isNotEmpty) {
        return true;
      }
      if (filter.type == FilterType.dropdown && value != null && value != 'alle' && value != 'all') {
        return true;
      }
      if (filter.type == FilterType.chip && value != null && value != 'alle' && value != 'all') {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SkaCard(
      padding: padding,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...filters.map((filter) => _buildFilter(context, filter)),
          if (showResetButton && _hasActiveFilters)
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Nulstil'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilter(BuildContext context, FilterConfig filter) {
    switch (filter.type) {
      case FilterType.search:
        return _SearchFilter(
          config: filter,
          value: values[filter.id]?.toString() ?? '',
          onChanged: (value) => onFilterChanged(filter.id, value),
        );
      case FilterType.dropdown:
        return _DropdownFilter(
          config: filter,
          value: values[filter.id]?.toString(),
          onChanged: (value) => onFilterChanged(filter.id, value),
        );
      case FilterType.chip:
        return _ChipFilter(
          config: filter,
          value: values[filter.id]?.toString() ?? 'alle',
          onChanged: (value) => onFilterChanged(filter.id, value),
        );
      case FilterType.tristate:
        return _TristateFilter(
          config: filter,
          value: values[filter.id]?.toString() ?? 'alle',
          onChanged: (value) => onFilterChanged(filter.id, value),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Search filter field
class _SearchFilter extends StatefulWidget {
  final FilterConfig config;
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchFilter({
    required this.config,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SearchFilter> createState() => _SearchFilterState();
}

class _SearchFilterState extends State<_SearchFilter> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_SearchFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, size: 18, color: AppColors.mutedForeground),
          hintText: widget.config.hint ?? 'Søg...',
          isDense: true,
          contentPadding: AppSpacing.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
          border: const OutlineInputBorder(),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: AppColors.mutedForeground),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                )
              : null,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// Dropdown filter field
class _DropdownFilter extends StatelessWidget {
  final FilterConfig config;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.config,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = config.options ?? [];
    final allOptions = config.showAllOption
        ? [
            FilterOption(value: 'alle', label: config.allOptionLabel),
            ...options,
          ]
        : options;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 200),
      child: DropdownButtonFormField<String>(
        value: value ?? 'alle',
        isExpanded: true,
        decoration: InputDecoration(
          labelText: config.label,
          isDense: true,
          contentPadding: AppSpacing.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
          border: const OutlineInputBorder(),
        ),
        items: allOptions.map((opt) {
          final countText = config.showCount && opt.count != null ? ' (${opt.count})' : '';
          return DropdownMenuItem(
            value: opt.value,
            child: Text(
              '${opt.label}$countText',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        selectedItemBuilder: (context) {
          return allOptions.map((opt) {
            final countText = config.showCount && opt.count != null ? ' (${opt.count})' : '';
            return Text(
              '${opt.label}$countText',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
          }).toList();
        },
      ),
    );
  }
}

/// Chip filter (horizontal scrollable)
class _ChipFilter extends StatelessWidget {
  final FilterConfig config;
  final String value;
  final ValueChanged<String> onChanged;

  const _ChipFilter({
    required this.config,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = config.options ?? [];
    final allOptions = config.showAllOption
        ? [
            FilterOption(value: 'alle', label: config.allOptionLabel),
            ...options,
          ]
        : options;

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allOptions.map((opt) {
          final isSelected = value == opt.value;
          final countText = config.showCount && opt.count != null ? ' (${opt.count})' : '';

          return FilterChip(
            label: Text('${opt.label}$countText'),
            selected: isSelected,
            onSelected: (_) => onChanged(opt.value),
            avatar: opt.icon != null
                ? Icon(opt.icon, size: 16, color: isSelected ? Colors.white : opt.color)
                : null,
            backgroundColor: opt.color?.withValues(alpha: 0.1),
            selectedColor: opt.color ?? Theme.of(context).colorScheme.primary,
            labelStyle: AppTypography.xs.copyWith(
              color: isSelected ? AppColors.primaryForeground : AppColors.foreground,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Tristate checkbox filter (alle/yes/no)
class _TristateFilter extends StatelessWidget {
  final FilterConfig config;
  final String value;
  final ValueChanged<String> onChanged;

  const _TristateFilter({
    required this.config,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = config.options ?? [];
    if (options.length < 2) return const SizedBox.shrink();

    final yesOption = options[0];
    final noOption = options.length > 1 ? options[1] : null;

    final bool? checkboxValue = value == yesOption.value
        ? true
        : (noOption != null && value == noOption.value)
            ? false
            : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: checkboxValue,
          tristate: true,
          onChanged: (newValue) {
            if (newValue == true) {
              onChanged(yesOption.value);
            } else if (newValue == false && noOption != null) {
              onChanged(noOption.value);
            } else {
              onChanged('alle');
            }
          },
        ),
        GestureDetector(
          onTap: () {
            // Cycle through: alle -> yes -> no -> alle
            if (value == 'alle') {
              onChanged(yesOption.value);
            } else if (value == yesOption.value && noOption != null) {
              onChanged(noOption.value);
            } else {
              onChanged('alle');
            }
          },
          child: Row(
            children: [
              if (yesOption.icon != null) ...[
                Icon(yesOption.icon, size: 18),
                const SizedBox(width: 4),
              ],
              Text(
                value == 'alle'
                    ? config.label
                    : value == yesOption.value
                        ? yesOption.label
                        : noOption?.label ?? config.label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: value == yesOption.value
                      ? AppColors.success
                      : value == noOption?.value
                          ? AppColors.warning
                          : null,
                ),
              ),
              if (config.showCount) ...[
                const SizedBox(width: 4),
                Text(
                  value == yesOption.value
                      ? '(${yesOption.count ?? 0})'
                      : value == noOption?.value
                          ? '(${noOption?.count ?? 0})'
                          : '(${(yesOption.count ?? 0) + (noOption?.count ?? 0)})',
                  style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Summary cards filter (interactive stat cards)
class SummaryCardsFilter extends StatelessWidget {
  final List<FilterOption> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final bool showAllCard;
  final int? totalCount;
  final String allLabel;

  const SummaryCardsFilter({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.showAllCard = true,
    this.totalCount,
    this.allLabel = 'Total',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final allOptions = showAllCard
            ? [
                ...options,
                FilterOption(
                  value: 'alle',
                  label: allLabel,
                  count: totalCount ?? options.fold<int>(0, (sum, opt) => sum + (opt.count ?? 0)),
                  icon: Icons.apps,
                  color: AppColors.primary,
                ),
              ]
            : options;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: allOptions.map((opt) {
            final isSelected = selectedValue == opt.value;
            return _SummaryCard(
              option: opt,
              isSelected: isSelected,
              onTap: () => onChanged(isSelected ? 'alle' : opt.value),
              maxWidth: constraints.maxWidth,
              cardCount: allOptions.length,
            );
          }).toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final FilterOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final double maxWidth;
  final int cardCount;

  const _SummaryCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.maxWidth,
    required this.cardCount,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = ((maxWidth - (12 * (cardCount - 1))) / cardCount).clamp(100.0, 180.0);
    final color = option.color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.icon != null) Icon(option.icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              '${option.count ?? 0}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter results header showing count and active filters
class FilterResultsHeader extends StatelessWidget {
  final int resultCount;
  final String itemLabel;
  final Map<String, String> activeFilters;
  final VoidCallback? onReset;

  const FilterResultsHeader({
    super.key,
    required this.resultCount,
    this.itemLabel = 'resultater',
    this.activeFilters = const {},
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final filterText = activeFilters.entries
        .where((e) => e.value.isNotEmpty && e.value != 'alle' && e.value != 'all')
        .map((e) => e.value)
        .join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '$resultCount $itemLabel${filterText.isNotEmpty ? ' ($filterText)' : ''}',
            style: AppTypography.xs.copyWith(color: AppColors.mutedForeground),
          ),
          if (activeFilters.isNotEmpty && onReset != null) ...[
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Nulstil'),
              onPressed: onReset,
            ),
          ],
        ],
      ),
    );
  }
}
