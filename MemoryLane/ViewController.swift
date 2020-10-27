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

let WIDTH = UIScreen.main.bounds.width
let HEIGHT = UIScreen.main.bounds.height
let BRIGHTNESS_THRESHOLD: CGFloat = 0.5

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var instructionTextLabel: UILabel!
    @IBOutlet weak var subInstructionTextLabel: UILabel!
    @IBOutlet weak var reflectorImageView: UIImageView!
    @IBOutlet weak var boxImageView: UIImageView!
    @IBOutlet weak var iPadImageView: UIImageView!
    @IBOutlet weak var correctIconView: UIImageView!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var angleLabel: UILabel!
    
    private let captureSession = AVCaptureSession()
    lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    var totalFrameCount = 0
//    var shapeLayers = [CAShapeLayer]()
    var player: AVAudioPlayer?
    // color picker point
    var pickers = [
        CGPoint(x: WIDTH/3*0+5, y: 60),
        CGPoint(x: WIDTH/3*1, y: 60),
        CGPoint(x: WIDTH/3*2, y: 60),
        CGPoint(x: WIDTH-5, y: 60),
    ]
    let speechSynthesizer = AVSpeechSynthesizer()
    
    let buttonNames = ["Like", "Repeat", "Next", "Play/Pause"]
    let buttons = Buttons()
    // Global Bool for validation state
    var iPadValidated = false
    var reflectorValidated = false
//    static var buttonPressed = [Bool](repeating: false, count: 4)
    var allValidationPassed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
//        ViewController.buttonPressed = [Bool](repeating: false, count: 4)
        self.iPadAngleValidation()
        // set up camera, camera feed, camera output
        self.setCameraInput()
        self.showCameraFeed()
//        self.drawButtons(n: 4)
        self.setCameraOutput()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        ViewController.buttonPressed = [Bool](repeating: false, count: 4)
//    }
//
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
//
//        // get object scan area
//        guard let objectAreaContext = CGContext(data: baseAddr + startPos + 90, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bimapInfo.rawValue) else {
//            return
//        }
//        guard let objectAreaImage = objectAreaContext.makeImage() else {
//            return
//        }
        
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
                    self.showToast(self.buttonNames[3-n] + " Button Pressed")
//                    ViewController.buttonPressed[3-n] = true
//                    if ViewController.buttonPressed.filter({$0}).count == 1 {
//                        self.showToast(self.buttonNames[3-n] + " Button Pressed")
//                    }
                } else {
//                    ViewController.buttonPressed[3-n] = false
                    self.buttons.release(i: 3-n)
                }
            }
//            print(self.buttonPressed)
//            if ViewController.buttonPressed.allSatisfy({$0}) {
            if self.buttons.allPressed() {
                // only execute following statement once after four button pressed
                if !self.allValidationPassed {
                    self.allValidationPassed = true
                    print("all button pressed")
                    // update instruction label
                    self.instructionTextLabel.text = "Session will start shortly"
                    self.subInstructionTextLabel.text = ""
                    self.speak(text: self.instructionTextLabel.text!)
                    // stop ipad angle detection
                    self.motionManager.stopDeviceMotionUpdates()
                    self.showCorrectAnimation(time: 0.5)
                    self.switchScreen()
                }
                self.showToast("Setup Completed!")
            }
        }
    }
    
