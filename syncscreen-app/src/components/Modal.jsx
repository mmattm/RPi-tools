// Modal.js
import { useState } from "react";

import PropTypes from "prop-types";
import TimePicker from "react-time-picker";

import "react-time-picker/dist/TimePicker.css";
import "react-clock/dist/Clock.css";
import runScript from "../components/RunScript";

const Modal = ({ isOpen, onClose }) => {
  const [time, setTime] = useState("");
  const [duration, setDuration] = useState("");

  if (!isOpen) return null;

  const handleApply = () => {
    if (!time || !duration) {
      alert("Please provide both sleep time and duration.");
      return;
    }

    const [hour, minute] = time.split(":");
    const wakeMinutes = parseInt(duration, 10);

    runScript("schedule", {
      "shutdown-hour": hour,
      "shutdown-minute": minute,
      "wake-minutes": wakeMinutes,
    });

    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center">
      <div className="bg-white p-4 rounded-lg shadow-lg w-1/3 relative">
        <button
          onClick={onClose}
          className="absolute bg-white top-0 right-0 m-4 text-black"
        >
          ✖
        </button>
        <h2 className="text-2xl mb-4">Schedule</h2>
        <div className="grid grid-cols-2 gap-4">
          <div className="flex flex-col">
            <label className="mr-3 mb-2">Sleep Time</label>
            <TimePicker onChange={setTime} value={time} />
          </div>
          <div className="flex flex-col">
            <label className="mr-3 mb-2">Sleep duration (minutes)</label>
            <input
              className="bg-white border border-black p-1 text-black"
              type="text"
              value={duration}
              onChange={(e) => setDuration(e.target.value)}
            />
          </div>
        </div>
        <div className="mt-4 flex gap-2">
          <button
            className="bg-black text-white rounded p-2"
            onClick={handleApply}
          >
            Apply
          </button>
          <button
            className="bg-red-600 text-white rounded p-2"
            onClick={() => {
              runScript("schedule", { disable: true });
              onClose();
            }}
          >
            Disable schedule
          </button>
        </div>
      </div>
    </div>
  );
};

// Validation props
Modal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onClose: PropTypes.func.isRequired,
};

export default Modal;
