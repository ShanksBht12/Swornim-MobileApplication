const multer = require("multer");
const path = require("path");
const fs = require("fs");

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(process.cwd(), "uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Configure multer storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let uploadPath = "uploads/";

    // Create different folders based on file type or route
    if (file.fieldname === "profileImage") {
      uploadPath += "profiles/";
    } else if (file.fieldname === "portfolioImage" || file.fieldname === "portfolioImages") {
      uploadPath += "portfolios/";
    } else if (file.fieldname === "venueImages") {
      uploadPath += "venues/";
    } else {
      uploadPath += "others/";
    }

    // Create directory if it doesn't exist
    const fullPath = path.join(process.cwd(), uploadPath);
    if (!fs.existsSync(fullPath)) {
      fs.mkdirSync(fullPath, { recursive: true });
    }

    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    // Generate unique filename
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    const name = file.fieldname + "-" + uniqueSuffix + ext;
    cb(null, name);
  },
});

// File filter for images
const imageFilter = (req, file, cb) => {
  console.log('DEBUG: File filter check:', {
    fieldname: file.fieldname,
    originalname: file.originalname,
    mimetype: file.mimetype,
    size: file.size
  });
  
  // Check if it's an image by MIME type
  if (file.mimetype.startsWith("image/")) {
    console.log('DEBUG: File accepted - valid image type');
    cb(null, true);
  } else {
    // Fallback: check file extension for common image formats
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    const fileExtension = path.extname(file.originalname).toLowerCase();
    
    if (allowedExtensions.includes(fileExtension)) {
      console.log('DEBUG: File accepted - valid image extension:', fileExtension);
      cb(null, true);
    } else {
      console.log('DEBUG: File rejected - invalid type:', file.mimetype, 'and extension:', fileExtension);
      cb(new Error("Only image files are allowed"), false);
    }
  }
};

// File filter for documents
const documentFilter = (req, file, cb) => {
  const allowedTypes = [
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "image/jpeg",
    "image/jpg",
    "image/png",
  ];

  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error("Only PDF, DOC, DOCX, and image files are allowed"), false);
  }
};

// Configure multer
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
    files: 10, // Maximum 10 files
  },
  fileFilter: imageFilter,
});

// Configure multer for documents
const uploadDocument = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit for documents
    files: 5,
  },
  fileFilter: documentFilter,
});

// Error handler for multer
const handleMulterError = (error, req, res, next) => {
  console.log('DEBUG: Multer error handler:', {
    errorType: error.constructor.name,
    errorMessage: error.message,
    errorCode: error.code,
    reqMethod: req.method,
    reqUrl: req.originalUrl,
    hasFile: !!req.file,
    fileInfo: req.file ? {
      fieldname: req.file.fieldname,
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size
    } : null
  });

  if (error instanceof multer.MulterError) {
    let message = "File upload error";

    switch (error.code) {
      case "LIMIT_FILE_SIZE":
        message =
          "File size too large. Maximum size is 5MB for images and 10MB for documents.";
        break;
      case "LIMIT_FILE_COUNT":
        message = "Too many files. Maximum allowed is 10 files.";
        break;
      case "LIMIT_UNEXPECTED_FILE":
        message = "Unexpected file field.";
        break;
      default:
        message = error.message;
    }

    return res.status(400).json({
      data: null,
      message: message,
      status: "FILE_UPLOAD_ERROR",
      options: null,
    });
  }

  if (error.message.includes("Only")) {
    return res.status(400).json({
      data: null,
      message: error.message,
      status: "INVALID_FILE_TYPE",
      options: null,
    });
  }

  next(error);
};

// Middleware to handle upload errors
const wrapUploadMiddleware = (uploadMiddleware) => {
  return (req, res, next) => {
    uploadMiddleware(req, res, (error) => {
      if (error) {
        return handleMulterError(error, req, res, next);
      }
      next();
    });
  };
};

// Export wrapped middleware
module.exports = {
  single: (fieldName) => wrapUploadMiddleware(upload.single(fieldName)),
  array: (fieldName, maxCount) =>
    wrapUploadMiddleware(upload.array(fieldName, maxCount)),
  fields: (fields) => wrapUploadMiddleware(upload.fields(fields)),
  any: () => wrapUploadMiddleware(upload.any()),
  none: () => wrapUploadMiddleware(upload.none()),

  // Document uploads
  singleDocument: (fieldName) =>
    wrapUploadMiddleware(uploadDocument.single(fieldName)),
  arrayDocument: (fieldName, maxCount) =>
    wrapUploadMiddleware(uploadDocument.array(fieldName, maxCount)),
  fieldsDocument: (fields) =>
    wrapUploadMiddleware(uploadDocument.fields(fields)),
};
