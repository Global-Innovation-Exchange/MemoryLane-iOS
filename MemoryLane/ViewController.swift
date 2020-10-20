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
    @IBOutlet weak var instructionImageView: UIImageView!
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
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "soundName", withExtension: "mp3") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)

            /* iOS 10 and earlier require the following line:
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

            guard let player = player else { return }

            player.play()

        } catch let error {
            print(error.localizedDescription)
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
    // After iPad correctly placed, wait 1s to proceed
    let validateDelay = 1.0
    let updateInterval = 0.1
    var ipadValidated = false
    func iPadAngleValidation() {
        var timer = 0.0
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = updateInterval
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) {
                (data, error) in
                if let data = data {
                    let pitch = data.attitude.pitch * (180.0 / .pi)
                    // pitch angle range
                    if 66..<69 ~= pitch {
                        if timer.roundToDecimal(1) < self.validateDelay {
                            timer += self.updateInterval
                        } else if timer.roundToDecimal(1) == self.validateDelay {
                            if !self.ipadValidated {
                                self.ipadValidated = true
                                print("Placed correctly")
                                self.instructionTextLabel.text = "Attach Reflector"
                                self.reflectorValidation()
                            }
                        }
                    } else {
                        // reset timer
                        timer = 0.0
                        if self.ipadValidated {
                            self.ipadValidated = false
                            print("Place iPad on stand")
                            self.instructionTextLabel.text = "Place the iPad on the stand"
                            self.instructionImageView.image = nil
                            self.instructionImageView.center.y -= 40
                        }
                    }
                }
            }
        }
    }
    
    func reflectorValidation() {
        let reflectorImage = UIImage(named: "reflector.png")
        UIView.transition(with: self.instructionImageView,
                          duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: {
                              self.instructionImageView.image = reflectorImage
                          },
                          completion: nil)
        UIView.animate(withDuration: 2,
                       delay: 0.5,
                       options: .repeat,
                       animations: {
                            self.instructionImageView.center.y += 40
                       }, completion: nil)
    }
}

extension UIImage {
  func withAlphaComponent(_ alpha: CGFloat) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    defer { UIGraphicsEndImageContext() }

    draw(at: .zero, blendMode: .normal, alpha: alpha)
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}

extension Double {
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}

public extension CALayer {
    
    /// Get the specific color of given point
    ///
    /// - parameter at: point location
    ///
    /// - returns: Color
    func isLight(at position: CGPoint) -> Bool {
        // pixel of the given point
        var pixel = [UInt8](repeatElement(0, count: 4))
        // set the colorspace to RGB
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // set bitmap to RGBA
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return false
        }
        // translate the context point to each position
        context.translateBy(x: -position.x, y: -position.y)
//        context.rotate(by: CGFloat(.pi / 2.0))
        render(in: context)
        let color = UIColor(red: CGFloat(pixel[0]) / 255.0,
                            green: CGFloat(pixel[1]) / 255.0,
                            blue: CGFloat(pixel[2]) / 255.0,
                            alpha: CGFloat(pixel[3]) / 255.0)
        return color.isLight()
    }
}

public extension UIColor {
    func isLight() -> Bool {
        guard let components = cgColor.components, components.count > 2 else {return false}
        // w3.org/TR/AERT/#color-contrast
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
//        if brightness > 0.6 {
//            print(brightness)
//        }
        return (brightness > BRIGHTNESS_THRESHOLD)
    }
}

class ToastLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top, left: -textInsets.left, bottom: -textInsets.bottom, right: -textInsets.right)

        return textRect.inset(by: invertedInsets)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
}

extension UIViewController {
    static let DELAY_SHORT = 0.05
    static let DELAY_LONG = 0.05

    func showToast(_ text: String, delay: TimeInterval = DELAY_LONG) {
        let label = ToastLabel()
        label.backgroundColor = UIColor(white: 0, alpha: 0.5)
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 30)
        label.alpha = 0
        label.text = text
        label.clipsToBounds = true
        label.layer.cornerRadius = 20
        label.numberOfLines = 0
        label.textInsets = UIEdgeInsets(top: 15, left: 20, bottom: 15, right: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        let saveArea = view.safeAreaLayoutGuide
        label.centerXAnchor.constraint(equalTo: saveArea.centerXAnchor, constant: 0).isActive = true
        label.leadingAnchor.constraint(greaterThanOrEqualTo: saveArea.leadingAnchor, constant: 15).isActive = true
        label.trailingAnchor.constraint(lessThanOrEqualTo: saveArea.trailingAnchor, constant: -15).isActive = true
        label.bottomAnchor.constraint(equalTo: saveArea.bottomAnchor, constant: -30).isActive = true

        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
            label.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: delay, options: .curveEaseOut, animations: {
                label.alpha = 0
            }, completion: {_ in
                label.removeFromSuperview()
            })
        })
    }
}
