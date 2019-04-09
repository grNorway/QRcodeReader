//
//  QRScannerController.swift
//  QRCodeReader
//


import UIKit
import AVFoundation

class QRScannerController: UIViewController{

    //MARK: - Outlets
    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var topbar: UIView!
    @IBOutlet weak var targetView: UIView!
    @IBOutlet weak var torchButton: UIButton!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    //MARK: - Properties
    var qrCodeFrameView : UIView!
    
    let cameraControllerQRCode = CameraControllerQRCode()
    
    var torchMode : Bool = false
    
    var scaningline : UIView!
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraControllerQRCode.delegate = self
        AuthorizationCheck()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupUITargetview()
        blurView.mask(withRect: CGRect.init(origin: CGPoint(x: targetView.frame.origin.x, y: targetView.frame.origin.y), size: CGSize(width: targetView.frame.width, height: targetView.frame.height)), inverse: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addScanningLine()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let captureSession = cameraControllerQRCode.captureSession else {
            return
        }
        
        if captureSession.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    //MARK: - CameraControllerQRCode configuration
    
    func configureCameraControllerQRCode(){
        cameraControllerQRCode.prepare { (error) in
            if let error = error {
                print(error)
            }
            do{
                try self.cameraControllerQRCode.displayPreview(on: self.view)
            }catch{
                print(error)
                //AlertController
            }
        }
    }
    
    
    //MARK: - Actions
    
    @IBAction func toggleFlash(_ sender: UIButton) {
        if torchMode == false {
            torchMode = true
        }else{
            torchMode = false
        }
        
        do{
            try cameraControllerQRCode.toggle(on: torchMode)
        }catch{
            print(error)
            //AlertController
        }
        
    }
    
    //MARK: - Helper Functions
    
    private func addScanningLine(){
        scaningline = UIView(frame: CGRect(x: targetView.frame.minX + 10, y: targetView.frame.midY - 60, width: targetView.frame.width - 20, height: 2.0))
        scaningline.layer.borderColor = UIColor.red.cgColor
        scaningline.layer.backgroundColor = UIColor.red.cgColor
        view.addSubview(scaningline)
        
        
        UIView.animate(withDuration: 1, delay: 0, options: [.repeat,.autoreverse], animations: {
            self.scaningline.frame = CGRect(x: self.targetView.frame.minX + 10, y: self.targetView.frame.midY + 60, width: self.targetView.frame.width - 20, height: 2.0)
            
        }, completion: nil)
    }
    
    fileprivate func performFoundAnimation(on targetView: UIView) {
        let bezierPath = UIBezierPath(roundedRect: targetView.frame, cornerRadius: 10)
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 4
        
        shapeLayer.path = bezierPath.cgPath
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = 0.5
        self.view.layer.addSublayer(shapeLayer)
        shapeLayer.add(animation, forKey: "drawLineAnimation")
    }
    
    fileprivate func setupUITargetview() {
        targetView.layer.borderWidth = 2
        targetView.layer.borderColor = UIColor.white.cgColor
        targetView.layer.cornerRadius = 10
    }
    
    fileprivate func AuthorizationCheck() {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            configureCameraControllerQRCode()
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    self.configureCameraControllerQRCode()
                } else {
                    print("Access Denied")
                    //Show AlertController
                }
            })
        }
    }
    
}

extension QRScannerController : CameraControllerQRCodeDelegate{
    
    func qrCodefound(qrCodeValue: String, bounds: CGRect) {

        if targetView.frame.contains(bounds){
            
            DispatchQueue(label: "prepare").async {
                guard let captureSession = self.cameraControllerQRCode.captureSession else {
                    return
                }
                captureSession.stopRunning()
            }

            self.scaningline.removeFromSuperview()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            self.messageLabel.text = qrCodeValue
            
            performFoundAnimation(on: self.targetView)
            
            self.torchButton.isEnabled = false
            
        }
        
    }
}
    
    
    
    
    

