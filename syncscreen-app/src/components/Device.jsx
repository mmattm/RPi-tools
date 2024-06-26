import { useEffect, useState, forwardRef, useImperativeHandle } from "react";
import axios from "axios";
import PropTypes from "prop-types";
import moment from "moment";
import { FaSync } from "react-icons/fa";
import { serverPath } from "../components/RunScript";

const loading_text = "loading...";

const Device = forwardRef(({ device }, ref) => {
  const [status, setStatus] = useState("unknown");
  const [clock, setClock] = useState(loading_text);
  const [syncplay, setSyncplay] = useState(false);
  const [syncplayServer, setSyncplayServer] = useState(false);
  const [sleepTime, setSleepTime] = useState(false);
  const [wakeUpTime, setWakeUpTime] = useState(false);
  const [syncing, setSyncing] = useState(false);

  const getInfos = async () => {
    try {
      setSyncing(true);
      const response = await axios.get(
        `${serverPath}/api/get-infos?id=${device.id}`
      );
      const infos = response.data.output[device.ip];

      setSyncing(false);

      const formattedTime = moment.unix(infos.clock).format("HH:mm:ss");
      setClock(formattedTime);
      setSyncplay(infos["syncplay"]);
      setSyncplayServer(infos["syncplay-server"]);

      // if (infos.clock != false) {
      //   setStatus("online");
      // } else {
      //   setStatus("offline");
      // }

      if (device.id == 14) console.log(infos);

      if (infos["offline"]) {
        setStatus("offline");
      } else if (infos["syncplay"] === true) {
        setStatus("playing");
      } else if (infos["syncplay"] === false) {
        setStatus("online");
      }

      // Extract hour and minute from cron
      if (infos["cron"]) {
        const cronHour = parseInt(infos["cron"].hour, 10);
        const cronMinute = parseInt(infos["cron"].minute, 10);
        const sleepMinutes = parseInt(infos["cron"].sleep_minutes, 10);

        // Create a moment object for the cron time
        const cronTime = moment().hour(cronHour).minute(cronMinute);

        // Format cron time to "hh:mm"
        const formattedCronTime = cronTime.format("HH:mm");

        // Add sleep minutes to calculate wake-up time
        const wakeUpTime = cronTime
          .add(sleepMinutes, "minutes")
          .format("HH:mm");

        // console.log(`Sleep time: ${formattedCronTime}`);
        // console.log(`Wake-up time: ${wakeUpTime}`);
        setSleepTime(formattedCronTime);
        setWakeUpTime(wakeUpTime);
      } else {
        setSleepTime(false);
        setWakeUpTime(false);
      }
    } catch (error) {
      setStatus("offline");
      setSyncing(false);

      console.log(
        `Error getting infos for device ${device.id}: ${error.message}`
      );
    }
  };

  const rebootDevice = async () => {
    setSyncing(true);

    setStatus("online"); // Set status to unknown
    getInfos();

    try {
      const response = await axios.get(
        `${serverPath}/api/reboot-device?id=${device.id}`
      );

      setSyncing(false);
      console.log(
        `Reboot initiated for device ${device.id}: ${response.data.message}`
      );
      setStatus("offline");
    } catch (error) {
      setSyncing(false);
      console.log(`Error rebooting device ${device.id}: ${error.message}`);
    }
  };

  useEffect(() => {
    //console.log("Fetching device status: " + device.ip);

    // const fetchDeviceStatus = async () => {
    //   try {
    //     const response = await axios.get(
    //       `${serverPath}/api/ping-device?ip=${device.ip}`
    //     );
    //     //console.log(response.data);
    //     //console.log(`Device ${device.ip} is ${response.data.status}`);
    //     setStatus(response.data.status);
    //   } catch (error) {
    //     setStatus("offline");
    //   }
    // };

    // fetchDeviceStatus(); // Fetch status immediately on mount

    getInfos();

    const intervalId = setInterval(getInfos, 10000); // Fetch status every 10 seconds

    return () => clearInterval(intervalId); // Cleanup interval on unmount
  }, [device.ip]);

  useImperativeHandle(ref, () => ({
    rebootDevice,
  }));

  return (
    <div
      className={`p-4 border rounded-lg flex flex-col h-full ${
        status === "playing"
          ? "bg-green-300"
          : status === "offline"
          ? "bg-red-300"
          : "bg-gray-300"
      }`}
    >
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-4xl">🖥️ {device.id}</h2>
        </div>
        <div>
          {syncing && (
            <div className="flex items-center gap-2 text-gray-500	">
              <FaSync className="loading-icon" /> <p>Syncing</p>
            </div>
          )}
        </div>
      </div>
      <p>{device.ip}</p>
      <p>Status: {status}</p>
      {status !== "offline" && (
        <>
          <p>🕦 {clock}</p>
          <p>{syncplay === true ? "🟢" : "❌"} Syncplay Client</p>
          <p>{syncplayServer && "🟢 Syncplay Server"}</p>
          <p>
            {sleepTime && wakeUpTime && "😴" + sleepTime + "  ⏰" + wakeUpTime}
          </p>
        </>
      )}
      <div className="mt-auto">
        <button
          className="mt-3 w-full bg-white hover:bg-grey py-2 pt-3 rounded"
          onClick={() => rebootDevice()}
          disabled={status != "online" && status != "playing"}
          // disabled={status === "unknown" ? "disabled" : "not"} // Disable the button when rebooting
        >
          Reboot
        </button>
      </div>
    </div>
  );
});
// Add display name for better debugging and to satisfy ESLint rule
Device.displayName = "Device";

Device.propTypes = {
  device: PropTypes.shape({
    id: PropTypes.number.isRequired,
    ip: PropTypes.string.isRequired,
  }).isRequired,
};

export default Device;
