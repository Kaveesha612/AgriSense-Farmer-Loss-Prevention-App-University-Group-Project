import jwt from 'jsonwebtoken';

const token = jwt.sign(
  { id: '6a042b4d9850a594ba4ca642', role: 'Farmer' },
  'secret',
  { expiresIn: '30d' }
);

console.log('Token:', token);
