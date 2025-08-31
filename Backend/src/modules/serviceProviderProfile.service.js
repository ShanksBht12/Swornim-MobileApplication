const cloudinarySvc = require("../services/cloudinary.service");

/**
 * Generic update function for service provider profiles.
 * @param {Object} options
 * @param {Sequelize.Model} options.model - The Sequelize model (e.g., Photographer, MakeupArtist)
 * @param {Object} options.profileFieldNames - { image: 'profileImage', publicId: 'profileImagePublicId' }
 * @param {string} options.cloudinaryDir - Cloudinary directory for uploads
 * @param {Function} options.getWithUser - Function to fetch profile with user info
 * @param {string} options.userId - The logged-in user's ID
 * @param {Object} options.updateData - The update data (req.body)
 * @param {Object} options.file - The uploaded file (req.file)
 * @returns {Promise<Object>} - The updated profile with user info
 */
// List of NOT NULL fields for all service provider types
const NOT_NULL_FIELDS = [
  'businessName',
  'hourlyRate',
  'packageStartingPrice',
  'sessionRate',
  'bridalPackageRate',
  'pricePerPerson',
  'capacity',
  'location', // location object itself should not be null
  // Add other required fields as needed
];

// Utility to recursively convert empty strings to null and remove nulls for NOT NULL fields
function cleanEmptyStringsAndRemoveNulls(obj) {
  if (!obj || typeof obj !== 'object') return obj;
  for (const key in obj) {
    if (typeof obj[key] === 'object' && obj[key] !== null) {
      cleanEmptyStringsAndRemoveNulls(obj[key]);
    } else if (obj[key] === '') {
      obj[key] = null;
    }
    // Remove nulls for NOT NULL fields
    if (obj[key] === null && NOT_NULL_FIELDS.includes(key)) {
      delete obj[key];
    }
  }
  return obj;
}

async function updateServiceProviderProfile({
  model,
  profileFieldNames,
  cloudinaryDir,
  getWithUser,
  userId,
  updateData,
  file,
}) {
  // Find the profile by userId
  const profile = await model.findOne({ where: { userId } });
  if (!profile) throw { code: 404, message: "Profile not found" };

  // Handle image upload if present
  if (file && file.path) {
    // Delete old image from Cloudinary if exists
    if (profile[profileFieldNames.publicId]) {
      await cloudinarySvc.deleteFile(profile[profileFieldNames.publicId]);
    }
    const uploadResult = await cloudinarySvc.fileUpload(file.path, cloudinaryDir);
    updateData[profileFieldNames.image] = uploadResult.url;
    updateData[profileFieldNames.publicId] = uploadResult.publicId;
  }

  // Prevent accidental update of id or userId
  delete updateData.id;
  delete updateData.userId;

  console.log('DEBUG: Before update - profile.id:', profile.id, 'userId:', profile.userId);
  console.log('DEBUG: updateData to be applied:', updateData);

  cleanEmptyStringsAndRemoveNulls(updateData);
  await profile.update(updateData);
  
  console.log('DEBUG: After update - profile.id:', profile.id, 'userId:', profile.userId);
  console.log('DEBUG: Calling getWithUser with id:', profile.id);
  
  const updatedProfile = await getWithUser(profile.id);
  
  console.log('DEBUG: getWithUser result:', updatedProfile ? 'found' : 'undefined');
  
  if (!updatedProfile) {
    throw { code: 404, message: "Profile not found after update" };
  }
  return updatedProfile;
}

module.exports = { updateServiceProviderProfile }; 