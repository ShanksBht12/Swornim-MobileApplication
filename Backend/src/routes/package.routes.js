const express = require('express');
const router = express.Router();
const packageModuleRouter = require('../modules/package/package.routes');

router.use('/', packageModuleRouter);

module.exports = router; 