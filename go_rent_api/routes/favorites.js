import { Router } from 'express';
import { addFavorite, removeFavorite } from '../controllers/favoriteController.js';

const router = Router();

router.post('/', addFavorite);
router.delete('/:car_id', removeFavorite);

export default router;
