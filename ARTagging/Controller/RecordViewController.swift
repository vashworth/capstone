//
//  RecordViewController.swift
//  ARTagging
//
//  Created by Victoria Ashworth on 4/8/19.
//  Copyright © 2019 Victoria Ashworth. All rights reserved.
//

import Foundation
import UIKit
import SceneKitVideoRecorder
import AVKit
import AVFoundation

protocol RecordViewControllerDelegate {
    func dismiss()
    func screenshot() -> UIImage
    func setupRecorder() -> SceneKitVideoRecorder?
}

class RecordViewController : UIViewController {
    var recorder: SceneKitVideoRecorder?
    var delegate : RecordViewControllerDelegate?
    var buttonHighlighted = false
    var videoData : Data?
    
    @IBOutlet weak var shareAction: UIBarButtonItem!
    @IBOutlet weak var PhotoVideoOption: UISegmentedControl!
    @IBOutlet weak var previewImage: UIImageView!
    
    @IBOutlet weak var buttonBorder: UIView!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shareAction.isEnabled = false
        style()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recorder = delegate?.setupRecorder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.dismiss()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pressCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        delegate?.dismiss()
    }
    
    @IBAction func pressRecord(_ sender: Any) {
        if buttonHighlighted == true {
            buttonHighlighted = false
        } else {
            buttonHighlighted = true
        }
        
        if PhotoVideoOption.selectedSegmentIndex == 0 {
            // photo
            previewImage.image = delegate?.screenshot()
            previewImage.isHidden = false
            shareAction.isEnabled = true
        } else {
            // video
            if buttonHighlighted == true {
                self.recorder?.startWriting().onSuccess {
                    print("Recording Started")
                    UIButton.animate(withDuration: 0.5) {
                        self.trailingConstraint.constant = 15
                        self.leadingConstraint.constant = 15
                        self.topConstraint.constant = 15
                        self.bottomConstraint.constant = 15
                        self.recordButton.layer.cornerRadius = (self.recordButton.frame.width / 10)
                        self.recordButton.clipsToBounds = true
                        self.view.layoutIfNeeded()
                    }
                }
            } else {
                self.recorder?.finishWriting().onSuccess { [weak self] url in
                    print("Recording Finished", url.absoluteString)
                    
                    do {
                        try self?.videoData = Data(contentsOf: url)
                    } catch {
                        print("Line 84: \(error)")
                    }
                    
                    self?.playVideo(from: url)
                    self?.shareAction.isEnabled = true
                }
            }
        }
    }
    
    
    @IBAction func PhotoVideoOptionChange(_ sender: Any) {
        // adjust UI
        if PhotoVideoOption.selectedSegmentIndex == 0 {
            // photo
            UIButton.animate(withDuration: 0.5) {
                self.trailingConstraint.constant = 8
                self.leadingConstraint.constant = 8
                self.topConstraint.constant = 8
                self.bottomConstraint.constant = 8
                self.view.layoutIfNeeded()
                self.recordButton.layer.backgroundColor = UIColor.white.cgColor
                self.recordButton.layer.cornerRadius = (self.recordButton.frame.width / 2)
                self.recordButton.clipsToBounds = true
                self.view.layoutIfNeeded()
            }
        } else {
            // video
            UIButton.animate(withDuration: 0.5) {
                self.trailingConstraint.constant = 8
                self.leadingConstraint.constant = 8
                self.topConstraint.constant = 8
                self.bottomConstraint.constant = 8
                self.view.layoutIfNeeded()
                self.recordButton.layer.backgroundColor = UIColor.red.cgColor
                self.recordButton.layer.cornerRadius = (self.recordButton.frame.width / 2)
                self.recordButton.clipsToBounds = true
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func pressShare(_ sender: Any) {
        var vc: UIActivityViewController
        if PhotoVideoOption.selectedSegmentIndex == 0 {
            guard let image = previewImage.image else { return }
            vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            
        } else {
            guard let video = videoData else { return }
            
            let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            let videoURL = DocumentDirURL.appendingPathComponent("recording").appendingPathExtension("mp4")
            
            do {
                try video.write(to: videoURL)
                print("written")
            } catch {
                print("Line 121: \(error)")
            }
            
            vc = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
        }
        
        present(vc, animated: true)
    }
    
    
    private func playVideo(from file : URL) {
        let player = AVPlayer(url: file)
        let playerController = AVPlayerViewController()
        
        playerController.player = player
        
        self.addChild(playerController)
        self.view.addSubview(playerController.view)
        playerController.view.frame = self.view.frame
        
        player.play()
    }
    
    func style() {
        buttonBorder.layer.cornerRadius = (buttonBorder.frame.width / 2)
        buttonBorder.clipsToBounds = true
        buttonBorder.layer.borderWidth = 5
        buttonBorder.layer.borderColor = UIColor.white.cgColor
        
        recordButton.layer.cornerRadius = (recordButton.frame.width / 2)
        recordButton.clipsToBounds = true
    }
}

