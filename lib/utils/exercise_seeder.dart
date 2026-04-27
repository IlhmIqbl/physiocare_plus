import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseSeeder {
  static Future<void> seed() async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    final exercises = [
      {
        'title': 'Shoulder Pendulum',
        'description': 'Gently swing your arm in small circles to relieve shoulder tension and improve mobility.',
        'bodyArea': 'shoulder',
        'difficulty': 'easy',
        'duration': 300,
        'videoUrl': '',
        'thumbnailUrl': '',
        'targetPainTypes': ['rotator_cuff', 'frozen_shoulder'],
        'steps': [
          'Stand next to a table and lean forward, supporting yourself with your good arm.',
          'Let your affected arm hang down freely.',
          'Gently swing your arm in small clockwise circles (10 reps).',
          'Repeat counterclockwise (10 reps).',
          'Rest for 30 seconds and repeat 3 sets.',
        ],
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Cat-Cow Stretch',
        'description': 'A gentle spinal flexion and extension sequence to relieve lower back pain.',
        'bodyArea': 'lower_back',
        'difficulty': 'easy',
        'duration': 240,
        'videoUrl': '',
        'thumbnailUrl': '',
        'targetPainTypes': ['muscle_tension', 'disc_pain'],
        'steps': [
          'Start on hands and knees, wrists under shoulders, knees under hips.',
          'Inhale: drop your belly, lift your head and tailbone (Cow).',
          'Exhale: round your spine toward the ceiling, tuck chin and pelvis (Cat).',
          'Repeat slowly for 10 cycles.',
          'Move gently — do not force the range of motion.',
        ],
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Quad Sets',
        'description': 'Tighten the quadriceps muscle to strengthen the knee without bending it.',
        'bodyArea': 'knee',
        'difficulty': 'easy',
        'duration': 180,
        'videoUrl': '',
        'thumbnailUrl': '',
        'targetPainTypes': ['post_surgery', 'osteoarthritis'],
        'steps': [
          'Sit or lie on your back with your leg straight.',
          'Place a small rolled towel under your knee.',
          'Tighten your thigh muscle by pressing the back of your knee down.',
          'Hold for 5 seconds, then relax.',
          'Repeat 15 times per leg.',
        ],
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Hip Flexor Stretch',
        'description': 'Stretch the hip flexors to reduce hip pain and improve posture.',
        'bodyArea': 'hip',
        'difficulty': 'medium',
        'duration': 240,
        'videoUrl': '',
        'thumbnailUrl': '',
        'targetPainTypes': ['hip_tightness', 'lower_back_referred'],
        'steps': [
          'Kneel on one knee, the other foot in front (lunge position).',
          'Keep your torso upright.',
          'Gently push your hips forward until you feel a stretch at the front of your kneeling hip.',
          'Hold for 30 seconds.',
          'Repeat 3 times each side.',
        ],
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Chin Tucks',
        'description': 'Strengthen deep neck flexors to relieve neck pain and correct forward head posture.',
        'bodyArea': 'neck',
        'difficulty': 'easy',
        'duration': 180,
        'videoUrl': '',
        'thumbnailUrl': '',
        'targetPainTypes': ['cervical_pain', 'headache'],
        'steps': [
          'Sit or stand tall with relaxed shoulders.',
          'Without bending your neck, slide your head straight back (making a double chin).',
          'Hold for 3 seconds.',
          'Return to neutral.',
          'Repeat 10 times, 3 sets.',
        ],
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Ankle Alphabet',
        'description': 'Trace the alphabet with your foot to improve ankle mobility and circulation.',
        'bodyArea': 'ankle',
        'difficulty': 'easy',
        'duration': 300,
        'videoUrl': '',
        'thumbnailUrl': '',
        'targetPainTypes': ['sprain', 'stiffness'],
        'steps': [
          'Sit in a chair with your foot elevated.',
          'Using only your ankle and foot (not your whole leg), trace each letter of the alphabet.',
          'Move slowly and deliberately through the full range of motion.',
          'Complete A–Z once per foot.',
          'Rest 1 minute, then repeat.',
        ],
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
    ];

    for (final exercise in exercises) {
      final ref = db.collection('exercises').doc();
      batch.set(ref, exercise);
    }

    await batch.commit();
  }
}
