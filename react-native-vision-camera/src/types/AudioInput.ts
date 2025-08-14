/**
 * Represents an available audio input device
 */
export interface AudioInputDevice {
  /**
   * Unique identifier for the audio input device
   */
  id: string;
  /**
   * Human-readable name of the audio input device
   */
  name: string;
  /**
   * Whether this is the built-in microphone
   */
  isBuiltIn: boolean;
  /**
   * Whether the device is currently connected
   */
  isConnected: boolean;
}

/**
 * Audio configuration options for the camera
 */
export interface AudioConfiguration {
  /**
   * The ID of the audio input device to use
   * If not specified, the default audio input will be used
   */
  audioInputId?: string;
}
