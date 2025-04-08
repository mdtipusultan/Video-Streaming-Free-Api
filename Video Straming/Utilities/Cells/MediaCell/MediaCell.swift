//
//  MediaCell.swift
//  Video Straming
//
//  Created by Tipu Sultan on 4/8/25.
//

import UIKit
import AVFoundation


class MediaCell: UITableViewCell {
    static let identifier = "MediaCell"

    @IBOutlet weak var videoContainerView: UIView!

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    private var timeObserverToken: Any?
    
    //other propirties
    private let backwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("⏪", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        return button
    }()

    private let forwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("⏩", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        return button
    }()

    private let progressSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        return slider
    }()

    private let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white
        label.text = "00:00"
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white
        label.text = "00:00"
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        videoContainerView.backgroundColor = .black

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        videoContainerView.addGestureRecognizer(tapGesture)
        
        setupControls()
    }
    
    private func setupControls() {
        let controls = [backwardButton, forwardButton, progressSlider, currentTimeLabel, durationLabel]
        controls.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            videoContainerView.addSubview($0)
        }

        backwardButton.addTarget(self, action: #selector(didTapBackward), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(didTapForward), for: .touchUpInside)
        progressSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)

        NSLayoutConstraint.activate([
            // Progress slider
            progressSlider.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor, constant: 50),
            progressSlider.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor, constant: -50),
            progressSlider.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: -40),
            
            // Current time label
            currentTimeLabel.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
            currentTimeLabel.bottomAnchor.constraint(equalTo: progressSlider.topAnchor, constant: -4),
            
            // Duration label
            durationLabel.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor),
            durationLabel.bottomAnchor.constraint(equalTo: progressSlider.topAnchor, constant: -4),
            
            // Backward button
            backwardButton.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor, constant: 10),
            backwardButton.centerYAnchor.constraint(equalTo: progressSlider.centerYAnchor),
            
            // Forward button
            forwardButton.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor, constant: -10),
            forwardButton.centerYAnchor.constraint(equalTo: progressSlider.centerYAnchor)
        ])
    }

    @objc private func didTapBackward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTimeMake(value: 10, timescale: 1))
        player.seek(to: newTime)
    }

    @objc private func didTapForward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTimeMake(value: 10, timescale: 1))
        player.seek(to: newTime)
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        guard let duration = player?.currentItem?.duration else { return }
        let totalSeconds = CMTimeGetSeconds(duration)
        let seekTime = CMTime(seconds: Double(sender.value) * totalSeconds, preferredTimescale: 600)
        player?.seek(to: seekTime)
    }

    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }


    
    override func prepareForReuse() {
        super.prepareForReuse()

        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }

        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
    }
    
    func configure(with video: Video) {
        player = AVPlayer(url: video.videoURL)
        player?.isMuted = true

        // Remove previous playerLayer if any
        playerLayer?.removeFromSuperlayer()

        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = videoContainerView.bounds

        if let layer = playerLayer {
            // Insert the player layer at the back so UI controls stay visible
            videoContainerView.layer.insertSublayer(layer, at: 0)
        }

        addPeriodicTimeObserver()

        // Set duration label
        if let duration = player?.currentItem?.asset.duration {
            let seconds = CMTimeGetSeconds(duration)
            durationLabel.text = formatTime(seconds)
        }
    }


    
    private func addPeriodicTimeObserver() {
        guard let player = player else { return }

        // Remove previous observer if any
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }

        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self,
                  let duration = player.currentItem?.duration else { return }

            let currentSeconds = CMTimeGetSeconds(time)
            let durationSeconds = CMTimeGetSeconds(duration)

            if durationSeconds.isFinite && durationSeconds > 0 {
                self.progressSlider.value = Float(currentSeconds / durationSeconds)
                self.currentTimeLabel.text = self.formatTime(currentSeconds)
            }
        }
    }



    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
    }


    func playVideo() {
        player?.play()
    }

    func pauseVideo() {
        player?.pause()
    }
    
    func stopPlayback() {
        player?.pause()
    }

    @objc private func handleTap() {
        guard let player = player else { return }

        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
}
