const express = require("express");
const fs = require("fs");
const cors = require("cors");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// ===== DB =====
const DB_FILE = "./db.json";

function loadDB() {
  if (!fs.existsSync(DB_FILE)) {
    fs.writeFileSync(DB_FILE, JSON.stringify({
      users: {},
      total: 0,
      daily: {},
      newToday: 0,
      lastDay: ""
    }, null, 2));
  }
  return JSON.parse(fs.readFileSync(DB_FILE));
}

function saveDB(db) {
  fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2));
}

// ===== HELPERS =====
function today() {
  return new Date().toISOString().slice(0, 10);
}

// ===== ENDPOINT EXEC (ROBLOX) =====
app.post("/exec", (req, res) => {
  const { userId, username } = req.body;
  if (!userId) return res.status(400).json({ error: "No userId" });

  const db = loadDB();
  const t = today();

  // reset día
  if (db.lastDay !== t) {
    db.daily = {};
    db.newToday = 0;
    db.lastDay = t;
  }

  // total ejecuciones (solo 1 vez por usuario)
  if (!db.users[userId]) {
    db.users[userId] = {
      username,
      firstSeen: t
    };
    db.total++;
    db.newToday++;
  }

  // usos hoy
  if (!db.daily[userId]) {
    db.daily[userId] = true;
  }

  saveDB(db);

  res.json({ ok: true });
});

// ===== STATS (PANEL) =====
app.get("/stats", (req, res) => {
  const db = loadDB();
  const t = today();

  const todayUses = Object.keys(db.daily).length;

  res.json({
    total: db.total,
    today: todayUses,
    online: true,
    newToday: db.newToday
  });
});

// ===== KEEP ALIVE =====
app.get("/", (_, res) => {
  res.send("DZ API ONLINE");
});

app.listen(PORT, () => {
  console.log("DZ API running on port", PORT);
});
