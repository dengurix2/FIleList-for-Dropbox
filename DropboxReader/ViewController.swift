//
//  ViewController.swift
//  FileList
//
//  Created by Hrt on 2016/09/18.
//  Copyright © 2016年 takahirohirata.com. All rights reserved.
//

import UIKit
import SwiftyDropbox

struct FileInfo {
    var name: String
    var bFolder: Bool
    init(name: String, bFolder: Bool) {
        self.name = name
        self.bFolder = bFolder
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var linkButton: UIButton!
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var linkDropboxBGView: UIView!

    private var fileInfoArray:Array<FileInfo>?
    private var targetPath:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.isHidden = true
        reloadButton.isHidden = true
        fileInfoArray = []
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.viewController = self
        checkButtons()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func linkButtonPressed(_ sender: AnyObject) {
        if (!isLinked()) {
            DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                          controller: self,
                                                          openURL: { (url: URL) -> Void in
                                                            UIApplication.shared.open(url, options: ["":""], completionHandler: nil)
            })
        } else {
            DropboxClientsManager.unlinkClients()
            checkButtons()
        }
    }
    
    @IBAction func unwindToViewController(segue: UIStoryboardSegue) {
    }
    
    private func isLinked() -> Bool {
        if DropboxClientsManager.authorizedClient != nil || DropboxClientsManager.authorizedTeamClient != nil {
            return true
        } else {
            return false
        }
    }
    
    public func checkButtons() {
        if (isLinked()) {
            linkButton .setTitle("unlink Dropbox", for: UIControlState.normal)
            linkDropboxBGView.isHidden = true

            getTargetPathList()
        } else {
            linkButton.setTitle("link Dropbox", for: UIControlState.normal)
            targetPath = ""
            fileInfoArray = []
            listTableView.reloadData()
            titleLabel.text = ""
            self.reloadButton.isHidden = true
        }
    }
    
    @IBAction func showLinkDropboxView(_ sender: AnyObject) {
        linkDropboxBGView.isHidden = !linkDropboxBGView.isHidden
    }

    private func setTitleLabel() {
        titleLabel.text = (targetPath == "")&&isLinked() ? "/" : targetPath
    }
    
    @IBAction func backButtonTapped(_ sender: AnyObject) {
        
        var array = targetPath.components(separatedBy: "/")
        if array.count>2 {
            array.removeFirst()
            array.removeLast()
            for name in array {
                targetPath = "/"
                targetPath.append(name)
            }
        } else {
            targetPath = ""
        }
        getTargetPathList()
        
    }
    
    @IBAction func reloadButtonTapped(_ sender: AnyObject) {
        getTargetPathList()
    }
    
    private func getTargetPathList()
    {
        if let client = DropboxClientsManager.authorizedClient {
            loadingView.isHidden = false
            client.files.listFolder(path: targetPath).response { response, error in
                if let metadata = response {
                    self.fileInfoArray?.removeAll()
                    for entry in metadata.entries {
                        print(entry.name)
                        var bFolder:Bool = true
                        if entry is Files.FileMetadata {
                            bFolder = false
                        } else {
                        }
                        self.fileInfoArray?.append(FileInfo(name: entry.name, bFolder: bFolder))
                    }
                    
                    self.listTableView.reloadData()
                    self.setTitleLabel()
                } else {
                    print(error!)
                    self.loadingView.isHidden = true
                    self.backButton.isHidden = true
                    self.reloadButton.isHidden = true
                    self.targetPath = ""
                }
                self.backButton.isHidden = self.targetPath=="" ? true : false
                self.loadingView.isHidden = true
                self.reloadButton.isHidden = false
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fileInfoArray!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath)
        let fileInfo:FileInfo = self.fileInfoArray![indexPath.row]
        cell.textLabel!.text = fileInfo.name
        cell.accessoryType = .none
        cell.imageView!.image = nil
        if fileInfo.bFolder {
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = UITableViewCellSelectionStyle.gray
            cell.imageView!.image = UIImage(named: "icon_folder")
        } else {
                cell.accessoryType = .none
                cell.selectionStyle = UITableViewCellSelectionStyle.none
                cell.imageView!.image = UIImage(named: "icon_file")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileInfo = self.fileInfoArray![indexPath.row]
        print("string: \(fileInfo.name), folder: \(fileInfo.bFolder)")

        if fileInfo.bFolder {
            targetPath.append("/")
            let fileInfo:FileInfo = self.fileInfoArray![indexPath.row]
            targetPath.append(fileInfo.name)
            print(targetPath)
            getTargetPathList()
        } else {
            print(fileInfo.name)
            
            let cell = tableView.cellForRow(at: indexPath)
            if cell?.accessoryType == .checkmark {
                let filename = cell?.textLabel?.text
                if let client = DropboxClientsManager.authorizedClient {
                    let fileManager = FileManager.default
                    let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let destURL = directoryURL.appendingPathComponent(filename!)
                    let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
                        return destURL
                    }
                    let path = self.targetPath + "/" + filename!
                    client.files.download(path: path, overwrite: true, destination: destination)
                        .response { response, error in
                            if let response = response {
                                print(response)
                            } else if let error = error {
                                print(error)
                            }
                        }
                        .progress { progressData in
                            print(progressData)
                    }
                }
            }
        }
    }
    
    func showAlert() {
        let alert: UIAlertController = UIAlertController(title: "ERROR", message: "", preferredStyle:  UIAlertControllerStyle.alert)
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{
            (action: UIAlertAction!) -> Void in
            print("OK")
        })
        alert.addAction(defaultAction)
        present(alert, animated: true, completion: nil)
    }
}

