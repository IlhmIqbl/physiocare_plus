import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseSeeder {
  // Empty — admin uploads videos via AdminVideoUploadScreen.
  // Keys follow the pattern bodyArea_difficulty (lowercase, underscores).
  static const _stepVideoMap = <String, String>{};

  /// Deletes every document in the exercises collection.
  static Future<void> clearExercises() async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('exercises').get();
    const batchSize = 400;
    for (var i = 0; i < snapshot.docs.length; i += batchSize) {
      final batch = db.batch();
      final chunk = snapshot.docs
          .sublist(i, (i + batchSize).clamp(0, snapshot.docs.length));
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Clears then seeds 21 exercises (7 body areas × 3 difficulties).
  static Future<void> seed() async {
    await clearExercises();
    final db = FirebaseFirestore.instance;
    final all = _exercises();
    const batchSize = 400;
    for (var i = 0; i < all.length; i += batchSize) {
      final batch = db.batch();
      final chunk =
          all.sublist(i, (i + batchSize).clamp(0, all.length));
      for (final exercise in chunk) {
        batch.set(db.collection('exercises').doc(), exercise);
      }
      await batch.commit();
    }
  }

  /// Patches videoUrl on every step of every existing exercise document.
  static Future<int> updateStepVideos() async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('exercises').get();
    int updated = 0;
    const batchSize = 400;
    for (var i = 0; i < snapshot.docs.length; i += batchSize) {
      final batch = db.batch();
      final chunk = snapshot.docs
          .sublist(i, (i + batchSize).clamp(0, snapshot.docs.length));
      for (final doc in chunk) {
        final data = doc.data();
        final bodyArea =
            (data['bodyArea'] as String? ?? '').toLowerCase().replaceAll(' ', '_');
        final difficulty = (data['difficulty'] as String? ?? '').toLowerCase();
        final videoUrl = _stepVideoMap['${bodyArea}_$difficulty'] ?? '';
        if (videoUrl.isEmpty) continue;
        final thumbnailUrl =
            '${videoUrl.replaceFirst('f_mp4,q_auto', 'f_jpg,q_auto')}.jpg';
        final rawSteps = data['steps'] as List<dynamic>? ?? [];
        final updatedSteps = rawSteps.map((s) {
          final step = Map<String, dynamic>.from(s as Map);
          step['videoUrl'] = videoUrl;
          return step;
        }).toList();
        batch.update(doc.reference, {
          'videoUrl': videoUrl,
          'thumbnailUrl': thumbnailUrl,
          'steps': updatedSteps,
        });
        updated++;
      }
      await batch.commit();
    }
    return updated;
  }

  static List<Map<String, dynamic>> _exercises() {
    final now = Timestamp.now();

    Map<String, dynamic> ex({
      required String title,
      required String description,
      required String bodyArea,
      required String difficulty,
      required List<String> sets,
      int setDurationSeconds = 45,
    }) {
      final totalDuration = sets.length * setDurationSeconds;
      return {
        'title': title,
        'description': description,
        'bodyArea': bodyArea,
        'difficulty': difficulty,
        'duration': totalDuration,
        'videoUrl': '',
        'thumbnailUrl': '',
        'targetPainTypes': const <String>[],
        'steps': sets
            .map((s) => {
                  'description': s,
                  'videoUrl': '',
                  'durationSeconds': setDurationSeconds,
                })
            .toList(),
        'isActive': true,
        'createdAt': now,
      };
    }

    return [
      // ── ANKLE ──────────────────────────────────────────────────────────────
      ex(
        title: 'Ankle Mobility Circles',
        description:
            'Gentle seated ankle circles to restore range of motion and reduce stiffness after ankle injury or surgery.',
        bodyArea: 'ankle',
        difficulty: 'easy',
        sets: [
          'Sit in a chair with feet flat on the floor. Lift your affected foot slightly off the ground.',
          'Slowly rotate your ankle clockwise in the largest circle you can manage without pain. Complete 10 circles.',
          'Reverse direction — rotate counterclockwise for 10 circles. Lower your foot and rest.',
        ],
      ),
      ex(
        title: 'Standing Calf Raises',
        description:
            'Progressive weight-bearing exercise to strengthen the calf-Achilles complex and improve ankle stability.',
        bodyArea: 'ankle',
        difficulty: 'medium',
        setDurationSeconds: 40,
        sets: [
          'Stand behind a chair with both hands lightly on the back for balance. Feet hip-width apart.',
          'Rise up slowly onto both tiptoes, hold for 2 seconds at the top, then lower slowly over 3 seconds.',
          'Perform 12 repetitions. On the final set, lower on one foot only if comfortable.',
          'Rest 20 seconds, then repeat.',
        ],
      ),
      ex(
        title: 'Single-Leg Balance Progression',
        description:
            'Progressive single-leg stance challenges proprioception and dynamic ankle stability.',
        bodyArea: 'ankle',
        difficulty: 'hard',
        setDurationSeconds: 30,
        sets: [
          'Stand on your affected leg with knee soft. Hold near a wall for safety. Balance for 20–30 seconds.',
          'Close your eyes and balance on your affected leg for 20 seconds. Open eyes if you feel unsafe.',
          'Balance on your affected leg; slowly reach forward with your free leg then return. 8 reps each direction.',
          'Balance and perform small single-leg calf raises: 10 slow reps without touching down.',
        ],
      ),

      // ── ELBOW ──────────────────────────────────────────────────────────────
      ex(
        title: 'Elbow Flexion & Extension',
        description:
            'Gentle active range-of-motion exercise to restore full elbow movement following injury or prolonged immobilisation.',
        bodyArea: 'elbow',
        difficulty: 'easy',
        sets: [
          'Sit upright with your arm relaxed at your side, palm facing forward. Slowly bend your elbow as far as comfortable.',
          'Hold the bent position for 3 seconds, then slowly straighten the elbow fully. Repeat 10 times.',
          'Rest 15 seconds. Rotate forearm palm-up then palm-down 10 times each (pronation/supination).',
        ],
      ),
      ex(
        title: 'Wrist Curl Strengthening',
        description:
            'Forearm and elbow strengthening using bodyweight or a light object to load the elbow flexors and extensors.',
        bodyArea: 'elbow',
        difficulty: 'medium',
        sets: [
          'Sit with forearm resting on your thigh, palm facing up, holding a light object (e.g. full water bottle). Curl the wrist upward 15 times.',
          'Flip palm down. Slowly extend wrist upward 15 times to work the extensor muscles.',
          'Rest arm on the table. Bend elbow from 0° to full flex against light resistance for 12 slow reps.',
          'Final set: isometric hold — push hand against opposite palm at 90° for 10 seconds × 3.',
        ],
      ),
      ex(
        title: 'Resistance Band Elbow Extension',
        description:
            'Resistance band tricep strengthening that loads the elbow through full extension range.',
        bodyArea: 'elbow',
        difficulty: 'hard',
        setDurationSeconds: 50,
        sets: [
          'Anchor a resistance band at shoulder height. Stand facing anchor, hold band with affected arm at shoulder height, elbow at 90°.',
          'Push forearm down to full elbow extension in 2 seconds. Return slowly in 3 seconds. 15 reps.',
          'Switch to overhead position: hold band overhead with elbow bent behind head. Extend elbow fully × 12 reps.',
          'Isometric burnout: hold elbow at 45° against band for 30 seconds without moving. Shake out arm and rest.',
        ],
      ),

      // ── HIP ────────────────────────────────────────────────────────────────
      ex(
        title: 'Supine Hip Flexor Stretch',
        description:
            'Lying hip flexor stretch to reduce anterior hip tightness and improve hip extension mobility.',
        bodyArea: 'hip',
        difficulty: 'easy',
        sets: [
          'Lie on your back at the edge of a firm bed or floor mat. Pull one knee to your chest while the other leg hangs or rests flat.',
          'Hold the stretch for 30 seconds. You should feel a gentle stretch in the front of the hanging/flat-leg hip.',
          'Switch sides. Pull opposite knee to chest; let the other leg relax long. Hold 30 seconds.',
        ],
      ),
      ex(
        title: 'Side-Lying Hip Abduction',
        description:
            'Targets the gluteus medius and hip abductors — essential for hip and knee alignment during walking.',
        bodyArea: 'hip',
        difficulty: 'medium',
        sets: [
          'Lie on your unaffected side with hips stacked and body straight. Rest your head on your lower arm.',
          'Slowly lift your top (affected) leg to 30–40° keeping it straight and toes pointing forward. Lower slowly × 15 reps.',
          'Add small circles: lift leg to 30° and draw 10 clockwise then 10 counterclockwise circles. Lower and rest.',
          'Roll to other side. Repeat lifts × 15 reps to balance both hips.',
        ],
      ),
      ex(
        title: 'Hip Bridge',
        description:
            'Glute and posterior hip strengthening in a safe supine position — foundational for hip stability.',
        bodyArea: 'hip',
        difficulty: 'hard',
        sets: [
          'Lie on your back, knees bent to 90°, feet flat on the floor hip-width apart. Arms flat at your sides.',
          'Squeeze glutes and lift hips until your body forms a straight line from shoulders to knees. Hold 3 seconds. Lower slowly. Repeat × 15.',
          'Single-leg bridge: extend one leg straight, hold bridge on the other. 10 reps each side.',
          'Bridge with march: hold bridge position and alternately lift each knee toward ceiling × 20 total reps.',
        ],
      ),

      // ── KNEE ───────────────────────────────────────────────────────────────
      ex(
        title: 'Quad Set',
        description:
            'Isometric quadriceps activation — the safest starting point for knee rehabilitation after injury or surgery.',
        bodyArea: 'knee',
        difficulty: 'easy',
        sets: [
          'Sit or lie with your leg straight. Place a small rolled towel under your knee. Tighten the quad muscle by pressing the back of your knee down toward the floor.',
          'Hold the contraction for 5 seconds, then release fully. Repeat 15 times. Focus on feeling the muscle above the kneecap activate.',
          'Rest 15 seconds, then repeat 15 more contractions. If you feel no pain you may progress to short-arc quads.',
        ],
      ),
      ex(
        title: 'Seated Leg Extension',
        description:
            'Controlled open-chain knee strengthening targeting the quadriceps through 0–90° arc.',
        bodyArea: 'knee',
        difficulty: 'medium',
        sets: [
          'Sit near the edge of a firm chair. Straighten your affected leg until it is parallel to the floor. Hold 3 seconds.',
          'Lower slowly over 3 seconds. Do not let the foot drop. 12 reps, focusing on smooth eccentric control.',
          'Add ankle weight or resistance band if comfortable: 3 × 12 reps with a 2-second hold at the top.',
          'Final set: terminal arc only — from 30° to full extension — 15 fast reps for VMO activation.',
        ],
      ),
      ex(
        title: 'Mini Squat Progression',
        description:
            'Progressive closed-chain knee loading through pain-free range — builds strength for daily activities.',
        bodyArea: 'knee',
        difficulty: 'hard',
        sets: [
          'Stand with feet hip-width apart, hands on a chair for support. Bend both knees to 30° (quarter squat). Hold 2 seconds. Rise. × 15 reps.',
          'Progress to 60° squat if pain-free. Slow descent (3 sec down, 1 sec hold, 2 sec up). × 12 reps.',
          'Single-leg mini squat: light touch on chair, bend affected knee to 30°. × 10 reps. Control is more important than depth.',
          'Wall sit: stand against a wall and slide down to 45–60°. Hold for 30 seconds, working up to 45 seconds.',
        ],
      ),

      // ── LOW BACK ───────────────────────────────────────────────────────────
      ex(
        title: 'Cat-Cow Spinal Mobility',
        description:
            'Classic spinal mobility exercise to reduce low back stiffness and restore segmental movement.',
        bodyArea: 'low back',
        difficulty: 'easy',
        sets: [
          'Start on all fours: hands under shoulders, knees under hips. Neutral spine.',
          'Cat: exhale and round your spine toward the ceiling, tuck pelvis, drop head. Hold 3 seconds.',
          'Cow: inhale and let your belly drop, lift head and tailbone. Hold 3 seconds. Flow between Cat and Cow × 10 cycles.',
        ],
      ),
      ex(
        title: 'Bird Dog',
        description:
            'Anti-rotation core stability exercise that safely loads the lumbar spine extensors and glutes.',
        bodyArea: 'low back',
        difficulty: 'medium',
        sets: [
          'On all fours, brace core gently. Extend right arm forward and left leg back simultaneously until both are level with the spine. Hold 3 seconds.',
          'Return to start without touching knee to floor. Repeat on opposite side (left arm, right leg). That is 1 rep. × 10 reps each side.',
          'Add a crunch at the end of each rep: bring elbow and knee together under body, then extend. × 8 reps each side.',
          'Slow eccentric hold: extend and hold 5 seconds each position. × 6 reps each side.',
        ],
      ),
      ex(
        title: 'Dead Bug',
        description:
            'Advanced anti-extension core exercise that demands lumbar neutral control under limb loading.',
        bodyArea: 'low back',
        difficulty: 'hard',
        sets: [
          'Lie on your back. Press your lower back firmly into the floor (posterior pelvic tilt). Raise arms to the ceiling and hips to 90°.',
          'Slowly lower right arm overhead and left leg toward the floor simultaneously — do NOT let your back arch. Return. 10 reps each side.',
          'Add a long exhale as you lower limbs to increase intra-abdominal pressure. × 8 reps each side.',
          'Opposite-arm, opposite-leg with a 3-second hold at the bottom position. × 6 reps each side.',
        ],
      ),

      // ── NECK ───────────────────────────────────────────────────────────────
      ex(
        title: 'Neck Range of Motion',
        description:
            'Active range-of-motion routine covering all cervical planes — the essential first step for neck rehabilitation.',
        bodyArea: 'neck',
        difficulty: 'easy',
        sets: [
          'Sit tall. Slowly turn head right as far as comfortable. Hold 3 seconds. Return to centre. Repeat left. × 5 each side.',
          'Tilt ear toward shoulder right, hold 3 seconds, return. Tilt left, hold 3 seconds. × 5 each side. Do not shrug shoulders.',
          'Slowly nod chin down toward chest, hold 3 seconds, return. Gently extend head back to neutral. × 8 nods. Do not force extension.',
        ],
      ),
      ex(
        title: 'Cervical Retraction (Chin Tuck)',
        description:
            'Chin tuck strengthens the deep cervical flexors and corrects forward head posture — core neck rehab exercise.',
        bodyArea: 'neck',
        difficulty: 'medium',
        sets: [
          'Sit or stand against a wall with back straight. Without lifting chin, gently glide your head back to create a "double chin". Hold 5 seconds. × 10 reps.',
          'Add light overpressure: place two fingers on chin and gently increase the retraction. Hold 5 seconds. × 8 reps.',
          'Retraction with rotation: retract chin then slowly turn head right 45°, hold 3 seconds, return. Repeat left. × 6 each side.',
          'Retraction with lateral tilt: retract chin then tilt ear toward shoulder 20°, hold 3 seconds. × 6 each side.',
        ],
      ),
      ex(
        title: 'Neck Isometric Strengthening',
        description:
            'Isometric resistance training for all cervical directions — builds endurance without joint compression.',
        bodyArea: 'neck',
        difficulty: 'hard',
        setDurationSeconds: 50,
        sets: [
          'Flexion resistance: place palm on forehead, push head gently into hand. Hold 10 seconds × 5 reps. Do not let head move.',
          'Extension resistance: cup both hands behind head, push head back into hands. Hold 10 seconds × 5 reps.',
          'Lateral resistance: place palm against side of head, push head sideways into hand. Hold 8 seconds × 4 each side.',
          'Rotation resistance: place palm against temple, push head into rotation against resistance. Hold 8 seconds × 4 each side.',
        ],
      ),

      // ── SHOULDER ───────────────────────────────────────────────────────────
      ex(
        title: 'Pendulum Swing',
        description:
            'Gravity-assisted shoulder distraction to reduce joint compression and restore early range of motion.',
        bodyArea: 'shoulder',
        difficulty: 'easy',
        sets: [
          'Lean forward with good arm supported on a table. Let affected arm hang freely. Gently swing arm forward and back like a pendulum × 20.',
          'Swing arm side to side × 20. Use momentum from body, not shoulder muscles. The shoulder should feel relaxed.',
          'Make small clockwise circles × 10, then counterclockwise × 10. Gradually increase circle size only if pain-free.',
        ],
      ),
      ex(
        title: 'Shoulder Flexion with Band',
        description:
            'Controlled anterior shoulder strengthening through a progressive flexion arc using a resistance band.',
        bodyArea: 'shoulder',
        difficulty: 'medium',
        sets: [
          'Stand on resistance band. Hold end with affected arm, palm facing back. Slowly raise arm forward to shoulder height in 3 seconds. Lower in 3 seconds. × 12.',
          'Raise to 120° (above shoulder) if pain-free. Pause 2 seconds at top. × 10 reps.',
          'Scaption: lift at a 30° angle (thumb up) to shoulder height × 12 reps. This targets the supraspinatus.',
          'Band pull-apart at shoulder height: hold band with both hands, pull apart to "T" position × 15 reps for posterior capsule.',
        ],
      ),
      ex(
        title: 'Side-Lying External Rotation',
        description:
            'Isolated infraspinatus and teres minor strengthening — critical for rotator cuff rehabilitation and shoulder stability.',
        bodyArea: 'shoulder',
        difficulty: 'hard',
        setDurationSeconds: 50,
        sets: [
          'Lie on unaffected side. Affected arm bent at 90° elbow, forearm across stomach. Slowly rotate forearm up toward ceiling × 15. Lower slowly.',
          'Hold at top position for 3 seconds before lowering. × 12 reps. Keep elbow pinned to side throughout.',
          'Add light resistance: dumbbell or wrist weight 0.5–1 kg. × 12 slow reps with 2-second hold at top.',
          'Standing band external rotation: elbow at 90°, rotate forearm outward against band × 15 reps. Control is essential.',
        ],
      ),
    ];
  }
}
