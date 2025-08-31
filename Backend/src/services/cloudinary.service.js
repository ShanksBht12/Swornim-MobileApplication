const { CloudinaryConfig } = require("../config/config");
const cloudinary = require("cloudinary").v2;
const { deleteFile } = require("../utilities/helpers");

class CloudinaryService {
  constructor() {
    cloudinary.config({
      cloud_name: CloudinaryConfig.cloudName,
      api_key: CloudinaryConfig.apiKey,
      api_secret: CloudinaryConfig.apiSecret,
    });
  }

  fileUpload = async (path, dir = "") => {
    try {
      const { public_id, secure_url } = await cloudinary.uploader.upload(path, {
        folder: "/swornim/" + dir,
        unique_filename: true,
      });

      const optimizedUrl = cloudinary.url(public_id, {
        transformation: [
          { dpr: "auto", responsive: true, width: "auto", crop: "scale" },
          { quality: "auto" },
          { fetch_format: "auto" },
        ],
      });
      deleteFile(path);

      return {
        publicId: public_id,
        url: secure_url,
        optimizedUrl: optimizedUrl,
      };
    } catch (exception) {
      throw exception;
    }
  };

  deleteFile = async (publicId) => {
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      return result;
    } catch (exception) {
      throw exception;
    }
  };
}

const cloudinarySvc = new CloudinaryService();
module.exports = cloudinarySvc; 