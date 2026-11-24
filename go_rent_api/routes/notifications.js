import { Router } from 'express';
import {
  getNotifications,
  updateNotification,
  deleteNotification,
} from '../controllers/notificationController.js';

const router = Router();

router.get('/', getNotifications);
router.put('/:id', updateNotification);
router.delete('/:id', deleteNotification);

export default router;
