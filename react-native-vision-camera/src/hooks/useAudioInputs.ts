import {useCallback, useState} from 'react';

import {CameraViewManager} from '../CameraViewManager';
import type {AudioInputDevice} from '../types/AudioInput';

/**
 * Hook for managing audio input devices
 */
export function useAudioInputs() {
  const [availableInputs, setAvailableInputs] = useState<AudioInputDevice[]>(
    []
  );
  const [currentInput, setCurrentInput] = useState<AudioInputDevice | null>(
    null
  );
  const [isLoading, setIsLoading] = useState(false);

  /**
   * Gets all available audio input devices
   */
  const getAvailableAudioInputs = useCallback(async (): Promise<
    AudioInputDevice[]
  > => {
    try {
      setIsLoading(true);
      const inputs = await CameraViewManager.getAvailableAudioInputs();
      setAvailableInputs(inputs);
      return inputs;
    } catch (error) {
      console.error('Failed to get available audio inputs:', error);
      return [];
    } finally {
      setIsLoading(false);
    }
  }, []);

  /**
   * Gets the currently selected audio input device
   */
  const getCurrentAudioInput =
    useCallback(async (): Promise<AudioInputDevice | null> => {
      try {
        const input = await CameraViewManager.getCurrentAudioInput();
        setCurrentInput(input);
        return input;
      } catch (error) {
        console.error('Failed to get current audio input:', error);
        return null;
      }
    }, []);

  /**
   * Sets the audio input device
   */
  const setAudioInput = useCallback(
    async (deviceId: string): Promise<boolean> => {
      try {
        await CameraViewManager.setAudioInput(deviceId);

        // Update current input
        const newInput = availableInputs.find(input => input.id === deviceId);
        if (newInput) {
          setCurrentInput(newInput);
        }

        return true;
      } catch (error) {
        console.error('Failed to set audio input:', error);
        return false;
      }
    },
    [availableInputs]
  );

  /**
   * Refreshes the list of available audio inputs and current selection
   */
  const refreshAudioInputs = useCallback(async () => {
    await Promise.all([getAvailableAudioInputs(), getCurrentAudioInput()]);
  }, [getAvailableAudioInputs, getCurrentAudioInput]);

  return {
    availableInputs,
    currentInput,
    isLoading,
    getAvailableAudioInputs,
    getCurrentAudioInput,
    setAudioInput,
    refreshAudioInputs,
  };
}
