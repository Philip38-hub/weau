require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const db = require('./database');
const authMiddleware = require('./middleware/auth');

const app = express();
const client = new OAuth2Client(); // In real app, pass Client ID

app.use(cors());
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET || 'weau_secret_key_123';

// ── Auth Route ──────────────────────────────────────────────────────────────

app.post('/api/auth', async (req, res) => {
    const { id_token } = req.body;
    if (!id_token) return res.status(400).json({ message: 'id_token required' });

    try {
        // In a real app, verify the Google ID token properly:
        // const ticket = await client.verifyIdToken({ idToken: id_token, audience: CLIENT_ID });
        // const payload = ticket.getPayload();
        // For this implementation, we simulate decoding or just use a mock payload if id_token is a mock string.

        let google_id, email, name, avatar;

        if (id_token === 'mock_google_id_token_xyz') {
            // Mock user for testing
            google_id = 'mock_google_id_123';
            email = 'mockuser@example.com';
            name = 'Mock User';
            avatar = 'https://api.dicebear.com/7.x/avataaars/svg?seed=mockuser';
        } else {
            // Logic for real token verification (commented out for simplicity unless actual CLIENT_ID is provided)
            google_id = 'id_' + id_token.substring(0, 10);
            email = id_token.includes('@') ? id_token : id_token.substring(0, 5) + '@example.com';
            name = 'User ' + id_token.substring(0, 5);
            avatar = null;
        }

        //Upsert user
        let user = db.prepare('SELECT * FROM users WHERE google_id = ?').get(google_id);

        if (!user) {
            const id = uuidv4();
            db.prepare('INSERT INTO users (id, google_id, name, email, avatar) VALUES (?, ?, ?, ?, ?)')
                .run(id, google_id, name, email, avatar);
            user = { id, google_id, name, email, avatar };
        }

        const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
        res.json({ access_token: token, user });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Authentication failed' });
    }
});

// ── Protected Routes ────────────────────────────────────────────────────────

app.use(authMiddleware);

// GET /api/users/me
app.get('/api/users/me', (req, res) => {
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
    res.json(user);
});

