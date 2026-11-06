/// The four difficulty tiers and their rules.
///
/// [levels] is how many levels must be passed to finish the tier.
/// [minClues]..[maxClues] is the range of given numbers a generated puzzle
/// should have. Fewer clues = harder puzzle.
enum Difficulty {
  easy('Easy', 20, 38, 42),
  medium('Medium', 20, 31, 34),
  hard('Hard', 20, 27, 29),
  extreme('Extremely Hard', 40, 23, 25);

  const Difficulty(this.label, this.levels, this.minClues, this.maxClues);

  final String label;
  final int levels;
  final int minClues;
  final int maxClues;

  /// The tier that must be fully passed before this one unlocks.
  Difficulty? get previous => index == 0 ? null : Difficulty.values[index - 1];

  static Difficulty fromName(String name) =>
      Difficulty.values.firstWhere((d) => d.name == name, orElse: () => Difficulty.easy);
}
