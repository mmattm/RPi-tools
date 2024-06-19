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

// Endpoint to run a script by name
app.get("/api/run-script", (req, res) => {
  const scriptName = req.query.name;
  if (!scriptName) {
    return res.status(400).json({ error: "Script name is required" });
  }

  // Execute the script by name
  exec(`../${scriptName}.sh`, (error, stdout, stderr) => {
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

  // Execute the reboot.sh script with the specific ID

  exec(`../reboot.sh ${piId}`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error executing script: ${error}`);
      return res
        .status(500)
        .json({ error: "Error executing script", details: stderr });
    }
    console.log(`Script output: ${stdout}`);
    res.json({ message: "Reboot script executed", output: stdout });
  });
});

// Endpoint to ping a specific device by IP address
app.get("/api/ping-device", async (req, res) => {
  //console.log("GET /api/ping-device");
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

  exec(`../get_infos.sh ${piId}`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error executing script: ${error}`);
      return res
        .status(500)
        .json({ error: "Error executing script", details: stderr });
    }
    console.log(`Script output: ${stdout}`);
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