// PUT /api/users
app.put('/api/users', (req, res) => {
    const { name, avatar, tracking_enabled, visibility_level, precision_level } = req.body;

    const updates = [];
    const params = [];

    if (name !== undefined) { updates.push('name = ?'); params.push(name); }
    if (avatar !== undefined) { updates.push('avatar = ?'); params.push(avatar); }
    if (tracking_enabled !== undefined) { updates.push('tracking_enabled = ?'); params.push(tracking_enabled ? 1 : 0); }
    if (visibility_level !== undefined) { updates.push('visibility_level = ?'); params.push(visibility_level); }
    if (precision_level !== undefined) { updates.push('precision_level = ?'); params.push(precision_level); }

    if (updates.length === 0) return res.status(400).json({ message: 'No updates provided' });

    params.push(req.user.id);
    db.prepare(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`).run(...params);

    res.json({ message: 'User updated' });
});

// POST /api/locations
app.post('/api/locations', (req, res) => {
    const { latitude, longitude } = req.body;
    if (latitude === undefined || longitude === undefined) {
        return res.status(400).json({ message: 'Lat/Lng required' });
    }

    db.prepare('UPDATE users SET last_lat = ?, last_lng = ?, last_seen_at = CURRENT_TIMESTAMP WHERE id = ?')
        .run(latitude, longitude, req.user.id);

    res.json({ message: 'Location updated' });
});

// ── Invites ─────────────────────────────────────────────────────────────────

// POST /api/invites/:userId
app.post('/api/invites/:userId', (req, res) => {
    const receiverEmailOrId = req.params.userId;
    const senderId = req.user.id;

    // Find receiver
    const receiver = db.prepare('SELECT id FROM users WHERE id = ? OR email = ?').get(receiverEmailOrId, receiverEmailOrId);
    if (!receiver) return res.status(404).json({ message: 'User not found' });
    if (receiver.id === senderId) return res.status(400).json({ message: 'Cannot invite yourself' });

    try {
        db.prepare('INSERT INTO invitations (id, sender_id, receiver_id) VALUES (?, ?, ?)')
            .run(uuidv4(), senderId, receiver.id);
        res.json({ message: 'Invite sent' });
    } catch (err) {
        res.status(400).json({ message: 'Invite already exists or error' });
    }
});

// GET /api/invites/:userId (userId is ignore, we use req.user.id)
app.get('/api/invites/:userId', (req, res) => {
    const userId = req.user.id;

    const incoming = db.prepare(`
    SELECT i.id, i.sender_id as user_id, u.name as user_name, u.avatar as user_avatar, 'incoming' as direction, i.status
    FROM invitations i
    JOIN users u ON i.sender_id = u.id
    WHERE i.receiver_id = ? AND i.status = 'pending'
  `).all(userId);

    const outgoing = db.prepare(`
    SELECT i.id, i.receiver_id as user_id, u.name as user_name, u.avatar as user_avatar, 'outgoing' as direction, i.status
    FROM invitations i
    JOIN users u ON i.receiver_id = u.id
    WHERE i.sender_id = ?
  `).all(userId);

    res.json([...incoming, ...outgoing]);
});

// POST /api/invites/:userId/accept
app.post('/api/invites/:userId/accept', (req, res) => {
    const senderId = req.params.userId;
    const receiverId = req.user.id;

    const invite = db.prepare('SELECT * FROM invitations WHERE sender_id = ? AND receiver_id = ? AND status = "pending"')
        .get(senderId, receiverId);

    if (!invite) return res.status(404).json({ message: 'Invite not found' });

    const transact = db.transaction(() => {
        db.prepare('UPDATE invitations SET status = "accepted" WHERE id = ?').run(invite.id);
        db.prepare('INSERT OR IGNORE INTO friends (user_id, friend_id) VALUES (?, ?)').run(senderId, receiverId);
        db.prepare('INSERT OR IGNORE INTO friends (user_id, friend_id) VALUES (?, ?)').run(receiverId, senderId);
    });

    transact();
    res.json({ message: 'Invite accepted' });
});

// POST /api/invites/:userId/decline
app.post('/api/invites/:userId/decline', (req, res) => {
    const senderId = req.params.userId;
    const receiverId = req.user.id;

    db.prepare('UPDATE invitations SET status = "declined" WHERE sender_id = ? AND receiver_id = ?')
        .run(senderId, receiverId);

    res.json({ message: 'Invite declined' });
});

// ── Friends ─────────────────────────────────────────────────────────────────

// GET /api/friends
app.get('/api/friends', (req, res) => {
    const friends = db.prepare(`
    SELECT u.id, u.name, u.avatar, u.last_lat as latitude, u.last_lng as longitude, u.last_seen_at as last_seen,
           u.visibility_level, u.precision_level, u.tracking_enabled
    FROM friends f
    JOIN users u ON f.friend_id = u.id
    WHERE f.user_id = ?
  `).all(req.user.id);

    // Apply privacy logic
    const processed = friends.map(f => {
        const isVisible = f.tracking_enabled && (f.visibility_level === 'public' || f.visibility_level === 'friends');

        if (!isVisible || !f.latitude) {
            return { ...f, latitude: null, longitude: null };
        }

        if (f.precision_level === 'city') {
            // Blur location: Snap to roughly ~5km grid
            return {
                ...f,
                latitude: Math.round(f.latitude * 20) / 20,
                longitude: Math.round(f.longitude * 20) / 20,
                is_blurred: true
            };
        }

        return f;
    });

    res.json(processed);
});

// DELETE /api/friends/:id
app.delete('/api/friends/:id', (req, res) => {
    const friendId = req.params.id;
    const userId = req.user.id;

    const transact = db.transaction(() => {
        db.prepare('DELETE FROM friends WHERE user_id = ? AND friend_id = ?').run(userId, friendId);
        db.prepare('DELETE FROM friends WHERE user_id = ? AND friend_id = ?').run(friendId, userId);
    });

    transact();
    res.json({ message: 'Friend removed' });
});

const os = require('os');
const PORT = process.env.PORT || 3000;

function getNetworkAddress() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                return iface.address;
            }
        }
    }
    return null;
}

app.listen(PORT, '0.0.0.0', () => {
    const lanIp = getNetworkAddress();
    console.log(`weau backend running!`);
    console.log(`- Local: http://localhost:${PORT}`);
    if (lanIp) {
        console.log(`- Network: http://${lanIp}:${PORT}`);
    }
});
