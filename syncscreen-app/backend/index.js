import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import ping from "ping";
import { exec } from "child_process";

import cors from "cors"; // Import the cors package

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const port = 3000;

app.use(cors());

app.use(express.static(path.join(__dirname, "../dist")));

// Define the absolute path to your scripts
const scriptsPath = path.join(__dirname, "../../");

app.get("/api/run-script", (req, res) => {
  const scriptName = req.query.name;
  console.log(`GET /api/run-script?name=${scriptName}`);
  if (!scriptName) {
    return res.status(400).json({ error: "Script name is required" });
  }

  const flags = Object.keys(req.query)
    .filter((key) => key !== "name")
    .map((key) => {
      if (req.query[key] === "true" || req.query[key] === "false") {
        return `--${key}`;
      } else {
        return `--${key} ${req.query[key]}`;
      }
    })
    .join(" ");

  // Execute the script with dynamic flags using absolute path
  const scriptPath = path.join(scriptsPath, `${scriptName}.sh`);
  console.log(`${scriptPath} ${flags}`);
  exec(`${scriptPath} ${flags}`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error executing script: ${error}`);
      return res
        .status(500)
        .json({ error: "Error executing script", details: stderr });
    }
    console.log(`Script output: ${stdout}`);
    res.json({ message: "Script executed", output: stdout });
  });
});

app.get("/api/reboot-device", (req, res) => {
  const piId = req.query.id;
  if (!piId) {
    return res.status(400).json({ error: "ID is required" });
  }

  // Execute the reboot.sh script with the specific ID using absolute path
  const scriptPath = path.join(scriptsPath, "reboot.sh");
  exec(`${scriptPath} ${piId}`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error executing script: ${error}`);
      return res
        .status(500)
        .json({ error: "Error executing script", details: stderr });
    }
    res.json({ message: "Reboot script executed", output: stdout });
  });
});

// Endpoint to ping a specific device by IP address
app.get("/api/ping-device", async (req, res) => {
  const ip = req.query.ip;
  if (!ip) {
    return res.status(400).json({ error: "IP address is required" });
  }

  try {
    const isAlive = await ping.promise.probe(ip);
    const status = isAlive.alive ? "online" : "offline";
    res.json({ ip, status });
  } catch (error) {
    res.status(500).json({ ip, status: "offline" });
  }
});

app.get("/api/get-infos", (req, res) => {
  const piId = req.query.id;
  if (!piId) {
    return res.status(400).json({ error: "ID is required" });
  }

  // Execute the get_infos.sh script with the specific ID using absolute path
  const scriptPath = path.join(scriptsPath, "get_infos.sh");
  exec(`${scriptPath} ${piId}`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error executing script: ${error}`);
      return res
        .status(500)
        .json({ error: "Error executing script", details: stderr });
    }
    try {
      const jsonOutput = JSON.parse(stdout);
      res.json({ message: "infos retrieved", output: jsonOutput });
    } catch (parseError) {
      console.error(`Error parsing JSON: ${parseError}`);
      res.status(500).json({
        error: "Error parsing script output",
        details: parseError.message,
      });
    }
  });
});

app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "../dist/index.html"));
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
