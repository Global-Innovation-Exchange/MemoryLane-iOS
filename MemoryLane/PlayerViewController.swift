//
//  MusicViewController.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/28/20.
//

import UIKit
import AVFoundation
import AVKit
import Lottie


class PlayerViewController: UIViewController {

    @IBOutlet weak var animationContainer: UIView!
    @IBOutlet weak var animationView: AnimationView!
    @IBOutlet weak var animationTitle: UILabel!
    @IBOutlet weak var mediaTitle: UITextField!
    @IBOutlet weak var promptQ: UITextField!
    @IBOutlet weak var medstatus: UITextField!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var thumbnailView: UIImageView!
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var animationName: String?
        
    
    var mediaType: String!
    //track if media playing
    var isPlaying: Bool = true
    
    //to disable pause/ play if media ended.
    var ended: Bool = false
    // will be used for next media playing
    var currentMediaIndex: Int = 0
    
    //--------- this is the struct of urls, questions and titles -------//
    struct Music: Codable {
        let track_name: String
        let mediaUrl: String
        let imageUrl: String
        let prompt: String
    }
    
    struct Video: Codable {
        let title: String
        let mediaUrl: String
        let imageUrl: String
        let prompt: String
    }
    
    struct Media {
        let title: String
        let url: String
        let thumbnail: String
        let prompt: String
    }
    
