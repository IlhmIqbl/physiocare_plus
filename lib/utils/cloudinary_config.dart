class CloudinaryConfig {
  CloudinaryConfig._();

  static const cloudName = 'dgq7kbqjg';

  // Unsigned upload preset — create this once in your Cloudinary dashboard:
  // Settings → Upload → Upload presets → Add upload preset
  // Set name = "physiocare_upload", Signing Mode = "Unsigned", then Save.
  static const uploadPreset = 'physiocare_upload';

  // Folder inside your Cloudinary account where exercise videos are stored
  static const folder = 'exercise_videos';

  // Build a delivery URL for a given public_id
  static String videoUrl(String publicId) =>
      'https://res.cloudinary.com/$cloudName/video/upload/$publicId';
}
