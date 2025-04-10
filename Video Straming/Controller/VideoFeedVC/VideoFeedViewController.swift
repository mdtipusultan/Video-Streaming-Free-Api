//
//  VideoFeedViewController.swift
//  Video Straming
//
//  Created by Tipu Sultan on 4/8/25.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var videos: [Video] = []
    
    var currentlyPlayingCell: MediaCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadSampleVideos()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.playVisibleVideo()
        }
        
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isPagingEnabled = true  // One video per screen
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
    }
    
    //    private func loadSampleVideos() {
    //        let sampleURLs = [
    //            "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
    //            "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
    //            "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
    //            "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
    //            "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
    //            "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
    //            "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
    //            "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
    //        ]
    //
    //        videos = sampleURLs.compactMap {
    //            guard let url = URL(string: $0) else { return nil }
    //            return Video(title: "Sample Video", videoURL: url)
    //        }
    //
    //        tableView.reloadData()
    //    }
    
    private func loadSampleVideos() {
        let videoService = PexelsVideoService()
        videoService.fetchVideos { [weak self] videos in
            self?.videos = videos
            self?.tableView.reloadData()
        }
    }
    
    
    
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MediaCell.identifier, for: indexPath) as? MediaCell else {
            return UITableViewCell()
        }
        
        let video = videos[indexPath.row]
        cell.configure(with: video)
        
        cell.onPlaybackTimeUpdate = { [weak self] time in
            self?.videos[indexPath.row].lastPlaybackTime = time
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIScreen.main.bounds.height
    }
    
}

extension ViewController: UITableViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        playVisibleVideo()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            playVisibleVideo()
        }
    }
    
    
    private func playVisibleVideo() {
        guard let visibleIndexPath = tableView.indexPathsForVisibleRows?.first,
              let cell = tableView.cellForRow(at: visibleIndexPath) as? MediaCell else { return }
        
        // Stop previous cell
        if currentlyPlayingCell != cell {
            currentlyPlayingCell?.stopPlayback()
            currentlyPlayingCell = cell
        }
        
        // Start new video
        cell.playVideo()
    }
}
