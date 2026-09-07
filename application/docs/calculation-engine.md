# Mandap Calculation Engine Documentation

## 1. Truss Decomposition Algorithm (Dynamic Programming)

### Problem Definition
Given an edge target length $L$ in ticks and catalog piece sizes $P = \{p_1, p_2, \dots, p_n\}$ in ticks:
Find a combination $\sum p_i = L$ that minimizes total piece count $\sum 1$.

### Optimization & Tie-Breaking Rules
1. **Primary Objective**: Minimum piece count.
2. **Deterministic Tie-Breaking**:
   - Normalize each candidate sequence by sorting piece lengths descending.
   - Compare normalized sequences lexicographically.
   - Prefer the lexicographically larger sequence (e.g. $[20, 15] > [18, 17]$).

### Bounded Impossible Search Strategy
If an exact fit is impossible for length $L$, the DP table is pre-computed up to $L + \max(P)$.
- `nearestLower`: Largest reachable $len < L$ in the DP table.
- `nearestHigher`: Smallest reachable $len > L$ in the DP table.
The algorithm terminates deterministically in $O(L \cdot |P|)$ time without infinite loops.

## 2. Pole Placement Strategy

### Rule
No unsupported horizontal run may exceed 30 ft (60 ticks).

### Strategy Abstraction (`PolePlacementStrategy`)
- Default: `EvenSpacingPoleStrategy`.
- For length $L > 30.0\text{ ft}$, calculates $N = \lceil L / 30.0 \rceil$ equal spans and places $N - 1$ intermediate poles along the edge vector.
- Invariant: Every generated span length $S_{\text{span}} \le 30.0\text{ ft}$.
