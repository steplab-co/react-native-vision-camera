import {NativeModules} from 'react-native';

import type {AudioInputDevice} from './types/AudioInput';

/**
 * Native module interface for CameraViewManager
 */
interface CameraViewManagerInterface {
  getAvailableAudioInputs(): Promise<AudioInputDevice[]>;
  getCurrentAudioInput(): Promise<AudioInputDevice | null>;
  setAudioInput(deviceId: string): Promise<boolean>;
}

/**
 * CameraViewManager provides access to native camera functionality
 */
export const CameraViewManager: CameraViewManagerInterface = {
  getAvailableAudioInputs: async (): Promise<AudioInputDevice[]> => {
    try {
      const {CameraViewManager: NativeCameraViewManager} = NativeModules;
      if (!NativeCameraViewManager) {
        throw new Error('CameraViewManager not found');
      }
      return await NativeCameraViewManager.getAvailableAudioInputs();
    } catch (error) {
      console.error('Failed to get available audio inputs:', error);
      return [];
    }
  },

  getCurrentAudioInput: async (): Promise<AudioInputDevice | null> => {
    try {
      const {CameraViewManager: NativeCameraViewManager} = NativeModules;
      if (!NativeCameraViewManager) {
        throw new Error('CameraViewManager not found');
      }
      return await NativeCameraViewManager.getCurrentAudioInput();
    } catch (error) {
      console.error('Failed to get current audio input:', error);
      return null;
    }
  },

  setAudioInput: async (deviceId: string): Promise<boolean> => {
    try {
      const {CameraViewManager: NativeCameraViewManager} = NativeModules;
      if (!NativeCameraViewManager) {
        throw new Error('CameraViewManager not found');
      }
      return await NativeCameraViewManager.setAudioInput(deviceId);
    } catch (error) {
      console.error('Failed to set audio input:', error);
      return false;
    }
  },
};
