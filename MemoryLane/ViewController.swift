//
//  ViewController.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/5/20.
//

import UIKit
import AVFoundation

let WIDTH = UIScreen.main.bounds.width
let HEIGHT = UIScreen.main.bounds.height
class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureSession = AVCaptureSession()
    var frontCamera: AVCaptureDevice?
    let previewLayer = CALayer()
    let textlayer = CATextLayer()
    var shapeLayers = [CAShapeLayer]()
    var transform = CGAffineTransform.identity
    
    // Camera data frame data queue
    let queue = DispatchQueue(label: "com.camera.video.queue")
    
    // color picker point
    var pickers = [
        CGPoint(x: WIDTH/5, y: HEIGHT/7),
        CGPoint(x: WIDTH/5*2, y: HEIGHT/7),
        CGPoint(x: WIDTH/5*3, y: HEIGHT/7),
        CGPoint(x: WIDTH/5*4, y: HEIGHT/7),
    ]
    
    let buttons = ["Like", "Repeat", "Next", "Turn Off"]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.createUI()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first {
        let location = touch.location(in: self.view)
        print(location.x, location.y)
        print(self.pickers)
      }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
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
        
        guard let content = CGContext(data: baseAddr, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bimapInfo.rawValue) else {
            return
        }
        
        guard let cgImage = content.makeImage() else {
            return
        }
        
        DispatchQueue.main.async {
            self.previewLayer.contents = cgImage
            for (n, picker) in self.pickers.enumerated() {
                // Update the point after view transform
                let position = picker.applying(self.transform)
                if self.previewLayer.buttonPressed(at: position) {
                    self.shapeLayers[n].strokeColor = UIColor.green.cgColor
                    self.showToast(self.buttons[n] + " Button Pressed")
                } else {
                    self.shapeLayers[n].strokeColor = UIColor.red.cgColor
                }
            }
//            self.lineShape.strokeColor = color?.cgColor
        }
        
    }

    func getFrontCamera() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInDualCamera,
                                                for: AVMediaType.video,
                                                position: .front) {
            return device
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                            for: AVMediaType.video,
                            position: .front) {
            return device
        } else {
            return nil
        }
    }
    
    func setupUI() {
        previewLayer.bounds = CGRect(x: 0, y: 0, width: WIDTH, height: WIDTH)
        previewLayer.position = view.center
        previewLayer.contentsGravity = CALayerContentsGravity.resizeAspectFill
//        previewLayer.masksToBounds = true
        // rotate by 90 degree
        self.transform = self.transform.rotated(by: CGFloat(.pi / 2.0))
        // mirror view
        self.transform = self.transform.scaledBy(x: 1, y: -1)
        previewLayer.setAffineTransform(self.transform)
        view.layer.insertSublayer(previewLayer, at: 0)
        for point in self.pickers {
            let result = self.getIndicators(point: point)
            let circle = result.circle
            let dot = result.dot
            view.layer.addSublayer(circle)
            self.shapeLayers.append(circle)
            view.layer.addSublayer(dot)
        }
        
    }
    
    func getIndicators(point: CGPoint) -> (circle: CAShapeLayer, dot: CAShapeLayer) {
        // circle
        let circlePath = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: 40, height: 40))
        let lineShape = CAShapeLayer()
        lineShape.frame = CGRect.init(x: point.x-20, y:point.y-20, width: 40, height: 40)
        lineShape.lineWidth = 5
        lineShape.strokeColor = UIColor.red.cgColor
        lineShape.path = circlePath.cgPath
        lineShape.fillColor = UIColor.clear.cgColor
//        self.view.layer.addSublayer(lineShape)

        // dot
        let linePath1 = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: 8, height: 8))
        let lineShape1 = CAShapeLayer()
        lineShape1.frame = CGRect.init(x: point.x-4, y:point.y-4, width: 8, height: 8)
        lineShape1.path = linePath1.cgPath
        lineShape1.fillColor = UIColor.init(white: 0.7, alpha: 0.8).cgColor
//        self.view.layer.addSublayer(lineShape1)
        return (lineShape, lineShape1)
    }
    
    func createUI() {
        do {
            self.frontCamera = self.getFrontCamera()
            let captureDeviceInput = try AVCaptureDeviceInput(device: self.frontCamera!)
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: NSNumber(value: kCMPixelFormat_32BGRA)] as? [String : Any]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            
            if self.captureSession.canAddOutput(videoOutput) {
                self.captureSession.addOutput(videoOutput)
            }
            self.captureSession.addInput(captureDeviceInput)
        } catch {
            print(error)
            return
        }
        
        self.captureSession.startRunning()
    }
}


public extension CALayer {
    
    /// Get the specific color of given point
    ///
    /// - parameter at: point location
    ///
    /// - returns: Color
    func buttonPressed(at position: CGPoint) -> Bool {
        
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
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        return (brightness > 0.6)
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
    static let DELAY_SHORT = 0.1
    static let DELAY_LONG = 0.3

    func showToast(_ text: String, delay: TimeInterval = DELAY_LONG) {
        let label = ToastLabel()
        label.backgroundColor = UIColor(white: 0, alpha: 0.5)
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 35)
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
