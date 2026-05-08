import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const farmLocationSchema = mongoose.Schema({
  name: { type: String, required: true },
  coordinates: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  area: { type: Number }, // hectares
  cropStage: { type: String },
});

const userSchema = mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    phone: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    role: {
      type: String,
      enum: ['Farmer', 'FarmerOfficer', 'Admin'],
      default: 'Farmer',
    },
    farmLocations: [farmLocationSchema],
    preferredLanguage: { type: String, default: 'en' },
    notificationsEnabled: { type: Boolean, default: true },
    bio: { type: String, default: '' },
    gender: {
      type: String,
      enum: ['Male', 'Female', 'Other'],
      default: 'Male',
    },
  },
  { timestamps: true }
);

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

userSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

const User = mongoose.model('User', userSchema);
export default User;