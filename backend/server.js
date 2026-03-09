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

        // Upsert user using PostgreSQL's ON CONFLICT syntax
        const userResult = await db.query(`
            INSERT INTO users (id, google_id, name, email, avatar, tracking_enabled, visibility_level, precision_level)
            VALUES ($1, $2, $3, $4, $5, true, 'friends', 'exact')
            ON CONFLICT (google_id) DO UPDATE SET
                name = EXCLUDED.name,
                email = EXCLUDED.email,
                avatar = EXCLUDED.avatar
            RETURNING *
        `, [uuidv4(), google_id, name, email, avatar]);

        const user = userResult.rows[0];

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
app.get('/api/users/me', async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
        const user = result.rows[0];
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json(user);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server error' });
    }
});

// PUT /api/users
app.put('/api/users', async (req, res) => {
    const { name, avatar, tracking_enabled, visibility_level, precision_level } = req.body;

    const updates = [];
    const values = [];
    let paramCount = 1;

    if (name !== undefined) { 
        updates.push(`name = $${paramCount++}`); 
        values.push(name); 
    }
    if (avatar !== undefined) { 
        updates.push(`avatar = $${paramCount++}`); 
        values.push(avatar); 
    }
    if (tracking_enabled !== undefined) { 
        updates.push(`tracking_enabled = $${paramCount++}`); 
        values.push(tracking_enabled); 
    }
    if (visibility_level !== undefined) { 
        updates.push(`visibility_level = $${paramCount++}`); 
        values.push(visibility_level); 
    }
    if (precision_level !== undefined) { 
        updates.push(`precision_level = $${paramCount++}`); 
        values.push(precision_level); 
    }

    if (updates.length === 0) return res.status(400).json({ message: 'No updates provided' });

    values.push(req.user.id); // Add user ID for WHERE clause

    try {
        await db.query(`UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCount}`, values);
        res.json({ message: 'User updated' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server error' });
    }
});

// POST /api/locations
app.post('/api/locations', async (req, res) => {
    const { latitude, longitude } = req.body;
    if (latitude === undefined || longitude === undefined) {
        return res.status(400).json({ message: 'Lat/Lng required' });
    }

    try {
        await db.query(
            'UPDATE users SET last_lat = $1, last_lng = $2, last_seen_at = NOW() WHERE id = $3',
            [latitude, longitude, req.user.id]
        );
        res.json({ message: 'Location updated' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server error' });
    }
});

// ── Invites ─────────────────────────────────────────────────────────────────

// POST /api/invites/:userId
app.post('/api/invites/:userId', async (req, res) => {
    const receiverEmailOrId = req.params.userId;
    const senderId = req.user.id;

    try {
        // Find receiver by ID or email
        const receiverResult = await db.query(
            'SELECT id FROM users WHERE id = $1 OR email = $1',
            [receiverEmailOrId]
        );
        
        if (receiverResult.rows.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        const receiver = receiverResult.rows[0];
        
        if (receiver.id === senderId) {
            return res.status(400).json({ message: 'Cannot invite yourself' });
        }

        // Try to insert invite, handle conflict if already exists
        try {
            await db.query(
                'INSERT INTO invitations (id, sender_id, receiver_id) VALUES ($1, $2, $3)',
                [uuidv4(), senderId, receiver.id]
            );
            res.json({ message: 'Invite sent' });
        } catch (err) {
            res.status(400).json({ message: 'Invite already exists or error' });
        }
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server error' });
    }
});

// GET /api/invites/:userId (userId is ignored, we use req.user.id)
app.get('/api/invites/:userId', async (req, res) => {
    const userId = req.user.id;

    try {
        const incomingResult = await db.query(`
            SELECT i.id, i.sender_id as user_id, u.name as user_name, u.avatar as user_avatar, 'incoming' as direction, i.status
            FROM invitations i
            JOIN users u ON i.sender_id = u.id
            WHERE i.receiver_id = $1 AND i.status = 'pending'
        `, [userId]);

        const outgoingResult = await db.query(`
            SELECT i.id, i.receiver_id as user_id, u.name as user_name, u.avatar as user_avatar, 'outgoing' as direction, i.status
            FROM invitations i
            JOIN users u ON i.receiver_id = u.id
            WHERE i.sender_id = $1
        `, [userId]);

        res.json([...incomingResult.rows, ...outgoingResult.rows]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server error' });
    }
});

// POST /api/invites/:userId/accept
app.post('/api/invites/:userId/accept', async (req, res) => {
    const senderId = req.params.userId;
    const receiverId = req.user.id;

    try {
        // Start transaction
        await db.query('BEGIN');
        
        // Check if invite exists and is pending
        const inviteResult = await db.query(
            'SELECT id FROM invitations WHERE sender_id = $1 AND receiver_id = $2 AND status = $3',
            [senderId, receiverId, 'pending']
        );
        
        if (inviteResult.rows.length === 0) {
            await db.query('ROLLBACK');
            return res.status(404).json({ message: 'Invite not found' });
        }

        const inviteId = inviteResult.rows[0].id;

        // Update invite status
        await db.query('UPDATE invitations SET status = $1 WHERE id = $2', ['accepted', inviteId]);
        
        // Insert friendship (both directions)
        await db.query(
            'INSERT INTO friends (user_id, friend_id) VALUES ($1, $2), ($2, $1) ON CONFLICT DO NOTHING',
            [senderId, receiverId]
        );

        await db.query('COMMIT');
        res.json({ message: 'Invite accepted' });
    } catch (err) {
        await db.query('ROLLBACK');
        console.error(err);
        res.status(500).json({ message: 'Server error' });
    }
});

// POST /api/invites/:userId/decline
app.post('/api/invites/:userId/decline', async (req, res) => {
    const senderId = req.params.userId;
    const receiverId = req.user.id;

    try {
        await db.query(
            'UPDATE invitations SET status = $1 WHERE sender_id = $2 AND receiver_id = $3',
            ['declined', senderId, receiverId]
        );
        res.json({ message: 'Invite declined' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server error' });
    }
});

// ── Friends ─────────────────────────────────────────────────────────────────

// GET /api/friends
app.get('/api/friends', async (req, res) => {
    try {
        const result = await db.query(`
            SELECT u.id, u.name, u.avatar, u.last_lat as latitude, u.last_lng as longitude, u.last_seen_at as last_seen,
                   u.visibility_level, u.precision_level, u.tracking_enabled
            FROM friends f
            JOIN users u ON f.friend_id = u.id
            WHERE f.user_id = $1
        `, [req.user.id]);

        const friends = result.rows;

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
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server error' });
    }
});

// DELETE /api/friends/:id
app.delete('/api/friends/:id', async (req, res) => {
    const friendId = req.params.id;
    const userId = req.user.id;

    try {
        // Start transaction
        await db.query('BEGIN');
        
        // Delete friendship in both directions
        await db.query(
            'DELETE FROM friends WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)',
            [userId, friendId]
        );

        await db.query('COMMIT');
        res.json({ message: 'Friend removed' });
    } catch (err) {
        await db.query('ROLLBACK');
        console.error(err);
        res.status(500).json({ message: 'Server error' });
    }
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