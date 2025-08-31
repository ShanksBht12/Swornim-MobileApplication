const ServicePackage = require('./package.model');
const { CreatePackageDTO, UpdatePackageDTO } = require('./package.validator');

// Create a new package
async function createPackage(req, res) {
  try {
    const { error, value } = CreatePackageDTO.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });
    const pkg = await ServicePackage.create(value);
    return res.status(201).json(pkg);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// Get all packages (optionally filter by serviceProviderId)
async function getPackages(req, res) {
  try {
    const { service_provider_id } = req.query;
    const where = service_provider_id ? { serviceProviderId: service_provider_id } : {};
    console.log('Fetching packages with query:', req.query);
    console.log('Where clause:', where);
    const pkgs = await ServicePackage.findAll({ where });
    console.log('Packages found:', pkgs);
    return res.json(pkgs);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// Get a single package by ID
async function getPackageById(req, res) {
  try {
    const { id } = req.params;
    const pkg = await ServicePackage.findByPk(id);
    if (!pkg) return res.status(404).json({ error: 'Package not found' });
    return res.json(pkg);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// Update a package
async function updatePackage(req, res) {
  try {
    const { id } = req.params;
    const { error, value } = UpdatePackageDTO.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });
    const pkg = await ServicePackage.findByPk(id);
    if (!pkg) return res.status(404).json({ error: 'Package not found' });
    await pkg.update(value);
    return res.json(pkg);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

// Delete a package
async function deletePackage(req, res) {
  try {
    const { id } = req.params;
    const pkg = await ServicePackage.findByPk(id);
    if (!pkg) return res.status(404).json({ error: 'Package not found' });
    await pkg.destroy();
    return res.status(204).send();
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = {
  createPackage,
  getPackages,
  getPackageById,
  updatePackage,
  deletePackage,
}; 