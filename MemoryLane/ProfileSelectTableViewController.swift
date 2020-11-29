//
//  ProfileSelectViewController.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/27/20.
//

import UIKit
import FoldingCell

class ProfileSelectTableViewController: UITableViewController, ProfileCellDelegate {
    
    @IBOutlet weak var instructionTextLabel: UILabel!
    
    struct Profiles: Codable {
        let profiles: [Profile]
    }
    
    struct Profile: Codable {
        let user_id: String?
        let profile: ProfileInfo
    }
    
    struct ProfileInfo: Codable {
        let name, gender, location, occupation: String?
        let age: Int?
        let prefered_genre: [String]?
    }
    
    enum Const {
        static let closeCellHeight: CGFloat = 100
        static let openCellHeight: CGFloat = 488
        static let rowsCount = 3
    }
    var cellHeights: [CGFloat] = []
    var profiles = [Profile]()
    
    var internetConnected = false
    let caregiverId = "memorylane"
    let baseURL = "https://us-central1-memory-lane-954c7.cloudfunctions.net"
     
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchProfiles(profilesCompletionHandler: { profileList, error in
          if let profileList = profileList {
            DispatchQueue.main.async() {
                self.instructionTextLabel.text = "Please select a profile"
//                print(profileList.profiles)
                self.profiles = profileList.profiles
                self.tableView.reloadData()
            }
          }
        })
        setup()
    }
    
    // MARK: Helpers
    private func setup() {
        cellHeights = Array(repeating: Const.closeCellHeight, count: Const.rowsCount)
        tableView.estimatedRowHeight = Const.closeCellHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = UIColor(red: 0.9765, green: 0.9765, blue: 0.9765, alpha: 1.0)
        if #available(iOS 10.0, *) {
            tableView.refreshControl = UIRefreshControl()
            tableView.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
        }
    }
    
    // MARK: Actions
    @objc func refreshHandler() {
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if #available(iOS 10.0, *) {
                self?.tableView.refreshControl?.endRefreshing()
            }
            self?.tableView.reloadData()
        })
    }
    
    private func checkInternetConnection() {
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
            self.internetConnected = true
        }else{
            self.instructionTextLabel.text = "Internet Connection not Available!"
//            self.subInstructionTextLabel.text = "Memory Lane App cannot work without Internet connection"
            self.internetConnected = false
            print("Internet Connection not Available!")
        }
    }
    
    func fetchProfiles(profilesCompletionHandler: @escaping (Profiles?, Error?) -> Void){
        let endpoint = "/showProfiles?id=\(caregiverId)"
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
                let parsedJSON = try jsonDecoder.decode(Profiles.self, from: data!)
                profilesCompletionHandler(parsedJSON, nil)
            } catch let parseErr {
                print("JSON error: \(parseErr.localizedDescription)")
                print(parseErr)
                profilesCompletionHandler(nil, parseErr)
            }
        })
        task.resume()
    }
    
    func switchScreen() {
        let delayTime = DispatchTime.now() + 0.0
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let vc = mainStoryboard.instantiateViewController(withIdentifier: "SetupViewController") as? SetupViewController {
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            }
        })
    }
}

// MARK: - TableView

extension ProfileSelectTableViewController {

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return self.profiles.count
    }

    override func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case let cell as ProfileCell = cell else {
            return
        }

        cell.backgroundColor = .clear
        cell.delegate = self

        if cellHeights[indexPath.row] == Const.closeCellHeight {
            cell.unfold(false, animated: false, completion: nil)
        } else {
            cell.unfold(true, animated: false, completion: nil)
        }

        cell.number = indexPath.row + 1
        if self.profiles.count > 0 {
            let p = self.profiles[indexPath.row].profile
            cell.userId = p.name ?? "test"
            cell.occupation = p.occupation ?? "Teacher"
            cell.location = p.location ?? "Bellevue, WA"
//            print("\(p.gender ?? "Male"), \(p.age ?? 75) years old")
            cell.subInfo = "\(p.gender ?? "Male"), \(p.age ?? 75) years old"
            cell.preferedGenre = p.prefered_genre ?? []
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoldingCell", for: indexPath) as! FoldingCell
        let durations: [TimeInterval] = [0.26, 0.2, 0.2]
        cell.durationsForExpandedState = durations
        cell.durationsForCollapsedState = durations
        return cell
    }

    override func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let cell = tableView.cellForRow(at: indexPath) as! FoldingCell

        if cell.isAnimating() {
            return
        }

        var duration = 0.0
        let cellIsCollapsed = cellHeights[indexPath.row] == Const.closeCellHeight
        if cellIsCollapsed {
            cellHeights[indexPath.row] = Const.openCellHeight
            cell.unfold(true, animated: true, completion: nil)
            duration = 0.5
        } else {
            cellHeights[indexPath.row] = Const.closeCellHeight
            cell.unfold(false, animated: true, completion: nil)
            duration = 0.8
        }

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            tableView.beginUpdates()
            tableView.endUpdates()
            
            // fix https://github.com/Ramotion/folding-cell/issues/169
            if cell.frame.maxY > tableView.frame.maxY {
                tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            }
        }, completion: nil)
    }
}
