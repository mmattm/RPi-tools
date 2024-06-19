// Modal.js
import { useState } from "react";

import PropTypes from "prop-types";
import TimePicker from "react-time-picker";

import "react-time-picker/dist/TimePicker.css";
import "react-clock/dist/Clock.css";

const Modal = ({ isOpen, onClose }) => {
  const [value, onChange] = useState("");
  if (!isOpen) return null;

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
            <TimePicker onChange={onChange} value={value} />
          </div>
          <div className="flex flex-col">
            <label className="mr-3 mb-2">Sleep duration (minutes)</label>
            <input
              className="bg-white border border-black p-1 text-black"
              type="text"
            />
          </div>
        </div>
        <div className="mt-4 flex gap-2">
          <button className="bg-black text-white rounded p-2">Apply</button>
          <button
            className="bg-red-600 text-white rounded p-2"
            onClick={onClose}
          >
            Disabled schedule
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
