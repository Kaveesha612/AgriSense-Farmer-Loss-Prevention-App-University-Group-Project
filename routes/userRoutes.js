import express from 'express';
import {
  getUserProfile,
  updateUserProfile,
  updateUserPassword,
  deleteUserProfile,
  getAllUsers,
  getUserById,
  updateUserRole,
  deleteUser,
  getFarmersInRegion,
} from '../controllers/userController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.route('/profile')
  .get(protect, getUserProfile)
  .put(protect, updateUserProfile)
  .delete(protect, deleteUserProfile);

router.route('/profile/password')
  .put(protect, updateUserPassword);

router.route('/')
  .get(protect, authorize('Admin'), getAllUsers);

router.route('/farmers/region')
  .get(protect, authorize('Admin', 'FarmerOfficer'), getFarmersInRegion);

router.route('/:id')
  .get(protect, authorize('Admin', 'FarmerOfficer'), getUserById)
  .delete(protect, authorize('Admin'), deleteUser);

router.route('/:id/role')
  .put(protect, authorize('Admin'), updateUserRole);

export default router;