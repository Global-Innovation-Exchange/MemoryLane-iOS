//
//  ViewController.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/5/20.
//

import UIKit
import AVFoundation
import Vision
import CoreMotion
import CoreLocation
import Lottie

let WIDTH = UIScreen.main.bounds.width
let HEIGHT = UIScreen.main.bounds.height
let BRIGHTNESS_THRESHOLD: CGFloat = 0.5

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var headnotchImageView: UIImageView!
    @IBOutlet weak var instructionTextLabel: UILabel!
    @IBOutlet weak var subInstructionTextLabel: UILabel!
    @IBOutlet weak var reflectorImageView: UIImageView!
    @IBOutlet weak var boxImageView: UIImageView!
    @IBOutlet weak var iPadImageView: UIImageView!
    @IBOutlet weak var correctIconView: UIImageView!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var correctAnimationView: AnimationView!
    
    @IBOutlet weak var angleLabel: UILabel!
    
    private let captureSession = AVCaptureSession()
    lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    var totalFrameCount = 0
//    var shapeLayers = [CAShapeLayer]()
    
    // color picker point
    var pickers = [
        CGPoint(x: WIDTH/3*0+5, y: 60),
        CGPoint(x: WIDTH/3*1, y: 60),
        CGPoint(x: WIDTH/3*2, y: 60),
        CGPoint(x: WIDTH-5, y: 60),
    ]
    
    let buttonNames = ["Like", "Repeat", "Next", "Play/Pause"]
    let buttons = Buttons()
    // Global Bool for validation state
    var iPadValidated = false
    var reflectorValidated = false
    var allValidationPassed = false
    
    let themeObjects = ThemeObjects()
    var objectDetectionStart = false
    private var objectDetectionRequests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        // iPad Placement Validation -> reflector Validation
        self.iPadAngleValidation()
        // set up camera, camera feed, camera output
        self.setCameraInput()
        self.showCameraFeed()
        self.setCameraOutput()
        // Load ML model and prepare the request
        self.setupObjectDetection()
        // A notification will post after validation and introduction
        // Start object detection request once the notification is received
        NotificationCenter.default.addObserver(self, selector: #selector(handleObjectDetectionStart), name: Notification.Name("Object Detection Start"), object: nil)
    }
    
    @objc func handleObjectDetectionStart(_ notification: NSNotification) {
        // set this boolean so the object detection request will be performed in captureOutput function
        self.objectDetectionStart = true
        // remove this observer
        NotificationCenter.default.removeObserver(self, name: Notification.Name("Object Detection Start"), object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        self.previewLayer.frame = self.view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //session Start
        self.videoDataOutput.setSampleBufferDelegate(self,
                                                     queue:DispatchQueue(label:"camera_frame_processing_queue"))
        self.captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //session Stopped
//        self.videoDataOutput.setSampleBufferDelegate(nil, queue: nil)
//        self.captureSession.stopRunning()
    }
    
    //Set the captureSession!
    private func setCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera,
                              .builtInDualCamera,
                              .builtInTrueDepthCamera],
                mediaType: .video,
                position: .front).devices.first else {
            fatalError("No front camera device found.")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func showCameraFeed() {
        self.previewLayer.videoGravity = .resizeAspect
        // To show the camera preview, for debug usage
//        self.view.layer.addSublayer(self.previewLayer)
//        self.previewLayer.frame = self.view.frame
        self.previewLayer.frame = CGRect(x: 0, y: 0, width: 810, height: 150)
    }
    
    private func setCameraOutput() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
              connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    
    func captureOutput(_ output: AVCaptureOutput,didOutput sampleBuffer: CMSampleBuffer,from connection: AVCaptureConnection) {
        totalFrameCount += 1
//        if totalFrameCount % 3 != 0{ return }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        guard let baseAddr = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {
            return
        }
        let width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bimapInfo: CGBitmapInfo = [
            .byteOrder32Little,
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)]
        
        // get button area
        let startPos = 130 * bytesPerRow
        guard let buttonAreaContext = CGContext(data: baseAddr + startPos, width: width, height: 90, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bimapInfo.rawValue) else {
            return
        }
        guard let buttonAreaImage = buttonAreaContext.makeImage() else {
            return
        }
        
        guard let context = CGContext(data: baseAddr, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bimapInfo.rawValue) else {
            return
        }
        guard let areaImage = context.makeImage() else {
            return
        }
        
        if self.iPadValidated && !self.reflectorValidated {
            self.reflectorValidation(in: areaImage)
        }
        if self.iPadValidated && self.reflectorValidated {
            self.buttonDetection(in: buttonAreaImage)
//            self.lightingCalibration(in: buttonAreaImage)
        }
        if self.objectDetectionStart {
            // Object detection
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, options: [:])
            do {
                try imageRequestHandler.perform(self.objectDetectionRequests)
            } catch {
                print(error)
            }
        }
    }

    
    private func lightingCalibration(in image: CGImage) {
//        DispatchQueue.main.async {
//            print("Lighting Calibration")
//            print(image.isDark)
//        }
    }
    
    func buttonDetection(in image: CGImage) {
        DispatchQueue.main.async {
            self.previewLayer.contents = image
            for (n, picker) in self.pickers.enumerated() {
                if self.previewLayer.isLight(at: picker) {
                    self.buttons.press(i: 3-n)
                } else {
                    self.buttons.release(i: 3-n)
                }
            }
            if self.buttons.allPressed() {
                // only execute following statement once after four button pressed
                if !self.allValidationPassed {
                    self.allValidationPassed = true
                    // update instruction label
                    self.instructionTextLabel.text = "Session will start shortly"
                    self.subInstructionTextLabel.text = ""
                    Helper.speak(text: self.instructionTextLabel.text!)
                    // stop ipad angle detection
                    self.motionManager.stopDeviceMotionUpdates()
                    self.showCorrectAnimation(time: 0.5)
                    self.switchScreen()
                }
                self.showToast("Setup Completed!")
            }
        }
    }
    
    
    private func switchScreen() {
        let delayTime = DispatchTime.now() + 1.7
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let vc = mainStoryboard.instantiateViewController(withIdentifier: String(describing: IntroViewController.self)) as? IntroViewController {
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            }
        })
    }
    
    
    // MotionManager
    let motionManager = CMMotionManager()
    
    func iPadAngleValidation() {
        UIView.animate(withDuration: 2,
                       delay: 0.5,
                       options: .repeat,
                       animations: {
                            self.iPadImageView.center.y += 80
                       }, completion: nil)
        Helper.speak(text: self.instructionTextLabel.text!)
        
        // After iPad correctly placed, wait 1s to proceed
        let validateDelay = 1.0
        let updateInterval = 0.1
        
        var timer = 0.0
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = updateInterval
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) {
                (data, error) in
                if let data = data {
                    let pitch = data.attitude.pitch * (180.0 / .pi)
                    self.angleLabel.text = String(format: "%.1f°", pitch)
                    // pitch angle range
                    if 72..<76 ~= pitch {
                        if timer.roundToDecimal(1) < validateDelay {
                            timer += updateInterval
                        } else if timer.roundToDecimal(1) == validateDelay {
                            if !self.iPadValidated {
                                self.iPadValidated = true
                                self.instructionTextLabel.text = "iPad placed correctly"
                                self.iPadImageView.layer.removeAllAnimations()
                                self.showCorrectAnimation(time: 0.5)
                                self.perform(#selector(self.showReflectorAnimation), with: nil, afterDelay: 1.5)
                            }
                        }
                    } else {
                        // reset timer
                        timer = 0.0
                        self.reflectorValidated = false
                        self.reflectorValidationTimer = 0
                        if self.iPadValidated {
                            self.iPadValidated = false
                            print("Place iPad on stand")
                            self.instructionTextLabel.text = "Place the iPad on the stand"
                            Helper.speak(text: self.instructionTextLabel.text!)
                            self.fadeImage(view: self.reflectorImageView, time: 0.5, alpha: 0)
                            self.reflectorImageView.center.y -= 40
                            self.correctAnimationView.isHidden = true
                            Helper.updateImage(view: self.boxImageView, image: UIImage(named: "box")!, time: 0.5)
                            self.fadeImage(view: self.iPadImageView, time: 0.5, alpha: 1.0)
                            self.fadeImage(view: self.boxImageView, time: 0.5, alpha: 1.0)
                            self.fadeImage(view: self.arrowImageView, time: 0.5, alpha: 0.0)
                            self.iPadImageView.center.y -= 80
                            self.arrowImageView.center.y -= 40
                            self.subInstructionTextLabel.text = ""
                            UIView.animate(withDuration: 2,
                                           delay: 0.5,
                                           options: .repeat,
                                           animations: {
                                                self.iPadImageView.center.y += 80
                                           }, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    @objc func showReflectorAnimation() {
//        self.fadeImage(view: self.correctIconView, time: 0.5, alpha: 0.0)
        self.correctAnimationView.isHidden = true
        self.fadeImage(view: self.iPadImageView, time: 0.5, alpha: 1.0)
        self.fadeImage(view: self.boxImageView, time: 0.5, alpha: 1.0)
        self.fadeImage(view: self.reflectorImageView, time: 0.5, alpha: 1.0)
        self.instructionTextLabel.text = "Put the reflector all the way in"
        Helper.speak(text: self.instructionTextLabel.text!)
        UIView.animate(withDuration: 2,
                       delay: 0.5,
                       options: .repeat,
                       animations: {
                            self.reflectorImageView.center.y += 40
                       }, completion: nil)
    }
    
    @objc func showButtonAnimation() {
//        self.fadeImage(view: self.correctIconView, time: 0.5, alpha: 0.0)
        self.correctAnimationView.isHidden = true
        self.fadeImage(view: self.iPadImageView, time: 0.5, alpha: 0.0)
        self.fadeImage(view: self.boxImageView, time: 0.5, alpha: 1.0)
        self.fadeImage(view: self.reflectorImageView, time: 0.5, alpha: 0.0)
        self.fadeImage(view: self.arrowImageView, time: 0.5, alpha: 1.0)
        Helper.updateImage(view: self.boxImageView, image: UIImage(named: "box1")!, time: 0.5)
//        self.instructionTextLabel.text = "Do you have Memory Lane item ready in the drawer?"
        self.instructionTextLabel.text = "Press all buttons on the box at once when you are ready to start a session"
        Helper.speak(text: self.instructionTextLabel.text!)
        UIView.animate(withDuration: 2,
                       delay: 0.5,
                       options: [.repeat, .autoreverse],
                       animations: {
                            self.arrowImageView.center.y += 40
                       }, completion: nil)
    }
    
    var validationDelay = 60
    var reflectorValidationTimer = 0
    private func reflectorValidation(in image: CGImage) {
//        print("slot detection")
        let request = VNDetectRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                guard let results = request.results as? [VNRectangleObservation] else {
                    self.reflectorValidated = false
                    return
                }

                guard let rect = results.first else{
                    self.reflectorValidated = false
                    return
                }
                // detected full slot rectangle
                if rect.topRight.x - rect.topLeft.x > CGFloat(0.95) {
                    if self.reflectorValidationTimer < self.validationDelay {
                        self.reflectorValidationTimer += 1
                    } else if self.reflectorValidationTimer == self.validationDelay {
                        if !self.reflectorValidated {
                            self.reflectorValidated = true
                            self.instructionTextLabel.text = "Reflector placed correctly"
                            self.reflectorImageView.layer.removeAllAnimations()
                            self.showCorrectAnimation(time: 0.5)
                            self.perform(#selector(self.showButtonAnimation), with: nil, afterDelay: 1.5)
                        }
                    }
                } else {
                    self.reflectorValidationTimer = 0
                    if self.reflectorValidated {
                        self.reflectorValidated = false
                        self.showReflectorAnimation()
                    }
                }
//                print(self.reflectorValidationTimer)
            }
        })
        request.minimumAspectRatio = VNAspectRatio(0.0)
        request.maximumAspectRatio = VNAspectRatio(0.1)
        request.minimumConfidence = Float(0.9)
        request.quadratureTolerance = Float(1)
        request.minimumSize = Float(0.0)
        request.maximumObservations = 1

        
        let imageRequestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        try? imageRequestHandler.perform([request])
    }
    
    // Object Detection Vision
    @discardableResult
    func setupObjectDetection() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "Memory Lane 1", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    if let results = request.results {
                        self.handleObjectDetectionRequestResults(results)
                    }
                })
            })
            self.objectDetectionRequests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }


    func handleObjectDetectionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        if results.isEmpty {
            self.themeObjects.detect(objectName: "")
        }
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            self.themeObjects.detect(objectName: topLabelObservation.identifier)
        }
//        super.updateNowPlayingLabel(text: "no idea")
        CATransaction.commit()
    }
    
    
    func showCorrectAnimation(time: Double) {
        // fade all image views
        Helper.playSound(filename: "CorrectSound")
        for subview in self.view.subviews
        {
            if let item = subview as? UIImageView
            {
                if item != self.headnotchImageView {
                    self.fadeImage(view: item, time: time, alpha: 0.0)
                }
            }
        }
        // show correct icon imageview
        self.correctAnimationView.isHidden = false
        self.correctAnimationView.animation = Animation.named("CheckAnimation")
        correctAnimationView.play()
    }
    
    func fadeImage(view: UIImageView, time: Double, alpha: CGFloat) {
        UIView.animate(withDuration: time, delay: 0, options: .curveEaseOut, animations: {
            view.alpha = alpha
        }, completion: nil)
    }
}
