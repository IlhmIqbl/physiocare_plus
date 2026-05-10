class ExerciseStep {
  final String description;
  final String videoUrl;
  final int durationSeconds;

  const ExerciseStep({
    required this.description,
    required this.videoUrl,
    required this.durationSeconds,
  });

  factory ExerciseStep.fromMap(Map<String, dynamic> map) {
    return ExerciseStep(
      description: map['description'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? '',
      durationSeconds: map['durationSeconds'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'videoUrl': videoUrl,
        'durationSeconds': durationSeconds,
      };
}
