//
//  CameraViewManager.swift
//  mrousavy
//
//  Created by Marc Rousavy on 09.11.20.
//  Copyright © 2020 mrousavy. All rights reserved.
//

import AVFoundation
import CoreLocation
import Foundation

/**
 Audio input manager for handling audio input device selection
 */
final class AudioInputManager {
  
  // MARK: - Types
  
  /**
   Represents an available audio input device
   */
  struct AudioInputDevice: Equatable {
    let id: String
    let name: String
    let isBuiltIn: Bool
    let isConnected: Bool
    
    init(id: String, name: String, isBuiltIn: Bool, isConnected: Bool) {
      self.id = id
      self.name = name
      self.isBuiltIn = isBuiltIn
      self.isConnected = isConnected
    }
  }
  
  // MARK: - Properties
  
  private let audioSession = AVAudioSession.sharedInstance()
  
  // MARK: - Initialization
  
  init() {
    setupAudioSession()
  }
  
  private func setupAudioSession() {
    do {
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth,.allowBluetoothA2DP,])
      try audioSession.setActive(true)
      print("[AudioInputManager] Audio session configured successfully")
    } catch {
      print("[AudioInputManager] Failed to configure audio session: \(error)")
    }
  }
  
  // MARK: - Public Methods
  
  /**
   Gets all available audio input devices
   */
  func getAvailableAudioInputs() -> [AudioInputDevice] {
    var devices: [AudioInputDevice] = []
    
    // Get built-in microphone
    if let builtInMic = AVCaptureDevice.default(for: .audio) {
      let builtInId = builtInMic.uniqueID
      let builtInDevice = AudioInputDevice(
        id: builtInId,
        name: "Built-in Microphone",
        isBuiltIn: true,
        isConnected: true
      )
      print("[AudioInputManager] Found built-in microphone: '\(builtInId)' (length: \(builtInId.count), bytes: \(Array(builtInId.utf8)))")
      devices.append(builtInDevice)
    }
    
    // Get external audio inputs
    if #available(iOS 14.0, *) {
      let inputs = audioSession.availableInputs ?? []
      print("[AudioInputManager] Available audio session inputs: \(inputs.map { "\($0.portName) ('\($0.uid)')" })")
      
      for input in inputs {
        // Skip built-in microphone as we already added it
        if input.portType != .builtInMic {
          let inputId = input.uid
          let device = AudioInputDevice(
            id: inputId,
            name: input.portName,
            isBuiltIn: false,
            isConnected: true
          )
          print("[AudioInputManager] Added external input: '\(input.portName)' ('\(inputId)', length: \(inputId.count), bytes: \(Array(inputId.utf8)))")
          devices.append(device)
        }
      }
    }
    
    // If no devices found, at least ensure we have the built-in microphone
    if devices.isEmpty {
      let fallbackDevice = AudioInputDevice(
        id: "builtin_microphone",
        name: "Built-in Microphone",
        isBuiltIn: true,
        isConnected: true
      )
      print("[AudioInputManager] No devices found, adding fallback built-in microphone")
      devices.append(fallbackDevice)
    }
    
    print("[AudioInputManager] Returning \(devices.count) devices:")
    for device in devices {
      print("[AudioInputManager]   - \(device.name): '\(device.id)' (length: \(device.id.count), bytes: \(Array(device.id.utf8)))")
    }
    return devices
  }
  
  /**
   Gets the currently selected audio input device
   */
  func getCurrentAudioInput() -> AudioInputDevice? {
    if let currentInput = audioSession.currentRoute.inputs.first {
      let device = AudioInputDevice(
        id: currentInput.uid,
        name: currentInput.portName,
        isBuiltIn: currentInput.portType == .builtInMic,
        isConnected: true
      )
      return device
    }
    return nil
  }
  
  /**
   Sets the audio input device by ID
   */
  func setAudioInput(deviceId: String) throws {
            try audioSession.updateCategory(AVAudioSession.Category.playAndRecord,
                                            mode: .videoRecording,
                                            options: [.mixWithOthers,
                                                      .allowBluetoothA2DP,
                                                      .allowBluetooth,
                                                      .defaultToSpeaker,
                                                      .allowAirPlay])

     
      try audioSession.setActive(true)
    print("[AudioInputManager] Attempting to set audio input to device ID: '\(deviceId)'")
    print("[AudioInputManager] Device ID length: \(deviceId.count)")
    print("[AudioInputManager] Device ID bytes: \(Array(deviceId.utf8))")
    
    // Ensure audio session is active
    if !audioSession.isOtherAudioPlaying {
      do {
        try audioSession.setActive(true)
      } catch {
        print("[AudioInputManager] Warning: Could not activate audio session: \(error)")
      }
    }
    
    if #available(iOS 14.0, *) {
      // First check if it's the built-in microphone
      if let builtInMic = AVCaptureDevice.default(for: .audio) {
        let builtInId = builtInMic.uniqueID
        print("[AudioInputManager] Built-in mic ID: '\(builtInId)'")
        print("[AudioInputManager] Built-in mic ID length: \(builtInId.count)")
        print("[AudioInputManager] Built-in mic ID bytes: \(Array(builtInId.utf8))")
        print("[AudioInputManager] IDs match? \(deviceId == builtInId)")
        
        if builtInId == deviceId {
          print("[AudioInputManager] Setting to built-in microphone")
          // For built-in microphone, we don't need to set preferred input
          // Just ensure the audio session is configured for recording
          try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
          try audioSession.setActive(true)
          return
        }
      }
      
      // Check for fallback built-in microphone
      if deviceId == "builtin_microphone" {
        print("[AudioInputManager] Setting to fallback built-in microphone")
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
        try audioSession.setActive(true)
        return
      }
      
      // Check external inputs
      let inputs = audioSession.availableInputs ?? []
      print("[AudioInputManager] Available external inputs: \(inputs.map { "\($0.portName) ('\($0.uid)')" })")
      
      for input in inputs {
        let inputId = input.uid
        print("[AudioInputManager] Checking input '\(input.portName)' with ID '\(inputId)'")
        print("[AudioInputManager] Input ID length: \(inputId.count)")
        print("[AudioInputManager] Input ID bytes: \(Array(inputId.utf8))")
        print("[AudioInputManager] IDs match? \(deviceId == inputId)")
      }
      
      if let targetInput = inputs.first(where: { $0.uid == deviceId }) {
        print("[AudioInputManager] Setting to external input: \(targetInput.portName)")
        
        try audioSession.setPreferredInput(targetInput)
       
      } else {
        print("[AudioInputManager] Device not found. Requested ID: '\(deviceId)'")
        throw AudioInputError.deviceNotFound
      }
    } else {
      throw AudioInputError.unsupportedVersion
    }
  }
}

