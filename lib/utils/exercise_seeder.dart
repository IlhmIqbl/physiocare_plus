import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseSeeder {
  static String _yt(String id) => 'https://www.youtube.com/watch?v=$id';
  static String _thumb(String id) =>
      'https://img.youtube.com/vi/$id/hqdefault.jpg';

  static Future<void> seed() async {
    final db = FirebaseFirestore.instance;

    final existing = await db.collection('exercises').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    const batchSize = 500;
    final all = _exercises();

    for (var i = 0; i < all.length; i += batchSize) {
      final batch = db.batch();
      final chunk = all.sublist(i, (i + batchSize).clamp(0, all.length));
      for (final exercise in chunk) {
        batch.set(db.collection('exercises').doc(), exercise);
      }
      await batch.commit();
    }
  }

  static List<Map<String, dynamic>> _exercises() {
    final now = Timestamp.now();

    Map<String, dynamic> ex({
      required String title,
      required String description,
      required String bodyArea,
      required String difficulty,
      required int duration,
      required String videoId,
      required List<String> targetPainTypes,
      required List<String> steps,
    }) {
      final url = videoId.isNotEmpty ? _yt(videoId) : '';
      final thumb = videoId.isNotEmpty ? _thumb(videoId) : '';
      return {
        'title': title,
        'description': description,
        'bodyArea': bodyArea,
        'difficulty': difficulty,
        'duration': duration,
        'videoUrl': url,
        'thumbnailUrl': thumb,
        'targetPainTypes': targetPainTypes,
        'steps': steps,
        'isActive': true,
        'createdAt': now,
      };
    }

    return [
      // ─────────────────────────── SHOULDER ───────────────────────────

      // Shoulder – Easy
      ex(
        title: 'Shoulder Pendulum',
        description:
            'Gently swing your arm in small circles to relieve shoulder tension and improve range of motion. Ideal as a first step after shoulder injury.',
        bodyArea: 'shoulder',
        difficulty: 'easy',
        duration: 300,
        videoId: 'Vhfna_PExbk',
        targetPainTypes: ['frozen_shoulder', 'impingement', 'arthritis'],
        steps: [
          'Stand next to a table and lean forward, supporting yourself with your good arm.',
          'Let your affected arm hang down freely.',
          'Gently swing your arm in small clockwise circles (10 reps).',
          'Repeat counterclockwise (10 reps).',
          'Rest 30 seconds and perform 3 sets.',
        ],
      ),
      ex(
        title: 'Simple Shoulder Pain Relief',
        description:
            'A three-movement routine targeting shoulder impingement and general shoulder soreness, suitable for any fitness level.',
        bodyArea: 'shoulder',
        difficulty: 'easy',
        duration: 240,
        videoId: '5Uoc4hXXjbY',
        targetPainTypes: ['impingement', 'muscle_tension'],
        steps: [
          'Begin with shoulder rolls: roll shoulders backward 10 times, forward 10 times.',
          'Cross-body stretch: bring one arm across your chest and hold 20 seconds each side.',
          'Doorway chest stretch: stand in a doorway, arms at 90°, lean forward gently.',
          'Hold each stretch 20–30 seconds.',
          'Repeat the sequence twice.',
        ],
      ),
      ex(
        title: 'Beginner Shoulder Strengthening',
        description:
            'Gentle strengthening exercises for the shoulder muscles, designed for seniors and beginners recovering from shoulder pain.',
        bodyArea: 'shoulder',
        difficulty: 'easy',
        duration: 360,
        videoId: 'L2aDU183SQE',
        targetPainTypes: ['weakness', 'frozen_shoulder'],
        steps: [
          'Side raises: hold light weights or water bottles, raise arms to shoulder height (10 reps).',
          'Forward raises: raise arms straight in front to shoulder height (10 reps).',
          'Wall push-ups: stand facing wall, arms shoulder-width apart, perform 10 slow push-ups.',
          'Rest 60 seconds between exercises.',
          'Complete 2 full rounds.',
        ],
      ),

      // Shoulder – Medium
      ex(
        title: 'Rotator Cuff Tests & Exercises',
        description:
            'Evidence-based rotator cuff exercises combined with simple self-tests to identify your specific shoulder weakness and target it precisely.',
        bodyArea: 'shoulder',
        difficulty: 'medium',
        duration: 480,
        videoId: 'C0g4zDXvqVk',
        targetPainTypes: ['rotator_cuff', 'impingement'],
        steps: [
          'Empty can test: raise arm at 45° angle with thumb pointing down. Note any pain.',
          'Internal rotation: using a resistance band, rotate arm inward 15 reps each side.',
          'External rotation: rotate arm outward against resistance, 15 reps each side.',
          'Scapular retraction: squeeze shoulder blades together, hold 5 seconds × 15 reps.',
          'Perform 3 sets of each exercise with 60-second rest between sets.',
        ],
      ),
      ex(
        title: 'Rotator Cuff Home Recovery',
        description:
            'A full rotator cuff rehabilitation routine for use at home after rotator cuff injury or surgery, progressing safely through key movements.',
        bodyArea: 'shoulder',
        difficulty: 'medium',
        duration: 600,
        videoId: 'gMBvjkRzYz4',
        targetPainTypes: ['rotator_cuff', 'post_surgery'],
        steps: [
          'Doorway stretch: stand in doorway with arm at 90°, gently open chest for 30 seconds.',
          'Side-lying external rotation: lie on good side, elbow bent, rotate forearm up (15 reps).',
          'Prone Y, T, W: lie face down on a bed, perform Y, T, and W shapes with arms (10 each).',
          'Band pull-apart: hold resistance band at shoulder height, pull ends apart (15 reps).',
          'Complete 3 sets of each with 45-second rest.',
        ],
      ),
      ex(
        title: 'Orthopedic Shoulder Therapy',
        description:
            'Medically guided shoulder therapy exercises demonstrated by an occupational therapist, covering all major shoulder movement planes.',
        bodyArea: 'shoulder',
        difficulty: 'medium',
        duration: 540,
        videoId: 'S4H_rZA2kSM',
        targetPainTypes: ['impingement', 'muscle_tension', 'rotator_cuff'],
        steps: [
          'Codman exercises: large pendulum circles in both directions (1 min each).',
          'Isometric shoulder flexion: press hand against wall in front, hold 10 sec × 10 reps.',
          'Isometric abduction: press hand against wall at side, hold 10 sec × 10 reps.',
          'Shoulder AROM: full active range of motion circles, 10 reps each direction.',
          'Perform the full circuit twice, resting 2 minutes between circuits.',
        ],
      ),

      // Shoulder – Hard
      ex(
        title: 'Advanced Shoulder Rehab',
        description:
            'High-level physiotherapy shoulder exercises for athletes and active individuals preparing to return to sport after shoulder injury.',
        bodyArea: 'shoulder',
        difficulty: 'hard',
        duration: 720,
        videoId: 'BMjP9ECGa-s',
        targetPainTypes: ['rotator_cuff', 'instability'],
        steps: [
          'Single-arm plank: hold plank on one arm for 20 seconds, alternate sides (3 reps each).',
          'Plyometric push-ups: explosive push-ups with hands leaving the floor (3 × 8 reps).',
          'Overhead press with resistance band: press band overhead from shoulder height (3 × 15).',
          'Diagonal band chops: pull band from low to high diagonally across body (3 × 12 each).',
          'Rest 90 seconds between sets. Stop immediately if sharp pain occurs.',
        ],
      ),
      ex(
        title: 'Post-Surgery Shoulder Strengthening',
        description:
            'Advanced strengthening exercises typically performed 8–12 weeks after shoulder surgery, under physiotherapist guidance.',
        bodyArea: 'shoulder',
        difficulty: 'hard',
        duration: 660,
        videoId: 'l97KTUD2Ty8',
        targetPainTypes: ['post_surgery', 'rotator_cuff'],
        steps: [
          'Scaption: raise arms to 45° in the scapular plane with thumbs up (3 × 15 reps).',
          'PNF D2 pattern: diagonal arm movement from hip to overhead (3 × 12 each).',
          'Prone row: lie face down on table, row resistance band to chest (3 × 15).',
          'Push-up plus: full push-up then push the floor away to protract scapula (3 × 10).',
          'Always warm up for 5 minutes before starting. Cool down with gentle stretches.',
        ],
      ),
      ex(
        title: 'Shoulder Strength & Power Phase',
        description:
            'Phase 6 shoulder rehabilitation workout focusing on strength and power development for full return to activity.',
        bodyArea: 'shoulder',
        difficulty: 'hard',
        duration: 600,
        videoId: 'XGAZmqoP8Fw',
        targetPainTypes: ['weakness', 'instability', 'post_surgery'],
        steps: [
          'Shoulder press: press dumbbells overhead from ear level (4 × 12 reps).',
          'Cable face pull: pull cable toward face, elbows high (4 × 15 reps).',
          'Lateral raise: raise dumbbells to shoulder height at sides (4 × 12 reps).',
          'Bent-over rear delt fly: hinge forward, raise arms to sides (4 × 12 reps).',
          'Rest 90 seconds between sets. Use moderate weight — control is key.',
        ],
      ),

      // ─────────────────────────── LOWER BACK ───────────────────────────

      // Lower Back – Easy
      ex(
        title: 'Beginner Core for Back Pain',
        description:
            'Physiotherapist-designed beginner core exercises specifically for lower back pain recovery and prevention of re-injury.',
        bodyArea: 'lower_back',
        difficulty: 'easy',
        duration: 420,
        videoId: 'jsKFvXVOQdg',
        targetPainTypes: ['muscle_tension', 'disc_pain', 'weakness'],
        steps: [
          'Pelvic tilt: lie on back, flatten lower back against floor, hold 5 sec × 15 reps.',
          'Knee-to-chest: gently pull one knee to chest, hold 20 sec each side.',
          'Glute bridge: feet flat, lift hips to form a straight line, hold 5 sec × 10 reps.',
          'Dead bug: lie on back, extend opposite arm and leg slowly (10 reps each side).',
          'Rest 60 seconds between exercises. Stop if pain worsens.',
        ],
      ),
      ex(
        title: 'Gentle Lower Back Exercises',
        description:
            'Five gentle exercises for lower back pain, guided by a medical doctor and physiotherapist — ideal for acute pain or first-time exercisers.',
        bodyArea: 'lower_back',
        difficulty: 'easy',
        duration: 360,
        videoId: 'kppFaMd4tQ8',
        targetPainTypes: ['acute_pain', 'muscle_tension'],
        steps: [
          'Cat-cow stretch: on hands and knees, alternate arching and rounding spine (10 reps).',
          'Child\'s pose: kneel and reach arms forward on the floor, hold 30 seconds.',
          'Piriformis stretch: figure-four stretch lying on back, hold 30 sec each side.',
          'Knee rocks: lie on back with knees bent, slowly rock knees side to side (10 reps).',
          'Perform at a slow, pain-free pace. Repeat entire sequence 2 times.',
        ],
      ),
      ex(
        title: 'Lower Back Physio Basics',
        description:
            'Core physiotherapy exercises for lower back pain covering fundamental movements to restore mobility and reduce discomfort.',
        bodyArea: 'lower_back',
        difficulty: 'easy',
        duration: 480,
        videoId: 'dRA5r4mOHy4',
        targetPainTypes: ['disc_pain', 'muscle_tension'],
        steps: [
          'Lumbar extension: lie face down on elbows, gently arch back (10 reps, hold 5 sec each).',
          'Hamstring stretch: lying on back, use towel to lift leg straight, hold 20 sec each.',
          'Sciatic nerve floss: lying down, straighten and bend knee rhythmically (15 reps each).',
          'Standing hip hinge: hinge at hips with flat back (15 reps, do not round spine).',
          'Perform twice daily in the morning and evening for best results.',
        ],
      ),

      // Lower Back – Medium
      ex(
        title: '8 Best Back Pain Exercises',
        description:
            'Eight proven exercises for lower back pain demonstrated by a medical doctor and physiotherapist — covers stretching and strengthening.',
        bodyArea: 'lower_back',
        difficulty: 'medium',
        duration: 600,
        videoId: 'HXSZHLGNSyU',
        targetPainTypes: ['disc_pain', 'muscle_tension', 'facet_joint'],
        steps: [
          'Supine twist: lie on back, drop bent knees to each side slowly (10 reps each).',
          'Single-leg glute bridge: bridge with one leg extended — hold 5 sec × 10 each.',
          'Bird-dog: on all fours, extend opposite arm and leg, hold 5 sec (10 reps each).',
          'Side plank: hold for 20–30 seconds each side (3 rounds).',
          'Hip thrust: shoulders on bench, drive hips up explosively (3 × 15 reps).',
        ],
      ),
      ex(
        title: '6 Best Back Pain Relief Exercises',
        description:
            'The six most effective lower back pain relief exercises from a licensed physical therapist for lasting pain reduction.',
        bodyArea: 'lower_back',
        difficulty: 'medium',
        duration: 540,
        videoId: 'We94A0ZuVDk',
        targetPainTypes: ['muscle_tension', 'weakness'],
        steps: [
          'McKenzie extension: lie face down, prop on forearms for 1 minute.',
          'Prone press-up: from prone position, press up with arms while hips stay down (10 reps).',
          'Standing back extension: hands on lower back, gently extend backward (10 reps).',
          'Plank: hold 20–30 seconds, maintain neutral spine (3 sets).',
          'Superman hold: face down, lift both arms and legs simultaneously (3 × 10 reps).',
        ],
      ),
      ex(
        title: '20-Minute Lower Back Rehab',
        description:
            'A complete 20-minute lower back rehabilitation routine with stretches and exercises to address both mobility and strength.',
        bodyArea: 'lower_back',
        difficulty: 'medium',
        duration: 1200,
        videoId: 'p6CMso14NWk',
        targetPainTypes: ['disc_pain', 'muscle_tension', 'stiffness'],
        steps: [
          'Warm-up: 2 minutes of gentle cat-cow and hip circles.',
          'Stretching phase (8 min): hip flexor, hamstring, and piriformis stretches 30 sec each.',
          'Strengthening phase (8 min): glute bridges, bird-dog, and dead bug 3 × 12 each.',
          'Cool-down: 2 minutes of child\'s pose and supine knee hugs.',
          'Perform 3 times per week for 4–6 weeks.',
        ],
      ),

      // Lower Back – Hard
      ex(
        title: 'Late Phase Back Strengthening',
        description:
            'Advanced late-phase rehabilitation for lower back — high-load strengthening exercises for those nearing full recovery.',
        bodyArea: 'lower_back',
        difficulty: 'hard',
        duration: 720,
        videoId: 'B6F-sQzlltA',
        targetPainTypes: ['weakness', 'disc_pain'],
        steps: [
          'Romanian deadlift: hinge at hips with weight, keep back flat (4 × 10 reps).',
          'Reverse hyperextension: hip hinge from bench, raise legs behind (3 × 15 reps).',
          'Pallof press: anti-rotation press with band from cable machine (3 × 12 each side).',
          'Good morning: barbell on back, hinge forward slowly (3 × 10 reps — light weight).',
          'Rest 2 minutes between sets. Ensure perfect form before increasing load.',
        ],
      ),
      ex(
        title: 'Back Stretch & Strengthen',
        description:
            'Occupational physiotherapy approach combining targeted stretching and progressive strengthening for chronic lower back pain.',
        bodyArea: 'lower_back',
        difficulty: 'hard',
        duration: 660,
        videoId: 'jaji1zuVAQU',
        targetPainTypes: ['chronic_pain', 'muscle_tension', 'stiffness'],
        steps: [
          'Nordic hamstring curl: kneel on soft surface, lower torso forward (3 × 6 reps).',
          'Single-leg deadlift: hinge on one leg, touch weight to floor (3 × 8 each).',
          'Loaded carries: farmer\'s carry with dumbbells for 20 metres (4 trips).',
          'Cable pull-through: stand facing away from cable, hinge and pull (3 × 15).',
          'Always use a weight belt for loaded exercises if advised by your physio.',
        ],
      ),
      ex(
        title: 'Lower Back Strength Builder',
        description:
            'A physio-guided lower back strengthening program for those who have cleared acute pain and are ready for progressive loading.',
        bodyArea: 'lower_back',
        difficulty: 'hard',
        duration: 780,
        videoId: 'bfgI4B20IZ0',
        targetPainTypes: ['weakness', 'chronic_pain'],
        steps: [
          'Barbell squat: back squat with controlled descent, drive through heels (4 × 8).',
          'Trap bar deadlift: neutral spine, full hip extension at top (4 × 6 reps).',
          'Cable row: seated row with back upright, squeeze scapulae (3 × 12).',
          'Ab wheel rollout: kneeling ab wheel rollout, return with core tight (3 × 8).',
          'Deload every 4th week. Progress weight by 2.5 kg per week maximum.',
        ],
      ),

      // ─────────────────────────── KNEE ───────────────────────────

      // Knee – Easy
      ex(
        title: 'Knee Pain Relief for Beginners',
        description:
            'Seven beginner-friendly knee exercises from Dr. Jo (Physical Therapist) to relieve knee pain and improve joint function safely.',
        bodyArea: 'knee',
        difficulty: 'easy',
        duration: 420,
        videoId: 'CHgIV32iwMo',
        targetPainTypes: ['osteoarthritis', 'post_surgery', 'patellofemoral'],
        steps: [
          'Ankle pumps: lying on back, pump ankles up and down to stimulate circulation (20 reps).',
          'Quad sets: tighten quadriceps by pressing knee down, hold 5 sec × 15 reps.',
          'Short arc quads: place rolled towel under knee, straighten leg fully (3 × 15).',
          'Heel slides: slide heel toward buttocks and back while lying down (15 reps each).',
          'Perform once daily. Do not push through sharp pain — mild aching is acceptable.',
        ],
      ),
      ex(
        title: 'Knee Physical Therapy Basics',
        description:
            'Physical therapy knee exercises and stretches to relieve muscle tightness and reduce pain — suitable for most knee conditions.',
        bodyArea: 'knee',
        difficulty: 'easy',
        duration: 360,
        videoId: '-u4HH8q3tyA',
        targetPainTypes: ['stiffness', 'osteoarthritis', 'muscle_tension'],
        steps: [
          'Calf stretch: lean against wall with back leg straight, hold 30 seconds each.',
          'Hamstring stretch: seated, extend one leg on chair, hinge forward slightly (30 sec each).',
          'Straight leg raise: lie on back, lift straight leg to 45°, hold 5 sec (10 reps each).',
          'Step-ups: step onto a low step and back down slowly (10 reps each leg).',
          'Perform 2 sets of each exercise, morning and evening.',
        ],
      ),
      ex(
        title: 'Basic Knee Rehabilitation',
        description:
            'Physical therapists walk through foundational knee rehabilitation exercises you can do at home after knee injury or surgery.',
        bodyArea: 'knee',
        difficulty: 'easy',
        duration: 480,
        videoId: 'A254DPhjHBw',
        targetPainTypes: ['post_surgery', 'osteoarthritis'],
        steps: [
          'Leg extension in chair: sit tall, slowly straighten knee, lower (3 × 15 reps).',
          'Seated knee flexion: use good leg to gently push injured leg into more bend (10 reps).',
          'Standing calf raises: hold chair for balance, rise onto toes and lower (3 × 15).',
          'Wall slide squat: slide back down wall to 45°, hold 10 seconds (10 reps).',
          'Ice the knee for 10–15 minutes after exercises if swelling or warmth is present.',
        ],
      ),

      // Knee – Medium
      ex(
        title: '11 Knee Rehab Exercises',
        description:
            'A comprehensive 11-exercise knee rehabilitation program covering all major muscle groups that support the knee joint.',
        bodyArea: 'knee',
        difficulty: 'medium',
        duration: 720,
        videoId: 'NJR2BcOk2BY',
        targetPainTypes: ['osteoarthritis', 'patellofemoral', 'ligament_sprain'],
        steps: [
          'Clam shells: side-lying with bands, open and close knees (3 × 15 each).',
          'Terminal knee extension: band behind knee, straighten fully against resistance (3 × 15).',
          'Step-down: step onto low box and slowly lower opposite foot to floor (3 × 10 each).',
          'Reverse lunge: step back slowly, lower back knee toward floor (3 × 10 each).',
          'Monster walks: resistance band around ankles, walk laterally 10 steps each direction.',
        ],
      ),
      ex(
        title: 'Everyday Knee Therapy',
        description:
            'Everyday physical therapy routine for knee pain from a licensed PT — practical exercises that fit into a busy daily schedule.',
        bodyArea: 'knee',
        difficulty: 'medium',
        duration: 540,
        videoId: '8UcPSritoL0',
        targetPainTypes: ['patellofemoral', 'muscle_tension', 'osteoarthritis'],
        steps: [
          'Hip flexor stretch with knee in extension: hold lunge position for 30 sec each.',
          'IT band foam roll: roll from hip to knee slowly (30 seconds each side).',
          'Single-leg balance: stand on one foot, progress to eyes closed (30 sec each).',
          'Mini squat to sit: squat to just barely touch chair and stand again (3 × 15).',
          'Pair this routine with icing and elevation after exercise for best recovery.',
        ],
      ),
      ex(
        title: '8 Knee Pain Relief Exercises',
        description:
            'Eight simple yet effective exercises for significant knee pain relief, targeting the muscles that protect the knee from stress.',
        bodyArea: 'knee',
        difficulty: 'medium',
        duration: 600,
        videoId: '_YO4VV6Jl6g',
        targetPainTypes: ['osteoarthritis', 'weakness', 'patellofemoral'],
        steps: [
          'Lateral band walks: resistance band just above ankles, walk sideways 15 steps each way.',
          'Single-leg press: use leg press machine with one leg, light weight (3 × 15).',
          'Hamstring curl with band: lie prone, curl heel toward glutes against band (3 × 15).',
          'Box step-up: step onto higher box (12–18 inches), drive knee up (3 × 10 each).',
          'Progress to next exercise only when current one is pain-free.',
        ],
      ),

      // Knee – Hard
      ex(
        title: 'Complete Knee Strengthening',
        description:
            'A comprehensive program targeting every major knee muscle group for full strength restoration and injury prevention.',
        bodyArea: 'knee',
        difficulty: 'hard',
        duration: 840,
        videoId: 'qiWPDDCgo3s',
        targetPainTypes: ['weakness', 'instability', 'post_surgery'],
        steps: [
          'Bulgarian split squat: rear foot elevated, lower back knee toward floor (4 × 8 each).',
          'Nordic curl: kneel, anchor feet, lower torso forward as far as possible (3 × 5).',
          'Plyometric jump squat: squat then jump explosively, land softly (3 × 10).',
          'Single-leg leg press: heavy load, full range of motion (4 × 10 each).',
          'Finish with 10 minutes of stretching — focus on quads, hamstrings, and calves.',
        ],
      ),
      ex(
        title: '11 Exercises for Stronger Knees',
        description:
            'A doctor and physiotherapist demonstrate 11 exercises for powerful knees — from functional movements to loaded strengthening.',
        bodyArea: 'knee',
        difficulty: 'hard',
        duration: 780,
        videoId: '74M1nBk1r0U',
        targetPainTypes: ['weakness', 'osteoarthritis', 'patellofemoral'],
        steps: [
          'Rear foot elevated split squat: 4 × 10 reps each leg with dumbbells.',
          'Stiff-leg deadlift: hinge with minimal knee bend to target hamstrings (4 × 10).',
          'Lateral step-up: step laterally onto a high box (3 × 10 each side).',
          'Isometric wall sit: hold 45–60 seconds (3 rounds).',
          'Depth drop landing: step off low box and absorb landing softly (3 × 8 each).',
        ],
      ),
      ex(
        title: 'Knee Pain — 5 Must-Do Exercises',
        description:
            'Five critical exercises that address the root causes of knee pain through targeted strengthening and neuromuscular training.',
        bodyArea: 'knee',
        difficulty: 'hard',
        duration: 660,
        videoId: 'rJgJT4AMo3k',
        targetPainTypes: ['patellofemoral', 'ligament_sprain', 'instability'],
        steps: [
          'Hip abductor strengthening: side-lying leg raise with ankle weight (3 × 20 each).',
          'Eccentric step-down: slowly lower off a step over 5 seconds (3 × 8 each leg).',
          'Terminal knee extension with band: walk out from anchor, perform 20 reps each leg.',
          'Bosu ball squat: squat on unstable surface for proprioception (3 × 12).',
          'Use a knee brace if advised by your physio during higher-load exercises.',
        ],
      ),

      // ─────────────────────────── HIP ───────────────────────────

      // Hip – Easy
      ex(
        title: 'Hip Exercises for Beginners',
        description:
            'Easy hip strengthening exercises designed for seniors and beginners — improve balance, coordination, and hip stability safely.',
        bodyArea: 'hip',
        difficulty: 'easy',
        duration: 480,
        videoId: '1jE_b5FDrZ0',
        targetPainTypes: ['hip_tightness', 'weakness', 'bursitis'],
        steps: [
          'Seated hip march: sitting tall, alternate lifting knees (20 reps each leg).',
          'Standing hip abduction: hold chair, raise leg to side and lower slowly (15 reps each).',
          'Hip circles: hands on hips, circle hips slowly (10 each direction).',
          'Glute bridge: feet flat, lift hips and hold 5 seconds (12 reps).',
          'Perform slowly and controlled. Rest 30 seconds between exercises.',
        ],
      ),
      ex(
        title: '10 Best Hip Strengthening Exercises',
        description:
            'Ask Doctor Jo\'s 10 best hip exercises for pain relief — progressing from lying down to sitting to standing movements.',
        bodyArea: 'hip',
        difficulty: 'easy',
        duration: 540,
        videoId: 's7WBpar9W6w',
        targetPainTypes: ['bursitis', 'hip_tightness', 'osteoarthritis'],
        steps: [
          'Clamshell: side-lying with band, open and close knees (3 × 15 each side).',
          'Prone hip extension: lie face down, lift one straight leg (3 × 15 each).',
          'Seated hip internal rotation: sit in chair, rotate leg inward against hand (10 reps each).',
          'Standing hip flexion: lift knee to 90° and hold 2 seconds (3 × 15 each).',
          'Hip hinge: stand, hinge forward with flat back, return upright (3 × 15 reps).',
        ],
      ),
      ex(
        title: 'Beginner Hip Mobility & Strength',
        description:
            'Eight simple exercises progressing from beginner to intermediate — ideal for those with weak hips or recovering from hip pain.',
        bodyArea: 'hip',
        difficulty: 'easy',
        duration: 480,
        videoId: 'TH7XujK_ubs',
        targetPainTypes: ['weakness', 'hip_tightness'],
        steps: [
          'Lying hip flexor stretch: pull knee to chest gently, hold 20 seconds each side.',
          'Supine glute bridge: slow, controlled, hold 3 seconds at top (15 reps).',
          'Side-lying abduction: raise top leg 30–40°, hold 2 sec (15 reps each side).',
          'Standing kickback: hold chair, extend leg behind with straight knee (15 each).',
          'Perform twice daily. Focus on feeling the target muscles contract.',
        ],
      ),

      // Hip – Medium
      ex(
        title: 'Hip Flexor Injury Rehab',
        description:
            'The right strengthening exercises for hip flexor injuries — a physio-led routine that targets hip flexor recovery without aggravating the injury.',
        bodyArea: 'hip',
        difficulty: 'medium',
        duration: 600,
        videoId: '3UiW5iPCEpA',
        targetPainTypes: ['hip_flexor_strain', 'hip_tightness'],
        steps: [
          'Isometric hip flexion: push knee up into your hand while standing (10 sec × 10).',
          'Resistance band hip flexion: attach band to ankle, march forward against resistance (15 each).',
          'Kneeling lunge stretch: hold 30 seconds each side to restore hip flexor length.',
          'Eccentric hip flexion: slowly lower leg from raised position over 5 seconds (10 each).',
          'Progress resistance band tension each week as strength improves.',
        ],
      ),
      ex(
        title: 'Hip Strengthening Routine',
        description:
            'The best hip strengthening routine for weak hips — targeting glutes, hip abductors, and hip flexors for full hip stability.',
        bodyArea: 'hip',
        difficulty: 'medium',
        duration: 660,
        videoId: 'jtpRBvLZw-Y',
        targetPainTypes: ['weakness', 'bursitis', 'hip_tightness'],
        steps: [
          'Sumo squat: wide stance, toes out 45°, squat to parallel (3 × 15).',
          'Lateral band squat walk: band above knees, walk sideways 15 steps each way.',
          'Single-leg glute bridge: one leg raised, drive through heel (3 × 12 each).',
          'Fire hydrant: on all fours, raise knee to side like a dog at fire hydrant (3 × 15).',
          'Curtsy lunge: cross foot behind and diagonally, lower into lunge (3 × 10 each).',
        ],
      ),
      ex(
        title: 'Complete Hip Muscle Routine',
        description:
            'Strengthen every hip muscle group with this simple but effective routine — ideal for adults 50+ and those in mid-stage rehab.',
        bodyArea: 'hip',
        difficulty: 'medium',
        duration: 600,
        videoId: 'zI5P8fU0NUk',
        targetPainTypes: ['weakness', 'osteoarthritis', 'bursitis'],
        steps: [
          'Hip thrust off bench: shoulders on bench, feet flat, drive hips up (3 × 12).',
          'Resistance band clamshell: medium resistance, 20 reps each side.',
          'Cable hip extension: attach cable to ankle, extend leg behind (3 × 15 each).',
          'Side plank with hip abduction: in side plank, raise top leg (3 × 10 each).',
          'Cool down: pigeon pose and figure-four stretch, 30 seconds each side.',
        ],
      ),

      // Hip – Hard
      ex(
        title: 'Advanced Hip Exercises',
        description:
            'Advanced exercises following hip replacement or major hip injury — performed under physiotherapist supervision at 8–12 weeks post-surgery.',
        bodyArea: 'hip',
        difficulty: 'hard',
        duration: 720,
        videoId: 'TQS_IqMvcpA',
        targetPainTypes: ['post_surgery', 'weakness'],
        steps: [
          'Standing hip abduction with weight: add ankle weights, raise leg to side (3 × 15).',
          'Step-up with knee drive: step onto 18" box, drive opposite knee up (3 × 10 each).',
          'Resisted hip extension: cable machine, extend leg behind against resistance (3 × 15).',
          'Single-leg squat to chair: lower slowly to chair on one leg (3 × 8 each).',
          'Never allow the operated hip to adduct past midline during any exercise.',
        ],
      ),
      ex(
        title: 'Hip Strength & Stability',
        description:
            'Fix weak hips fast with four targeted exercises for strength and stability — eliminating hip pain at its source.',
        bodyArea: 'hip',
        difficulty: 'hard',
        duration: 660,
        videoId: '12NGWxpDlr8',
        targetPainTypes: ['weakness', 'instability', 'bursitis'],
        steps: [
          'Copenhagen plank: side plank with top foot on bench, hold 20–30 sec each (3 sets).',
          'Single-leg Romanian deadlift with dumbbell: 4 × 8 each leg.',
          'Plyometric lateral bounds: jump side to side landing on one foot (3 × 8 each).',
          'Hip airplane: standing on one leg, rotate torso while keeping hip level (3 × 10 each).',
          'Focus on hip and knee alignment throughout — no inward knee collapse.',
        ],
      ),
      ex(
        title: 'Hip Pain-Free Strengthening',
        description:
            'Five hip-strengthening exercises for staying pain-free as you age — evidence-based movements for long-term hip health.',
        bodyArea: 'hip',
        difficulty: 'hard',
        duration: 600,
        videoId: 'thA83oOmgsM',
        targetPainTypes: ['osteoarthritis', 'weakness', 'bursitis'],
        steps: [
          'Heavy glute bridge: barbell across hips, drive through heels (4 × 10 reps).',
          'Deficit reverse lunge: step back onto lower surface for greater range (4 × 8 each).',
          'Lateral sled push: push sled sideways to load hip abductors (4 × 15 m each way).',
          'Single-leg cable hip flexion: heavy cable, controlled flexion to 90° (3 × 12 each).',
          'Programme for 3 days per week with 48 hours rest between sessions.',
        ],
      ),

      // ─────────────────────────── NECK ───────────────────────────

      // Neck – Easy
      ex(
        title: 'Neck Stretches & Exercises',
        description:
            'Ask Doctor Jo\'s gentle neck stretches and exercises to relieve pain and stiffness — simple enough for daily use.',
        bodyArea: 'neck',
        difficulty: 'easy',
        duration: 360,
        videoId: '2NOsE-VPpkE',
        targetPainTypes: ['cervical_pain', 'stiffness', 'headache'],
        steps: [
          'Chin tuck: slide head back to make a double chin, hold 3 sec × 10 reps.',
          'Neck side bend: tilt ear toward shoulder gently, hold 20 seconds each side.',
          'Neck rotation: slowly turn head to look over each shoulder, hold 20 sec each.',
          'Upper trap stretch: tilt head, add gentle hand pressure, hold 30 sec each side.',
          'Perform slowly — never force the range. Stop if dizziness occurs.',
        ],
      ),
      ex(
        title: 'Neck Physical Therapy Basics',
        description:
            'Physical therapy stretches and exercises for neck pain relief — suitable for anyone with mild to moderate neck stiffness or discomfort.',
        bodyArea: 'neck',
        difficulty: 'easy',
        duration: 420,
        videoId: 'I0mae0RDang',
        targetPainTypes: ['cervical_pain', 'muscle_tension', 'headache'],
        steps: [
          'Neck flexion stretch: gently nod chin to chest, hold 15 seconds (5 reps).',
          'Neck extension: slowly tilt head back, hold 10 seconds (5 reps).',
          'Levator scapulae stretch: turn head 45°, tilt down toward armpit, hold 30 sec each.',
          'Cervical retraction: stand against wall, tuck chin and press head to wall (10 reps).',
          'Perform twice daily, especially in the morning and after prolonged sitting.',
        ],
      ),
      ex(
        title: 'Beginner Neck Strengthening',
        description:
            'Physio-designed neck strengthening exercises for beginners — targets deep neck flexors and postural muscles to reduce chronic neck pain.',
        bodyArea: 'neck',
        difficulty: 'easy',
        duration: 480,
        videoId: 'T7sBeFEu4pw',
        targetPainTypes: ['cervical_pain', 'weakness', 'posture'],
        steps: [
          'Isometric neck flexion: press forehead into hand while resisting movement (10 sec × 10).',
          'Isometric side bend: press ear toward hand while resisting (10 sec × 10 each).',
          'Isometric extension: press back of head into hands while resisting (10 sec × 10).',
          'Neck retraction with band: loop band around head, retract chin against light resistance.',
          'Progress to medium resistance once these feel easy (2–3 weeks).',
        ],
      ),

      // Neck – Medium
      ex(
        title: '10 Best Neck Exercises',
        description:
            'Ask Doctor Jo\'s 10 most effective neck exercises for pain relief — a mix of stretching, strengthening, and range-of-motion work.',
        bodyArea: 'neck',
        difficulty: 'medium',
        duration: 600,
        videoId: 'NXC60wUYiPI',
        targetPainTypes: ['cervical_pain', 'stiffness', 'headache'],
        steps: [
          'Deep neck flexor activation: nodding slowly with precision (3 × 10, hold 5 sec).',
          'Prone neck extension: lying face down, lift head slightly (3 × 10, hold 3 sec).',
          'Shoulder blade squeeze: retract and depress scapulae, hold 5 sec (3 × 15).',
          'Band resisted rotation: light band, rotate head against resistance (3 × 12 each).',
          'Neck endurance holds: hold chin tuck position for 30–60 seconds (3 rounds).',
        ],
      ),
      ex(
        title: 'Neck Mobility Rehabilitation',
        description:
            'Three targeted rehab exercises to test and improve neck mobility — especially useful after whiplash or prolonged stiffness.',
        bodyArea: 'neck',
        difficulty: 'medium',
        duration: 420,
        videoId: 'SSAYXJH0cyE',
        targetPainTypes: ['stiffness', 'whiplash', 'cervical_pain'],
        steps: [
          'Gaze stabilization: fix eyes on a target, move head side to side while maintaining focus.',
          'Cervical SNAG: apply gentle overpressure to neck during rotation (10 reps each side).',
          'Neck rotation active range of motion: slow, full rotation 10 reps each direction.',
          'Proprioception training: place dot on wall at eye level, point nose at dot from memory.',
          'Perform 2 times per day. Expect 4–6 weeks of consistent practice for improvement.',
        ],
      ),
      ex(
        title: 'Neck Stretches — Real Time Routine',
        description:
            'A real-time guided neck stretch and exercise routine that you can follow along with in real time — great for desk workers.',
        bodyArea: 'neck',
        difficulty: 'medium',
        duration: 540,
        videoId: 'u3Ocw5UIpYs',
        targetPainTypes: ['muscle_tension', 'cervical_pain', 'headache'],
        steps: [
          'Scalene stretch: tilt head and look slightly up at 45°, hold 30 sec each side.',
          'Sternocleidomastoid stretch: rotate head and tilt slightly back, hold 30 sec each.',
          'Pec minor stretch: doorway stretch with arms high, open chest for 30 seconds.',
          'Thoracic extension on foam roller: upper back on roller, gently extend over it.',
          'Neck retraction series: 3 × 15 reps at increasing speed while maintaining form.',
        ],
      ),

      // Neck – Hard
      ex(
        title: 'Neck Strengthening: Easy to Hard',
        description:
            'A progressive neck strengthening sequence from Bob & Brad — covers easy, intermediate, and challenging exercises in one session.',
        bodyArea: 'neck',
        difficulty: 'hard',
        duration: 720,
        videoId: 'Jz-UKE6_GAI',
        targetPainTypes: ['whiplash', 'weakness', 'cervical_pain'],
        steps: [
          'Head lift supine: lie on back, lift head 1 inch, hold 10 sec × 10 reps.',
          'Head lift prone: lie face down, lift head while chin is tucked, hold 10 sec × 10.',
          'Weighted neck flexion: use a head harness with light weight, 3 × 12 reps.',
          'Resistance band neck extension: band behind head, extend against resistance (3 × 15).',
          'Cervical plank: hold rigid neck position during a full plank for 30–60 seconds.',
        ],
      ),
      ex(
        title: '7 Ways to Relieve Neck Pain',
        description:
            'Seven comprehensive approaches to neck pain relief combining manual techniques, exercises, and postural correction strategies.',
        bodyArea: 'neck',
        difficulty: 'hard',
        duration: 600,
        videoId: '2K19FoWW3ls',
        targetPainTypes: ['cervical_pain', 'stiffness', 'radiculopathy'],
        steps: [
          'Thoracic spine rotation: sit cross-legged, rotate torso fully each direction (10 each).',
          'Wall angel: back to wall, slide arms up and down in snow-angel motion (3 × 10).',
          'Deep neck flexor endurance: 3-minute sustained chin-tuck hold with breaks.',
          'Sidelying neck lateral flexion against gravity: 3 × 10 reps each side.',
          'Postural taping: ask a physio about therapeutic taping to support posture between sessions.',
        ],
      ),
      ex(
        title: '20-Minute Neck Pain Relief Routine',
        description:
            'A complete 20-minute guided routine combining stretches and exercises for thorough neck pain relief and long-term neck health.',
        bodyArea: 'neck',
        difficulty: 'hard',
        duration: 1200,
        videoId: 'sr3hW43i9tg',
        targetPainTypes: ['chronic_pain', 'stiffness', 'muscle_tension'],
        steps: [
          'Warm-up (3 min): gentle rotations, side bends, and nodding movements.',
          'Stretching phase (7 min): all major neck and upper trap stretches 30 sec each.',
          'Strengthening phase (7 min): isometrics, band exercises, and endurance holds.',
          'Cool-down (3 min): slow range-of-motion movements and diaphragmatic breathing.',
          'Aim for 3 sessions per week. Pair with ergonomic workstation adjustments.',
        ],
      ),

      // ─────────────────────────── ANKLE ───────────────────────────

      // Ankle – Easy
      ex(
        title: 'Ankle Rehabilitation: Phase 1',
        description:
            'CHOP Sports Medicine Phase 1 ankle rehabilitation — foundational range-of-motion exercises for the early stage of ankle recovery.',
        bodyArea: 'ankle',
        difficulty: 'easy',
        duration: 360,
        videoId: '2d-mVqEwgbo',
        targetPainTypes: ['sprain', 'stiffness', 'post_surgery'],
        steps: [
          'Ankle pumps: point and flex the foot 20 times to stimulate circulation.',
          'Ankle circles: 10 clockwise and 10 counterclockwise circles each foot.',
          'Ankle alphabet: trace each letter A–Z using the foot, once per foot.',
          'Towel curl: place towel flat on floor, scrunch with toes (3 × 15 reps).',
          'Perform 3–4 times daily for the first 1–2 weeks after injury.',
        ],
      ),
      ex(
        title: 'Sprained Ankle Rehab Program',
        description:
            'A complete sprained ankle rehabilitation program guided by a medical doctor and physiotherapist — from acute phase to walking normally.',
        bodyArea: 'ankle',
        difficulty: 'easy',
        duration: 480,
        videoId: 't0L7Aw1zLB0',
        targetPainTypes: ['sprain', 'instability', 'stiffness'],
        steps: [
          'RICE first 48 hours: rest, ice (20 min on/off), compression bandage, elevate foot.',
          'Range of motion: alphabets and circles pain-free, 3× daily.',
          'Seated calf raises: both feet on floor, rise onto toes slowly (3 × 15).',
          'Standing heel raises: hold chair for balance, rise and lower over 3 seconds each.',
          'Progress only when swelling has reduced and each step is pain-free.',
        ],
      ),
      ex(
        title: 'Ankle Mobility & Range of Motion',
        description:
            'Guided ankle mobility exercises to restore full range of motion after injury, stiffness, or reduced activity — suitable for all ages.',
        bodyArea: 'ankle',
        difficulty: 'easy',
        duration: 300,
        videoId: '',
        targetPainTypes: ['stiffness', 'sprain', 'post_surgery'],
        steps: [
          'Seated ankle dorsiflexion: pull toes toward shin and hold 5 seconds (15 reps).',
          'Seated ankle plantarflexion: point toes away firmly and hold 5 sec (15 reps).',
          'Inversion and eversion: roll foot inward then outward slowly (15 reps each).',
          'Towel gastrocnemius stretch: sit with leg straight, loop towel on foot, pull toes back.',
          'Hold each stretch 20–30 seconds. Perform morning and evening.',
        ],
      ),

      // Ankle – Medium
      ex(
        title: 'Ankle Strengthening Exercises',
        description:
            'Progressive ankle strengthening exercises to rebuild stability and strength after a sprain or for chronic ankle instability.',
        bodyArea: 'ankle',
        difficulty: 'medium',
        duration: 540,
        videoId: '',
        targetPainTypes: ['instability', 'weakness', 'chronic_sprain'],
        steps: [
          'Resistance band dorsiflexion: loop band around foot, pull toes up against resistance (3 × 15).',
          'Band eversion: loop band around foot, turn foot outward against resistance (3 × 15 each).',
          'Single-leg heel raise: stand on one foot, rise onto toes slowly (3 × 12 reps each).',
          'Single-leg balance: stand on injured foot, progress to eyes closed (30 sec × 3 each).',
          'Gradually increase time and reduce the surface stability over 4–6 weeks.',
        ],
      ),
      ex(
        title: 'Ankle Proprioception Training',
        description:
            'Balance and proprioception exercises to retrain the ankle\'s position sense after injury — critical for preventing re-injury.',
        bodyArea: 'ankle',
        difficulty: 'medium',
        duration: 480,
        videoId: '',
        targetPainTypes: ['instability', 'chronic_sprain', 'sprain'],
        steps: [
          'Single-leg stance on foam: stand on foam pad for 30 seconds each foot.',
          'Star excursion balance: stand on one foot, reach the other in 8 directions.',
          'Wobble board circles: stand on board, make circles with the board (60 sec each).',
          'Y-balance test exercise: reach anterior, posterolateral, and posteromedial (10 each).',
          'Progress to performing these with eyes closed as balance improves.',
        ],
      ),
      ex(
        title: 'Calf & Ankle Strengthening',
        description:
            'Targeted calf and ankle strengthening routine using progressive overload to restore full function after ankle injuries.',
        bodyArea: 'ankle',
        difficulty: 'medium',
        duration: 600,
        videoId: '',
        targetPainTypes: ['weakness', 'achilles_tendinopathy', 'instability'],
        steps: [
          'Eccentric heel drop: rise on both feet, lower on one foot over 3 seconds (3 × 15).',
          'Seated calf raise with weight: place weight on thigh, rise onto toes (3 × 20).',
          'Ankle hop progression: two-foot hops in place, progress to one-foot (3 × 20).',
          'Lateral step with band: resistance band around ankles, step sideways (3 × 15 each).',
          'Add 2.5 kg resistance weekly once each level is pain-free and controlled.',
        ],
      ),

      // Ankle – Hard
      ex(
        title: 'Advanced Ankle Stability',
        description:
            'Advanced ankle stability and power exercises for returning to sport or high-demand activity after ankle recovery.',
        bodyArea: 'ankle',
        difficulty: 'hard',
        duration: 720,
        videoId: '',
        targetPainTypes: ['instability', 'weakness', 'post_surgery'],
        steps: [
          'Single-leg hop for distance: hop as far as possible on one foot, stick landing (3 × 8).',
          'Lateral bound: jump side to side off one foot, absorb landing (3 × 10 each).',
          'Box jump with single-leg landing: jump onto box, land on one foot softly (3 × 6).',
          'Agility ladder drills: high-knees through ladder for 30 seconds (5 rounds).',
          'Only progress to plyometrics when single-leg calf raise is pain-free for 20+ reps.',
        ],
      ),
      ex(
        title: 'Ankle Return-to-Sport Exercises',
        description:
            'Sport-specific ankle exercises for the final phase of rehabilitation — designed for athletes returning after ankle sprain or surgery.',
        bodyArea: 'ankle',
        difficulty: 'hard',
        duration: 780,
        videoId: '',
        targetPainTypes: ['post_surgery', 'instability', 'chronic_sprain'],
        steps: [
          'Reactive hop landing: drop off box and immediately hop forward (3 × 8 each).',
          'Sprint deceleration: accelerate 10 m then decelerate over 5 m, cut left or right.',
          'Change-of-direction drills: cone agility patterns with sharp cuts (5 × 30 sec).',
          'Plyometric ankle stiffness drill: rapid hopping on the spot, minimal knee bend.',
          'Clear with your physiotherapist before beginning sport-specific loading.',
        ],
      ),
      ex(
        title: 'Ankle Power & Plyometrics',
        description:
            'Plyometric and power exercises for the ankle to develop elastic strength and explosive performance in the final rehab phase.',
        bodyArea: 'ankle',
        difficulty: 'hard',
        duration: 660,
        videoId: '',
        targetPainTypes: ['weakness', 'instability'],
        steps: [
          'Pogo jumps: bounce off both feet using only ankle flexion/extension (3 × 20 reps).',
          'Drop jump: step off 30 cm box, immediately jump as high as possible (3 × 8).',
          'Single-leg pogo: bounce off one foot, 3 × 15 reps each side.',
          'Depth jump to broad jump: combine vertical drop with horizontal projection (3 × 6).',
          'Monitor for pain or swelling after sessions. Reduce intensity if either occurs.',
        ],
      ),
    ];
  }
}
