// RunScript.jsx
import axios from "axios";

export const serverPath = "http://localhost:3000";

const runScript = async (scriptName, flags = {}) => {
  try {
    const params = { name: scriptName, ...flags };

    const response = await axios.get(`${serverPath}/api/run-script`, {
      params,
    });
    console.log(response.data);
  } catch (error) {
    console.error(`Error running script: ${error.message}`);
  }
};

export default runScript;