//    private func drawButtons(n: Int) {
//        for i in 0...n-1 {
//            let circlePath = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: 95, height: 95))
//            let lineShape = CAShapeLayer()
//            lineShape.frame = CGRect.init(x: 140*(i+1), y:Int(HEIGHT)/9*7-5, width: 95, height: 95)
////            lineShape.lineWidth = 1
////            lineShape.strokeColor = self.buttonColors[i].cgColor
//            lineShape.path = circlePath.cgPath
//            lineShape.fillColor = UIColor.clear.cgColor
//            view.layer.addSublayer(lineShape)
//            self.shapeLayers.append(lineShape)
//        }
//    }
    
    func playSound(){
        guard let url = Bundle.main.url(forResource: "CorrectSound", withExtension: "mp3") else {
            print("Sound file is missing")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)

            /* iOS 10 and earlier require the following line:
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

            guard let player = player else {
                print("Player is missing")
                return
            }
            player.play()
            
        } catch let err {
            print(err)
            return
        }
    }
    
    private func switchScreen() {
        let delayTime = DispatchTime.now() + 1.0
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let vc = mainStoryboard.instantiateViewController(withIdentifier: "Intro") as? IntroViewController {
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
        self.speak(text: self.instructionTextLabel.text!)
        
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
                    if 73..<76 ~= pitch {
                        if timer.roundToDecimal(1) < validateDelay {
                            timer += updateInterval
                        } else if timer.roundToDecimal(1) == validateDelay {
                            if !self.iPadValidated {
                                self.iPadValidated = true
                                self.instructionTextLabel.text = "iPad placed correctly"
                                self.playSound()
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
                            self.speak(text: self.instructionTextLabel.text!)
                            self.fadeImage(view: self.reflectorImageView, time: 0.5, alpha: 0)
                            self.reflectorImageView.center.y -= 40
                            self.fadeImage(view: self.correctIconView, time: 0.5, alpha: 0.0)
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
        self.fadeImage(view: self.correctIconView, time: 0.5, alpha: 0.0)
        self.fadeImage(view: self.iPadImageView, time: 0.5, alpha: 1.0)
        self.fadeImage(view: self.boxImageView, time: 0.5, alpha: 1.0)
        self.fadeImage(view: self.reflectorImageView, time: 0.5, alpha: 1.0)
        self.instructionTextLabel.text = "Put the reflector all the way in"
        self.speak(text: self.instructionTextLabel.text!)
        UIView.animate(withDuration: 2,
                       delay: 0.5,
                       options: .repeat,
                       animations: {
                            self.reflectorImageView.center.y += 40
                       }, completion: nil)
    }
    
    @objc func showButtonAnimation() {
        self.fadeImage(view: self.correctIconView, time: 0.5, alpha: 0.0)
        self.fadeImage(view: self.iPadImageView, time: 0.5, alpha: 1.0)
        self.fadeImage(view: self.boxImageView, time: 0.5, alpha: 1.0)
        self.fadeImage(view: self.reflectorImageView, time: 0.5, alpha: 1.0)
        self.fadeImage(view: self.arrowImageView, time: 0.5, alpha: 1.0)
        self.instructionTextLabel.text = "Do you have Memory Lane item ready in the drawer?"
        self.subInstructionTextLabel.text = "Press all buttons on the box at once when you are ready to start a session"
        self.speak(text: self.instructionTextLabel.text!)
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
                guard let results = request.results as? [VNRectangleObservation] else { return }

                guard let rect = results.first else{
                    self.reflectorValidated = false
                    return
                }
                if rect.topRight.x - rect.topLeft.x > CGFloat(0.95) {
                    if self.reflectorValidationTimer < self.validationDelay {
                        self.reflectorValidationTimer += 1
                    } else if self.reflectorValidationTimer == self.validationDelay {
                        if !self.reflectorValidated {
                            self.reflectorValidated = true
                            self.instructionTextLabel.text = "Reflector placed correctly"
                            self.playSound()
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
    
    func updateImage(view: UIImageView, image: UIImage, time: Double) {
        UIView.transition(with: view,
                          duration: time,
                          options: .transitionCrossDissolve,
                          animations: {
                              view.image = image
                          },
                          completion: nil)
    }
    
    func showCorrectAnimation(time: Double) {
        // fade all image views
        for subview in self.view.subviews
        {
            if let item = subview as? UIImageView
            {
                self.fadeImage(view: item, time: time, alpha: 0.0)
            }
        }
        // show correct icon imageview
        self.fadeImage(view: self.correctIconView, time: time, alpha: 1.0)
    }
    
    func fadeImage(view: UIImageView, time: Double, alpha: CGFloat) {
        UIView.animate(withDuration: time, delay: 0, options: .curveEaseOut, animations: {
            view.alpha = alpha
        }, completion: nil)
    }
    
    func speak(text: String) {
        let speechUtterance = AVSpeechUtterance(string: self.instructionTextLabel.text!)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
//        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 2.5
        speechUtterance.pitchMultiplier = 0.8
        self.speechSynthesizer.speak(speechUtterance)
        
    }
}
