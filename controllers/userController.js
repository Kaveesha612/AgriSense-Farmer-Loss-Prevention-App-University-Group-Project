import asyncHandler from 'express-async-handler';
import User from '../models/User.js';

// @desc    Get user profile
// @route   GET /api/users/profile
// @access  Private (All roles)
export const getUserProfile = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id).select('-password');
  if (user) {
    res.json(user);
  } else {
    res.status(404);
    throw new Error('User not found');
  }
});

// @desc    Update user profile (including farm locations)
// @route   PUT /api/users/profile
// @access  Private (All roles)
export const updateUserProfile = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id);
  if (user) {
    user.name = req.body.name || user.name;
    user.phone = req.body.phone || user.phone;
    user.preferredLanguage = req.body.preferredLanguage || user.preferredLanguage;
    user.notificationsEnabled = req.body.notificationsEnabled ?? user.notificationsEnabled;
    user.bio = req.body.bio !== undefined ? req.body.bio : user.bio;
    user.gender = req.body.gender || user.gender;

    if (req.body.farmLocations) {
      user.farmLocations = req.body.farmLocations;
    }

    if (req.body.password) {
      user.password = req.body.password;
    }

    const updatedUser = await user.save();
    res.json({
      _id: updatedUser._id,
      name: updatedUser.name,
      email: updatedUser.email,
      phone: updatedUser.phone,
      role: updatedUser.role,
      farmLocations: updatedUser.farmLocations,
      preferredLanguage: updatedUser.preferredLanguage,
      notificationsEnabled: updatedUser.notificationsEnabled,
      bio: updatedUser.bio,
      gender: updatedUser.gender,
    });
  } else {
    res.status(404);
    throw new Error('User not found');
  }
});

// @desc    Update user password
// @route   PUT /api/users/profile/password
// @access  Private (All roles)
export const updateUserPassword = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id);
  if (user) {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      res.status(400);
      throw new Error('Current password and new password are required');
    }

    const passwordMatch = await user.matchPassword(currentPassword);
    if (!passwordMatch) {
      res.status(401);
      throw new Error('Current password is incorrect');
    }

    user.password = newPassword;
    await user.save();
    res.json({ message: 'Password updated successfully' });
  } else {
    res.status(404);
    throw new Error('User not found');
  }
});

// @desc    Delete own profile
// @route   DELETE /api/users/profile
// @access  Private (All roles)
export const deleteUserProfile = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id);
  if (user) {
    await user.deleteOne();
    res.json({ message: 'Account deleted successfully' });
  } else {
    res.status(404);
    throw new Error('User not found');
  }
});

// @desc    Get all users (Admin only)
// @route   GET /api/users
// @access  Private/Admin
export const getAllUsers = asyncHandler(async (req, res) => {
  const users = await User.find({}).select('-password');
  res.json(users);
});

// @desc    Get user by ID (Admin & FarmerOfficer)
// @route   GET /api/users/:id
// @access  Private/Admin, FarmerOfficer
export const getUserById = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id).select('-password');
  if (user) {
    res.json(user);
  } else {
    res.status(404);
    throw new Error('User not found');
  }
});

// @desc    Update user role (Admin only)
// @route   PUT /api/users/:id/role
// @access  Private/Admin
export const updateUserRole = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id);
  if (user) {
    user.role = req.body.role;
    await user.save();
    res.json({ message: 'Role updated successfully' });
  } else {
    res.status(404);
    throw new Error('User not found');
  }
});

// @desc    Delete user (Admin only)
// @route   DELETE /api/users/:id
// @access  Private/Admin
export const deleteUser = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id);
  if (user) {
    await user.deleteOne();
    res.json({ message: 'User removed' });
  } else {
    res.status(404);
    throw new Error('User not found');
  }
});

// @desc    Get farmers in a region (FarmerOfficer only)
// @route   GET /api/users/farmers/region?lat=...&lng=...&radius=...
// @access  Private/FarmerOfficer
export const getFarmersInRegion = asyncHandler(async (req, res) => {
  const { lat, lng, radius = 10 } = req.query; // radius in km
  if (!lat || !lng) {
    res.status(400);
    throw new Error('Latitude and longitude required');
  }

  // Simplified: return all farmers (you could implement geospatial query)
  const farmers = await User.find({ role: 'Farmer' }).select('-password');
  // For real geospatial filtering, you would need to add a 2dsphere index on farmLocations.coordinates
  res.json(farmers);
});