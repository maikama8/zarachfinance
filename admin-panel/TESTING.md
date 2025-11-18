# Testing the Admin Panel

## Current Status

✅ Server is running on port 3000
✅ MongoDB connected to Atlas
✅ Admin account created:
   - Email: `admin@zarfinance.com`
   - Password: `ZarFinance123!`

## Testing Steps

1. **Open the browser console** (F12 or Cmd+Option+I)

2. **Navigate to**: `http://localhost:3000`

3. **Check the console** for any errors

4. **Try to login** with:
   - Email: `admin@zarfinance.com`
   - Password: `ZarFinance123!`

5. **Watch the console** - you should see:
   - "Attempting login..."
   - "Response status: 200"
   - "Login successful, redirecting..."

6. **If login fails**, check:
   - Browser console for errors
   - Network tab to see the request/response
   - Cookies tab to see if `connect.sid` cookie is set

## Debugging

### Check if session is working:
```bash
curl -c cookies.txt -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@zarfinance.com","password":"ZarFinance123!"}'

curl -b cookies.txt http://localhost:3000/api/session-check
```

### Check server logs:
```bash
cd admin-panel
tail -f server.log
```

## Common Issues

1. **Cookies not being sent**: Check browser settings, try incognito mode
2. **CORS issues**: Should not be an issue since same origin
3. **Session not persisting**: Check if cookies are enabled in browser
4. **Cache issues**: Hard refresh (Cmd+Shift+R) or clear cache

## Manual Test

If the web interface doesn't work, you can test the API directly:

```bash
# Login and save cookie
curl -c cookies.txt -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@zarfinance.com","password":"ZarFinance123!"}'

# Check session
curl -b cookies.txt http://localhost:3000/api/session-check

# Access dashboard (should return HTML)
curl -b cookies.txt http://localhost:3000/dashboard | head -20
```