    var mediaList: [String] = []
    var numofMedia: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numofMedia = mediaList.count
        isPlaying = true
        ended = false
        currentMediaIndex = 0
        // lable on top of media player
        medstatus.layer.zPosition = 1
        animationContainer.layer.zPosition = 2
        playMedia()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showAnimation(animationName: animationName!)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNoObjectDetected), name: Notification.Name("No Object Detected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleButtonPressed), name: Notification.Name("Button Pressed"), object: nil)
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("No Object Detected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("Button Pressed"), object: nil)
        self.removeVideoEndObserver()
        dismissPlayer()
        currentMediaIndex = 0
    }
    
    public func fetchMedia(type: String, id: String, mediaCompletionHandler: @escaping (Media?, Error?) -> Void){
        let baseURL = "https://us-central1-memory-lane-954c7.cloudfunctions.net"
        let endpoint = "/getMedia?type=\(type)&id=\(id)"
        let url = URL(string: baseURL + endpoint)
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if error != nil || data == nil {
                print("Client error!")
                return
            }
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Server error!")
                return
            }
            guard let mime = response.mimeType, mime == "application/json" else {
                print("Wrong MIME type!")
                return
            }
            do {
                let jsonDecoder = JSONDecoder()
                var title: String = ""
                var url: String = ""
                var thumbnail: String = ""
                var prompt: String = ""
                if type == "music" {
                    let parsedJSON = try jsonDecoder.decode(Music.self, from: data!)
                    title = parsedJSON.track_name
                    url = parsedJSON.mediaUrl
                    thumbnail = parsedJSON.imageUrl
                    prompt = parsedJSON.prompt
                } else if type == "video" {
                    let parsedJSON = try jsonDecoder.decode(Video.self, from: data!)
                    title = parsedJSON.title
                    url = parsedJSON.mediaUrl
                    thumbnail = parsedJSON.imageUrl
                    prompt = parsedJSON.prompt
                }
                mediaCompletionHandler(Media(title: title, url: url, thumbnail: thumbnail, prompt: prompt), nil)
            } catch let parseErr {
                print("JSON error: \(parseErr.localizedDescription), ID: \(id)")
                mediaCompletionHandler(nil, parseErr)
                
            }
        })
        task.resume()
    }
    
    //preparing media screen contents and layers
    func playMedia(){
        // handle the case where the media list is empty
        if currentMediaIndex < numofMedia {
            self.fetchMedia(type: mediaType, id: mediaList[currentMediaIndex], mediaCompletionHandler: { media, error in
                if let thismedia = media {
                    DispatchQueue.main.async { [self] in
                        let url = URL(string: thismedia.url)
                        self.mediaTitle.text = thismedia.title
                        self.mediaTitle.adjustsFontSizeToFitWidth = true
                        self.promptQ.text = thismedia.prompt
                        self.dismissPlayer()
                        self.player = AVPlayer(url: url!)
                        self.playerLayer = AVPlayerLayer(player: player)
                        self.playerLayer.videoGravity = .resizeAspect
                        self.playerLayer.frame = videoView.bounds
                        if self.mediaType == "music" {
                            let thumbnailURL = URL(string: thismedia.thumbnail)
                            let thumbnail = try? Data(contentsOf: thumbnailURL!)
                            thumbnailView.image = UIImage(data: thumbnail!)
                            self.thumbnailView.isHidden = false
                        } else {
                            self.thumbnailView.isHidden = true
                        }

                        self.videoView.layer.addSublayer(playerLayer)
                        self.player.play()
                        self.isPlaying = true
                        self.addVideoEndObserver()
                    }
                }
            })
        } else {
            self.mediaTitle.text = "No content was found"
        }
    }
    
    @objc func handleNoObjectDetected (_ notification: NSNotification) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func dismissPlayer() {
        if player != nil {
            player.pause()
        }
        player = nil
    }
    
    // track video "left" duration
    fileprivate var videoEndObserver: Any?

    
    func addVideoEndObserver() {
        guard let player = player else { return }

        // This code only when viewing from  URL.
        guard let duration = player.currentItem?.duration, duration.value != 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
                self?.addVideoEndObserver()
            })

            return
        }
        
        // "catch" the end of the video
        let promteTime = NSValue(time: duration - CMTimeMakeWithSeconds( 0.5, preferredTimescale: duration.timescale))
        videoEndObserver = player.addBoundaryTimeObserver(forTimes: [promteTime], queue: .main, using: {
            self.medstatus.text = "THE END"
            self.medstatus.isHidden = false
            self.ended = true
            
        })
        
        // catch when 10s left and show the prompt Q
        let endTime = NSValue(time: duration - CMTimeMakeWithSeconds( 10.0, preferredTimescale: duration.timescale))
        videoEndObserver = player.addBoundaryTimeObserver(forTimes: [endTime], queue: .main, using: {
            self.removeVideoEndObserver()
            self.promptQ.isHidden = false
        })
        
    }
    
    // stop observation
    func removeVideoEndObserver() {
        guard let observer = videoEndObserver else { return }
        player?.removeTimeObserver(observer)
        videoEndObserver = nil
    }
    
    func showAnimation(animationName: String) {
        switch animationName as String {
        case "CassetteAnimation":
            animationTitle.text = "Music!"
        case "TVAnimation":
            animationTitle.text = "Video!"
        case "NextAnimation":
            animationTitle.text = "Next"
        case "LikeAnimation":
            animationTitle.text = "Yay! you like this one. That’s helpful to know!"
        default:
            animationTitle.text = "Great Choice!"
            
        }
        // only show animation when animation is hidden
        // this is to prevent user press button repeatly during animation playing
        if animationContainer.isHidden {
            animationContainer.isHidden = false
            animationView.animation = Animation.named(animationName)
            animationView.play {
                (finished) in
                self.animationContainer.isHidden = true
            }
        }
    }
    
    @objc func handleButtonPressed (_ notification: NSNotification) {
        switch notification.object as! Int {
        case 0:
            // Like
            showAnimation(animationName: "LikeAnimation")
        case 1:
            // Repeat
//            player.seek(to: .zero)
            medstatus.isHidden = true
            removeVideoEndObserver()
            promptQ.isHidden = true
            ended = false
            dismissPlayer()
            playMedia()
        case 2:
            // Next
            currentMediaIndex += 1
            if currentMediaIndex < numofMedia {
                showAnimation(animationName: "NextAnimation")
                self.promptQ.isHidden = true
                removeVideoEndObserver()
                dismissPlayer()
                isPlaying = true
                medstatus.isHidden = true
                playMedia()
            } else {
                currentMediaIndex -= 1
                medstatus.text = "No more media is available right now"
                player.pause()
                isPlaying = false
                medstatus.isHidden = false
            }
        case 3:
            if !ended && player != nil{
                // Play and Pause
                if isPlaying {
                    player.pause()
                    //sender.setTitle("play", for: .normal)
                    isPlaying = false
                    medstatus.text = "Paused"
                    medstatus.isHidden = false
                }
                else {
                    player.play()
                    //sender.setTitle("pause", for: .normal)
                    isPlaying = true
                    medstatus.isHidden = true
                }
            }
        default:
            print("Button Press Error")
        }
    }
}