// MARK: - AudioInputError

enum AudioInputError: Error, LocalizedError {
  case deviceNotFound
  case unsupportedVersion
  
  var errorDescription: String? {
    switch self {
    case .deviceNotFound:
      return "Audio input device not found"
    case .unsupportedVersion:
      return "Audio input selection not supported on this iOS version"
    }
  }
}

@objc(CameraViewManager)
final class CameraViewManager: RCTViewManager {
  // pragma MARK: Properties

  override var methodQueue: DispatchQueue! {
    return DispatchQueue.main
  }

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  override final func view() -> UIView! {
    return CameraView()
  }

  // pragma MARK: React Functions

  @objc
  final func installFrameProcessorBindings() -> NSNumber {
    #if VISION_CAMERA_ENABLE_FRAME_PROCESSORS
      // Called on JS Thread (blocking sync method)
      let result = VisionCameraInstaller.install(with: self)
      return NSNumber(value: result)
    #else
      return false as NSNumber
    #endif
  }

  // TODO: The startRecording() func cannot be async because RN doesn't allow
  //       both a callback and a Promise in a single function. Wait for TurboModules?
  //       This means that any errors that occur in this function have to be delegated through
  //       the callback, but I'd prefer for them to throw for the original function instead.
  @objc
  final func startRecording(_ node: NSNumber, options: NSDictionary, onRecordCallback: @escaping RCTResponseSenderBlock) {
    let component = getCameraView(withTag: node)
    component.startRecording(options: options, callback: onRecordCallback)
  }

  @objc
  final func pauseRecording(_ node: NSNumber, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let component = getCameraView(withTag: node)
    component.pauseRecording(promise: Promise(resolver: resolve, rejecter: reject))
  }

  @objc
  final func resumeRecording(_ node: NSNumber, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let component = getCameraView(withTag: node)
    component.resumeRecording(promise: Promise(resolver: resolve, rejecter: reject))
  }

