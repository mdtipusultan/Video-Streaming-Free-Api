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
    @IBOutlet weak var muteButton: UIButton!

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    override func awakeFromNib() {
        super.awakeFromNib()

        // Tap to Play/Pause
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        videoContainerView.addGestureRecognizer(tapGesture)
        
        videoContainerView.backgroundColor = .black

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
    }

    func configure(with video: Video) {
        player = AVPlayer(url: video.videoURL)
        player?.isMuted = true

        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = videoContainerView.bounds

        if let layer = playerLayer {
            videoContainerView.layer.addSublayer(layer)
        }

        muteButton.setImage(UIImage(systemName: "speaker.slash.fill"), for: .normal)
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

    @IBAction func muteTapped(_ sender: UIButton) {
        guard let player = player else { return }
        player.isMuted.toggle()
        let icon = player.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        muteButton.setImage(UIImage(systemName: icon), for: .normal)
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
