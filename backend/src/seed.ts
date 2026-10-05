import 'dotenv/config';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

// The regular server owns the schemas; this tiny seed script is intentionally a safe,
// idempotent demo-account helper for local development.
const uri=process.env.MONGO_URI ?? 'mongodb://localhost:27017/relay';
await mongoose.connect(uri);
const users=mongoose.connection.collection('users');
const passwordHash=await bcrypt.hash('password123',12);
for (const [displayName,email] of [['Alex Morgan','alex@relay.local'],['Sam Rivera','sam@relay.local']]) {
  await users.updateOne({email},{$setOnInsert:{displayName,email,passwordHash,createdAt:new Date()}},{upsert:true});
}
console.log('Seeded alex@relay.local and sam@relay.local with password123');
await mongoose.disconnect();
