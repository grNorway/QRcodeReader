//
//  CameraControllerQRCode.swift
//  QRCodeReader
//


import AVFoundation
import UIKit

protocol CameraControllerQRCodeDelegate {
    func qrCodefound(qrCodeValue : String,bounds: CGRect)
}

class CameraControllerQRCode :NSObject{
    
    //MARK: - Properties
    
    var delegate : CameraControllerQRCodeDelegate?
    
    var captureSession : AVCaptureSession?
    
    var frontCamera: AVCaptureDevice?
    var rearCamera : AVCaptureDevice?
    
    var currentCameraPosition : CameraPosition?
    var frontCameraInput : AVCaptureDeviceInput?
    var rearCameraInput : AVCaptureDeviceInput?
    
    var rearCaptureInput : AVCaptureInput?
    var captureOutput : AVCaptureOutput?
    
    var photoOutput : AVCapturePhotoOutput?
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    enum CameraControllerError : Swift.Error{
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case outputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case torchCouldNotBeUsed
        case unableToFocus
        case unknown
    }
    
    public enum CameraPosition {
        case front
        case rear
    }
    
    
    
    func prepare(completionHandler : @escaping (Error?) -> ()){
        
        func createCaptureSession(){
            self.captureSession = AVCaptureSession()
        }
        
        func configureCaptureDevices() throws {
            
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
            
            let cameras = session.devices
            if cameras.isEmpty { throw CameraControllerError.noCamerasAvailable }
            
            for camera in cameras{
            
                print(camera.deviceType.rawValue)
                if camera.position == .front {
                    self.frontCamera = camera
                }
                
                if camera.position == .back {
                    self.rearCamera = camera
                    
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                    print(camera.activeVideoMaxFrameDuration)
                }
            }
            
        }
        
        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing}
            
            if let rearCamera = self.rearCamera {
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                self.rearCaptureInput = try AVCaptureDeviceInput(device: rearCamera)
                
                if captureSession.canAddInput(self.rearCameraInput!){
                    captureSession.addInput(self.rearCameraInput!)
                }else{
                    throw CameraControllerError.inputsAreInvalid
                }
                
                self.currentCameraPosition = .rear
                
            }else if let frontCamera = self.frontCamera {
                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                
                if captureSession.canAddInput(self.frontCameraInput!){
                    captureSession.addInput(self.frontCameraInput!)
                }else{
                    throw CameraControllerError.inputsAreInvalid
                }
                self.currentCameraPosition = .front
            }else{
                throw CameraControllerError.noCamerasAvailable
            }
        }
        
        func configurePhotoOutput() throws {
            guard let captureSession = self.captureSession else {
                throw CameraControllerError.captureSessionIsMissing
            }

            //metadataOutput
            
            let metadataOutput = AVCaptureMetadataOutput()
            

            if captureSession.canAddOutput(metadataOutput){
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }else{
                throw CameraControllerError.outputsAreInvalid
            }
            
            
            captureSession.startRunning()
        }
        
        DispatchQueue(label: "prepare").async {
            do{
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
            }catch{
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
            
        }
        
    }
    
    func displayPreview(on view : UIView) throws {
        guard let captureSession = self.captureSession,captureSession.isRunning else {
            throw CameraControllerError.captureSessionIsMissing
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        guard let previewLayer = self.previewLayer else {
            throw CameraControllerError.unknown
        }
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.insertSublayer(previewLayer, at: 0)
        previewLayer.frame = view.frame
        
    }
        
    
    func toggle(on:Bool)throws{
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw CameraControllerError.torchCouldNotBeUsed
        }
        
        if device.hasTorch{
            do{
                try device.lockForConfiguration()
                
                if on == true{
                    device.torchMode = .on
                }else{
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            }catch{
                throw CameraControllerError.torchCouldNotBeUsed
            }
        }else{
            throw CameraControllerError.torchCouldNotBeUsed
        }
    }
    
    func autofocus(focusPoint : CGPoint)throws{
        if let device = rearCamera{
            do{
                try device.lockForConfiguration()
                device.isFocusModeSupported(.continuousAutoFocus)
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
                device.exposurePointOfInterest = focusPoint
                
                device.exposureMode = .continuousAutoExposure
                device.unlockForConfiguration()
            }catch{
                throw CameraControllerError.unableToFocus
            }
        }
    }
    
}

extension CameraControllerQRCode : AVCaptureMetadataOutputObjectsDelegate{
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard let captureSession = captureSession ,captureSession.isRunning else {
            print("CaptureSession nil")
            return
        }
        
        guard !metadataObjects.isEmpty else {
            return
        }
        
        guard let metadataObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject else {
            print("Error Delegate method 1")
            return
        }
        
        let qrCodeBounds = metadataObject.bounds
        
        guard let QRCodeRect = previewLayer?.layerRectConverted(fromMetadataOutputRect: qrCodeBounds) else{
            return
        }
        
        guard let stringValue = metadataObject.stringValue else {
            return
        }
        
        guard let delegate = delegate else {
            print("Delegate : nil")
            return
        }
        
        delegate.qrCodefound(qrCodeValue: stringValue, bounds: QRCodeRect)
  
        
    }
}

