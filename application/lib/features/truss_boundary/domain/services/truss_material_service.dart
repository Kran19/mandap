import '../entities/boundary_truss_run.dart';
import '../entities/truss_material_requirement.dart';
import '../entities/truss_size.dart';

/// The stateless Material Resolver.
/// 
/// Consumes pure Geometric Runs and resolves them into Material Requirements.
/// It NEVER modifies the underlying geometry.
class TrussMaterialService {
  const TrussMaterialService();

  /// Resolves a single geometric span into a list of material requirements based on the
  /// standard stock sizes available, or falls back to a custom requirement.
  static List<TrussMaterialRequirement> resolveRun(BoundaryTrussRun run) {
    // Determine the optimal combination of standard truss lengths to fulfill the geometric span.
    // In this implementation, we attempt to fulfill the span using the standard 30, 25, 20, 10 ft pieces.
    // If the span is perfectly divisible or a known pattern, we use stock.
    // Otherwise, we output a CUSTOM requirement.

    final span = run.geometricSpan;
    
    // Simplistic stock resolver for demonstration:
    // Try to break down the span greedily starting from 30ft.
    // This is a naive resolver; in reality, this would query inventory rules.
    double remaining = span;
    final requirements = <TrussMaterialRequirement>[];
    int reqIndex = 0;

    // Check if it's an exact match for a single known size
    final exactMatch = _getExactMatch(span);
    if (exactMatch != null) {
      return [
        TrussMaterialRequirement(
          id: '${run.id}_mat_0',
          requiredLength: span,
          stockType: exactMatch,
          isCustom: false,
        )
      ];
    }

    // Try greedy breakdown (30s, then 10s etc - simplified logic)
    while (remaining >= 30.0) {
      requirements.add(
        TrussMaterialRequirement(
          id: '${run.id}_mat_$reqIndex',
          requiredLength: 30.0,
          stockType: TrussSize.thirty,
          isCustom: false,
        ),
      );
      remaining -= 30.0;
      reqIndex++;
    }

    if (remaining > 0) {
      final match = _getExactMatch(remaining);
      if (match != null) {
        requirements.add(
          TrussMaterialRequirement(
            id: '${run.id}_mat_$reqIndex',
            requiredLength: remaining,
            stockType: match,
            isCustom: false,
          ),
        );
      } else {
        // If remaining cannot be cleanly resolved, it's a CUSTOM cut.
        requirements.add(
          TrussMaterialRequirement(
            id: '${run.id}_mat_$reqIndex',
            requiredLength: remaining,
            stockType: null,
            isCustom: true,
          ),
        );
      }
    }

    return requirements;
  }

  static TrussSize? _getExactMatch(double length) {
    if ((length - 10.0).abs() < 0.001) return TrussSize.ten;
    if ((length - 20.0).abs() < 0.001) return TrussSize.twenty;
    if ((length - 25.0).abs() < 0.001) return TrussSize.twentyFive;
    if ((length - 30.0).abs() < 0.001) return TrussSize.thirty;
    if ((length - 40.0).abs() < 0.001) return TrussSize.forty;
    if ((length - 50.0).abs() < 0.001) return TrussSize.fifty;
    return null;
  }
}
