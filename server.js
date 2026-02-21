import express from "express";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 5173;
const BASE_PATH = "/vivo_app";

// 1️⃣ Serve static assets
app.use(BASE_PATH, express.static(path.join(__dirname, "dist")));

// 2️⃣ SPA fallback (IMPORTANT FIX)
app.use((req, res, next) => {
  if (req.path.startsWith(BASE_PATH)) {
    res.sendFile(path.join(__dirname, "dist/index.html"));
  } else {
    next();
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ App running at http://0.0.0.0:${PORT}${BASE_PATH}/`);
});
