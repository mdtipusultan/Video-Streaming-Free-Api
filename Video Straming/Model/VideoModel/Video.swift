//
//  Video.swift
//  Video Straming
//
//  Created by Tipu Sultan on 4/8/25.
//

import AVFoundation

struct Video {
    let title: String
    let videoURL: URL
    var lastPlaybackTime: CMTime = .zero // New line!
}

class PexelsVideoService {
    private let apiKey = "fU6hEyXhfVk4jxDP6xSj5zJhziGAXuDnul4utfqkSLZ0m4anb6azQg4m"
    private let session = URLSession.shared
    
    func fetchVideos(completion: @escaping ([Video]) -> Void) {
        let url = URL(string: "https://api.pexels.com/videos/search?query=nature&per_page=10")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        
        session.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("❌ Error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let videosArray = json?["videos"] as? [[String: Any]] ?? []
                
                let videos: [Video] = videosArray.compactMap { videoJSON in
                    if let urlStr = (videoJSON["video_files"] as? [[String: Any]])?.first(where: { $0["quality"] as? String == "hd" })?["link"] as? String,
                       let url = URL(string: urlStr),
                       let title = videoJSON["id"].flatMap({ "Video \($0)" }) {
                        return Video(title: title, videoURL: url)
                    }
                    return nil
                }
                
                DispatchQueue.main.async {
                    completion(videos)
                }
            } catch {
                print("❌ JSON parsing failed: \(error)")
                completion([])
            }
        }.resume()
    }
}
