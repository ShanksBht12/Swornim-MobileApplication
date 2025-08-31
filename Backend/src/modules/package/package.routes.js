const express = require('express');
const router = express.Router();
const packageController = require('./package.controller');
const { requireServiceProvider } = require('../../middlewares/auth.middleware');

// Public access for listing and viewing packages
router.get('/', packageController.getPackages);
router.get('/:id', packageController.getPackageById);

// Only service providers can create, update, delete
router.post('/', requireServiceProvider(), packageController.createPackage);
router.put('/:id', requireServiceProvider(), packageController.updatePackage);
router.delete('/:id', requireServiceProvider(), packageController.deletePackage);

module.exports = router; 