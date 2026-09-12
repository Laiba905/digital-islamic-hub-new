import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static final cloudinary = CloudinaryPublic(
      'lxuuhill',
      'AppPresent',
      cache: false
  );

  // Yeh method missing tha, ab add kar diya hai taake image upload ho sakay
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      print("Cloudinary Error: $e");
      return null;
    }
  }
}