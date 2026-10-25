enum GhostCostume {
  original('original', 'Original Ghost', 'The little boo you know and love.'),
  vampire('vampire', 'Vampire Ghost', 'Tiny fangs. A cape full of charm.'),
  skeleton('skeleton', 'Skeleton Ghost', 'Cozy bones for a moonlight dash.');

  const GhostCostume(this.id, this.label, this.description);
  final String id;
  final String label;
  final String description;

  static GhostCostume fromStored(Object? value) => values.firstWhere(
    (costume) => costume.id == value,
    orElse: () => original,
  );
}
