#!/usr/bin/env bash
# Uploads free exercise videos to Cloudinary and prints the resulting delivery URLs.

CLOUD_NAME="dgq7kbqjg"
API_KEY="655111537828448"
API_SECRET="Fw6NiHOq4aKqvDo2Sp_167LDkNs"
BASE_URL="https://res.cloudinary.com/${CLOUD_NAME}/video/upload/f_mp4,q_auto"

upload_video() {
  local source_url="$1"
  local public_id="$2"
  local timestamp
  timestamp=$(date +%s)
  local to_sign="public_id=${public_id}&timestamp=${timestamp}${API_SECRET}"
  local signature
  signature=$(printf '%s' "$to_sign" | sha1sum | cut -d' ' -f1)

  echo -n "  Uploading ${public_id}... "
  local response
  response=$(curl -s -m 120 -X POST \
    "https://api.cloudinary.com/v1_1/${CLOUD_NAME}/video/upload" \
    -F "file=${source_url}" \
    -F "public_id=${public_id}" \
    -F "api_key=${API_KEY}" \
    -F "timestamp=${timestamp}" \
    -F "signature=${signature}")

  local secure_url
  secure_url=$(printf '%s' "$response" | grep -oP '"secure_url":"\K[^"]+' | head -1)
  if [ -n "$secure_url" ]; then
    echo "OK"
    echo "    delivery: ${BASE_URL}/${public_id}"
  else
    local err
    err=$(printf '%s' "$response" | grep -oP '"message":"\K[^"]+' | head -1)
    echo "FAILED: ${err}"
    echo "    raw: $response" | head -c 300
    echo ""
  fi
}

echo "=== Cloudinary Exercise Video Upload ==="

# Shoulder
upload_video "https://upload.wikimedia.org/wikipedia/commons/3/31/EJERCICIO_DE_CODMAN.ogv" \
  "physio/shoulder_easy"

upload_video "https://upload.wikimedia.org/wikipedia/commons/f/f5/Escalera_de_dedos.ogv" \
  "physio/shoulder_medium"

upload_video "https://upload.wikimedia.org/wikipedia/commons/3/3c/Serratus_punch.webm" \
  "physio/shoulder_hard"

# Lower Back (kettlebell swing — hip hinge, core lower back movement)
upload_video "https://upload.wikimedia.org/wikipedia/commons/5/53/Kettlebell_Swing_Hip_Hinge_Style.webm" \
  "physio/lower_back"

# Knee
upload_video "https://upload.wikimedia.org/wikipedia/commons/8/8e/Knee_Push_Sweep.webm" \
  "physio/knee_easy"

upload_video "https://upload.wikimedia.org/wikipedia/commons/5/57/Strength_Training_Circuit-_Forward_Lunge.webm" \
  "physio/knee_medium"

upload_video "https://upload.wikimedia.org/wikipedia/commons/1/1e/Squat_-_exercise_demonstration_video.webm" \
  "physio/knee_hard"

# Hip hard (deadlift — fundamental hip hinge pattern)
upload_video "https://upload.wikimedia.org/wikipedia/commons/6/62/Deadlift_-_exercise_demonstration_video.webm" \
  "physio/hip_hard"

# Neck
upload_video "https://upload.wikimedia.org/wikipedia/commons/0/0a/A-novel-method-for-neck-coordination-exercise-%E2%80%93-a-pilot-study-on-persons-with-chronic-non-specific-1743-0003-5-36-S1.ogv" \
  "physio/neck"

# Ankle
upload_video "https://upload.wikimedia.org/wikipedia/commons/7/72/The-effect-of-directional-inertias-added-to-pelvis-and-ankle-on-gait-1743-0003-10-40-S1.ogv" \
  "physio/ankle"

echo ""
echo "=== Done ==="
echo ""
echo "Delivery URL base: ${BASE_URL}"
echo "Videos:"
echo "  shoulder_easy   -> ${BASE_URL}/physio/shoulder_easy"
echo "  shoulder_medium -> ${BASE_URL}/physio/shoulder_medium"
echo "  shoulder_hard   -> ${BASE_URL}/physio/shoulder_hard"
echo "  lower_back      -> ${BASE_URL}/physio/lower_back"
echo "  knee_easy       -> ${BASE_URL}/physio/knee_easy"
echo "  knee_medium     -> ${BASE_URL}/physio/knee_medium  (also used for hip_easy, hip_medium)"
echo "  knee_hard       -> ${BASE_URL}/physio/knee_hard"
echo "  hip_hard        -> ${BASE_URL}/physio/hip_hard"
echo "  neck            -> ${BASE_URL}/physio/neck"
echo "  ankle           -> ${BASE_URL}/physio/ankle"
