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
    @IBOutlet weak var reflectorImageView: UIImageView!
    @IBOutlet weak var iPadImageView: UIImageView!
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    var totalFrameCount = 0
    var shapeLayers = [CAShapeLayer]()
    var player: AVAudioPlayer?
    var buttonPressed = [Bool](repeating: false, count: 4)
    // color picker point
    var pickers = [
        CGPoint(x: WIDTH/3*0+5, y: 60),
        CGPoint(x: WIDTH/3*1, y: 60),
        CGPoint(x: WIDTH/3*2, y: 60),
        CGPoint(x: WIDTH-5, y: 60),
    ]
    let speechSynthesizer = AVSpeechSynthesizer()
    
    let buttonColors = [UIColor.green, UIColor.red, UIColor.yellow, UIColor.blue]
    let buttonNames = ["Like", "Repeat", "Next", "Play/Pause"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.buttonPressed = [Bool](repeating: false, count: 4)
        self.view.backgroundColor = UIColor.white
        self.iPadAngleValidation()
        // set up camera, camera feed, camera output
        self.setCameraInput()
        self.showCameraFeed()
        self.drawButtons(n: 4)
        self.setCameraOutput()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.buttonPressed = [Bool](repeating: false, count: 4)
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
        self.videoDataOutput.setSampleBufferDelegate(nil, queue: nil)
        self.captureSession.stopRunning()
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
        self.view.layer.addSublayer(self.previewLayer)
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
//        let height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bimapInfo: CGBitmapInfo = [
            .byteOrder32Little,
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)]
        let startPos = 130 * bytesPerRow
        guard let buttonAreaContext = CGContext(data: baseAddr + startPos, width: width, height: 80, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bimapInfo.rawValue) else {
            return
        }
        
        guard let buttonImage = buttonAreaContext.makeImage() else {
            return
        }
        if self.ipadValidated {
            self.detectRectangleByBrightness(in: buttonImage)
        }
    }
    
    private var bBoxLayer = CAShapeLayer()
    
    private func detectRectangleByBrightness(in image: CGImage) {
        DispatchQueue.main.async {
            self.previewLayer.contents = image
            for (n, picker) in self.pickers.enumerated() {
                // Update the point after transformation
//                let position = picker.applying(self.transform)
                if self.previewLayer.isLight(at: picker) {
//                    if !ViewController.buttonPressed {
                    self.shapeLayers[3-n].fillColor = self.buttonColors[3-n].cgColor
                    self.buttonPressed[3-n] = true
                    if self.buttonPressed.filter({$0}).count == 1 {
                        self.showToast(self.buttonNames[3-n] + " Button Pressed")
                    }
//                        print("Button Pressed")
//                        print(3-n, picker)
//                        print(ViewController.buttonPressed)
//                        ViewController.buttonPressed = true
//                    }
                } else {
                    self.shapeLayers[3-n].fillColor = UIColor.clear.cgColor
                    self.buttonPressed[3-n] = false
//                    ViewController.buttonPressed = false
                }
            }
            if self.buttonPressed.allSatisfy({$0}) {
                self.showToast("Setup Completed!")
//                self.switchScreen()
                
//                _ = self.switchScreen
            }
        }
    }
    
    private func drawButtons(n: Int) {
        for i in 0...n-1 {
            let circlePath = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: 95, height: 95))
            let lineShape = CAShapeLayer()
            lineShape.frame = CGRect.init(x: 140*(i+1), y:Int(HEIGHT)/9*7-5, width: 95, height: 95)
            lineShape.lineWidth = 5
            lineShape.strokeColor = self.buttonColors[i].cgColor
            lineShape.path = circlePath.cgPath
            lineShape.fillColor = UIColor.clear.cgColor
            view.layer.addSublayer(lineShape)
            self.shapeLayers.append(lineShape)
        }
    }
    
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
            if let vc = mainStoryboard.instantiateViewController(withIdentifier: "ObjectScan") as? UIViewController {
                self.present(vc, animated: true, completion: nil)
            }
        })
    }
    
    
    // MotionManager
    let motionManager = CMMotionManager()
    var ipadValidated = false
    
    func iPadAngleValidation() {
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
                    // pitch angle range
                    if 66..<69 ~= pitch {
                        if timer.roundToDecimal(1) < validateDelay {
                            timer += updateInterval
                        } else if timer.roundToDecimal(1) == validateDelay {
                            if !self.ipadValidated {
                                self.ipadValidated = true
                                self.playSound()
                                self.iPadImageView.image = UIImage(named: "CorrectIcon.png")
                                self.perform(#selector(self.reflectorValidation), with: nil, afterDelay: 1.0)
                            }
                        }
                    } else {
                        // reset timer
                        timer = 0.0
                        if self.ipadValidated {
                            self.ipadValidated = false
                            print("Place iPad on stand")
                            self.instructionTextLabel.text = "Place the iPad on the stand"
                            self.reflectorImageView.image = nil
                            self.reflectorImageView.center.y -= 40
                            self.speak(text: self.instructionTextLabel.text!)
                        }
                    }
                }
            }
        }
    }
    
    @objc func reflectorValidation() {
        let reflectorImage = UIImage(named: "reflector.png")
        self.iPadImageView.image = UIImage(named: "placeiPad.png")
        self.instructionTextLabel.text = "Then attach the black reflector"
        self.speak(text: self.instructionTextLabel.text!)
        UIView.transition(with: self.reflectorImageView,
                          duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: {
                              self.reflectorImageView.image = reflectorImage
                          },
                          completion: nil)
        UIView.animate(withDuration: 2,
                       delay: 0.5,
                       options: .repeat,
                       animations: {
                            self.reflectorImageView.center.y += 40
                       }, completion: nil)
    }
    
    func speak(text: String) {
        let speechUtterance = AVSpeechUtterance(string: self.instructionTextLabel.text!)
//        speechUtterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 2.5
        speechUtterance.pitchMultiplier = 1.2
        self.speechSynthesizer.speak(speechUtterance)
        
    }
}

//class Label: UILabel {
//    var speechSynthesizer = AVSpeechSynthesizer()
//    var speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: "Please follow the instruction to setup the device")
//
//    override var text: String? {
//        didSet {
//            if let text = text {
//                if oldValue != text {
//                    speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 2.0
//                    speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
//                    speechUtterance = AVSpeechUtterance(string: text)
//                    speechSynthesizer.speak(speechUtterance)
//                }
//            }
//        }
//    }
//}
