const bcrypt = require('bcrypt');
const readline = require('readline');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { pool } = require('../config/database');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function createAdmin() {
  try {
    console.log('\n=== Create Admin User ===\n');
    
    const username = await question('Username: ');
    const email = await question('Email: ');
    const password = await question('Password: ');
    const role = await question('Role (SUPER_ADMIN/ADMIN) [ADMIN]: ') || 'ADMIN';
    
    if (!username || !email || !password) {
      console.error('Error: All fields are required!');
      process.exit(1);
    }
    
    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);
    
    // Insert admin user
    const result = await pool.query(
      `INSERT INTO admin_users (username, email, password_hash, role, created_at)
       VALUES ($1, $2, $3, $4, NOW())
       RETURNING user_id, username, email, role`,
      [username, email, passwordHash, role]
    );
    
    console.log('\n✓ Admin user created successfully!');
    console.log('\nUser Details:');
    console.log('  ID:', result.rows[0].user_id);
    console.log('  Username:', result.rows[0].username);
    console.log('  Email:', result.rows[0].email);
    console.log('  Role:', result.rows[0].role);
    console.log('\nYou can now login with these credentials.\n');
    
  } catch (error) {
    if (error.code === '23505') {
      console.error('\nError: Username or email already exists!');
    } else {
      console.error('\nError creating admin user:', error.message);
    }
    process.exit(1);
  } finally {
    rl.close();
    pool.end();
  }
}

createAdmin();
