//
//  QRScannerController.swift
//  QRCodeReader
//
//  Created by Simon Ng on 13/10/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import AVFoundation

class QRScannerController: UIViewController,AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var topbar: UIView!
    
    var captureSession:AVCaptureSession!
    var videoPreviewLayer:AVCaptureVideoPreviewLayer!
    var qrCodeFrameView:UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            self.camera()
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    self.camera()
                } else {
                    //access denied
                }
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession.isRunning == false){
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
//        if let metadataObject = metadataObjects.first {
//            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
//            qrCodeFrameView.frame = readableObject.bounds
//            guard let stringValue = readableObject.stringValue else {return}
////            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
////            found(code: stringValue)
//            messageLabel.text = readableObject.stringValue
//        }
        
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                messageLabel.text = metadataObj.stringValue
            }
        }
    }
    
    private func camera(){
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else{
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do{
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        }catch{
            print("1")
            return
        }
        
        if (captureSession.canAddInput(videoInput)){
            captureSession.addInput(videoInput)
        }else{
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)){
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }else{
            failed()
            return
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = view.layer.bounds
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoPreviewLayer)
        captureSession.startRunning()
        
        // Move the message label and top bar to the front
        view.bringSubviewToFront(messageLabel)
        view.bringSubviewToFront(topbar)
        
        qrCodeFrameView = UIView()
        if let qrCodeFrameView = qrCodeFrameView{
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
    }
    
    func found(code: String) {
        print(code)
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
