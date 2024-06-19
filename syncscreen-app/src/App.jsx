import { useRef, useState } from "react";
import axios from "axios";

import Device from "./components/Device";
import Clock from "./components/Clock";
import Modal from "./components/Modal";
// import axios from "axios";

export const serverPath = "http://localhost:3000";

const deviceList = [
  { id: 1, ip: "10.0.1.101" },
  { id: 2, ip: "10.0.1.102" },
  { id: 3, ip: "10.0.1.103" },
  { id: 4, ip: "10.0.1.104" },
  { id: 5, ip: "10.0.1.105" },
  { id: 6, ip: "10.0.1.106" },
  { id: 7, ip: "10.0.1.107" },
  { id: 8, ip: "10.0.1.108" },
  { id: 9, ip: "10.0.1.109" },
  { id: 10, ip: "10.0.1.110" },
  { id: 11, ip: "10.0.1.111" },
  { id: 12, ip: "10.0.1.112" },
  { id: 13, ip: "10.0.1.113" },
  { id: 14, ip: "10.0.1.114" },
  { id: 15, ip: "10.0.1.115" },
  { id: 16, ip: "10.0.1.116" },
  { id: 17, ip: "10.0.1.117" },
  { id: 18, ip: "10.0.1.118" },
  { id: 19, ip: "10.0.1.119" },
];

function App() {
  const deviceRefs = useRef([]);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const rebootAllDevices = () => {
    deviceRefs.current.forEach((ref) => ref && ref.rebootDevice());
  };

  const handleScheduleClick = () => {
    setIsModalOpen(true);
  };

  const runScript = async (scriptName) => {
    try {
      const response = await axios.get(
        `${serverPath}/api/run-script?name=${scriptName}`
      );
      console.log(response.data);
    } catch (error) {
      console.error(`Error running script: ${error.message}`);
    }
  };

  return (
    <div className="bg-gray-100 p-4">
      <div className="flex items-center justify-between">
        <h1 className="text-6xl">
          SyncScreen <Clock />
        </h1>

        <img src="/ecal_logo.svg" alt="Logo" className="h-16" />
      </div>
      <div>
        <h2 className="text-3xl my-4">Devices</h2>

        <div className="grid grid-cols-4 gap-4">
          {deviceList.map((device, index) => (
            <Device
              key={device.id}
              device={device}
              ref={(el) => (deviceRefs.current[index] = el)}
              // rebootDevice={rebootDevice}
            />
          ))}
        </div>
      </div>
      <div className="w-full flex flex-col my-4">
        <h2 className="text-3xl my-4">Controls</h2>
        <div className="flex gap-4">
          <button
            onClick={rebootAllDevices}
            className="w-64 h-24 bg-white border text-xl rounded-lg"
          >
            🔄 Reboot and reset clock (All)
          </button>

          <button
            onClick={() => runScript("resume_syncplay")}
            className="w-64 h-24 bg-white border text-xl rounded-lg"
          >
            ❌ Kill Syncplay
          </button>

          <button
            onClick={() => runScript("run_syncplay")}
            className="w-64 h-24 bg-white border text-xl rounded-lg"
          >
            🟢 Resume Syncplay
          </button>

          <button
            onClick={() => runScript("toggle-play-pause")}
            className="w-64 h-24 bg-white border text-xl rounded-lg"
          >
            ⏯️ Pause / Play
          </button>
          <button
            // onClick={() => runScript("script3")}
            onClick={handleScheduleClick}
            className="w-64 h-24 bg-white border text-xl rounded-lg"
          >
            ⏰ Schedule
          </button>
          <button
            // onClick={() => runScript("script4")}
            className="w-64 h-24 bg-white border text-xl rounded-lg"
          >
            🚀 Upload videos
          </button>
        </div>
      </div>
      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)}>
        {/* Empty Modal */}
      </Modal>
    </div>
  );
}

export default App;