  @objc
  final func stopRecording(_ node: NSNumber, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let component = getCameraView(withTag: node)
    component.stopRecording(promise: Promise(resolver: resolve, rejecter: reject))
  }

  @objc
  final func cancelRecording(_ node: NSNumber, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let component = getCameraView(withTag: node)
    component.cancelRecording(promise: Promise(resolver: resolve, rejecter: reject))
  }

  @objc
  final func takePhoto(_ node: NSNumber, options: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let component = getCameraView(withTag: node)
    component.takePhoto(options: options, promise: Promise(resolver: resolve, rejecter: reject))
  }

  @objc
  final func takeSnapshot(_ node: NSNumber, options: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let component = getCameraView(withTag: node)
    component.takeSnapshot(options: options, promise: Promise(resolver: resolve, rejecter: reject))
  }

  @objc
  final func focus(_ node: NSNumber, point: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let promise = Promise(resolver: resolve, rejecter: reject)
    guard let x = point["x"] as? NSNumber, let y = point["y"] as? NSNumber else {
      promise.reject(error: .parameter(.invalid(unionName: "point", receivedValue: point.description)))
      return
    }
    let component = getCameraView(withTag: node)
    component.focus(point: CGPoint(x: x.doubleValue, y: y.doubleValue), promise: promise)
  }

  @objc
  final func getCameraPermissionStatus() -> String {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    return status.descriptor
  }

  @objc
  final func getMicrophonePermissionStatus() -> String {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)
    return status.descriptor
  }

  @objc
  final func getLocationPermissionStatus() -> String {
    #if VISION_CAMERA_ENABLE_LOCATION
      let status = CLLocationManager.authorizationStatus()
      return status.descriptor
    #else
      return CLAuthorizationStatus.restricted.descriptor
    #endif
  }

  @objc
  final func requestCameraPermission(_ resolve: @escaping RCTPromiseResolveBlock, reject _: @escaping RCTPromiseRejectBlock) {
    AVCaptureDevice.requestAccess(for: .video) { granted in
      let result: AVAuthorizationStatus = granted ? .authorized : .denied
      resolve(result.descriptor)
    }
  }

  @objc
  final func requestMicrophonePermission(_ resolve: @escaping RCTPromiseResolveBlock, reject _: @escaping RCTPromiseRejectBlock) {
    AVCaptureDevice.requestAccess(for: .audio) { granted in
      let result: AVAuthorizationStatus = granted ? .authorized : .denied
      resolve(result.descriptor)
    }
  }

  @objc
  final func requestLocationPermission(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    #if VISION_CAMERA_ENABLE_LOCATION
      CLLocationManager.requestAccess(for: .whenInUse) { status in
        resolve(status)
      }
    #else
      let promise = Promise(resolver: resolve, rejecter: reject)
      promise.reject(error: .system(.locationNotEnabled))
    #endif
  }
  
  @objc
  final func getAvailableAudioInputs(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let audioInputManager = AudioInputManager()
    let devices = audioInputManager.getAvailableAudioInputs()
    
    let deviceDicts = devices.map { device in
      return [
        "id": device.id,
        "name": device.name,
        "isBuiltIn": device.isBuiltIn,
        "isConnected": device.isConnected
      ] as [String: Any]
    }
    
    resolve(deviceDicts)
  }
  
  @objc
  final func getCurrentAudioInput(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let audioInputManager = AudioInputManager()
    if let currentDevice = audioInputManager.getCurrentAudioInput() {
      let deviceDict = [
        "id": currentDevice.id,
        "name": currentDevice.name,
        "isBuiltIn": currentDevice.isBuiltIn,
        "isConnected": currentDevice.isConnected
      ] as [String: Any]
      resolve(deviceDict)
    } else {
      resolve(nil)
    }
  }
  
  @objc
  final func setAudioInput(_ deviceId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    do {
      let audioInputManager = AudioInputManager()
      try audioInputManager.setAudioInput(deviceId: deviceId)
      resolve(true)
    } catch {
      reject("AUDIO_INPUT_ERROR", "Failed to set audio input: \(error.localizedDescription)", error)
    }
  }

  // MARK: Private

  func getCameraView(withTag tag: NSNumber) -> CameraView {
    // swiftlint:disable force_cast
    return bridge.uiManager.view(forReactTag: tag) as! CameraView
    // swiftlint:enable force_cast
  }
}
