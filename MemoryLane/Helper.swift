//
//  Helper.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/27/20.
//

import Foundation
import AVFoundation
import UIKit

class Helper{
    static var player: AVAudioPlayer?
    
    static func playSound(filename: String){
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
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
    
    static func updateImage(view: UIImageView, image: UIImage, time: Double) {
        UIView.transition(with: view,
                          duration: time,
                          options: .transitionCrossDissolve,
                          animations: {
                              view.image = image
                          },
                          completion: nil)
    }
    
    static let speechSynthesizer = AVSpeechSynthesizer()
    
    static func speak(text: String) {
        stopSpeaking()
        let speechUtterance = AVSpeechUtterance(string: text)
//        speechUtterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 2.4
        speechUtterance.pitchMultiplier = 1.2
        speechSynthesizer.speak(speechUtterance)
    }
    
    static func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
}
