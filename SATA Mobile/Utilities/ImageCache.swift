import Foundation
import UIKit

actor SharedImageCache {
    static let shared = SharedImageCache()
    
    private let groupIdentifier = "group.com.joaofranco.SATA-Mobile"
    private let fileManager = FileManager.default
    
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    func cacheImage(_ imageUrl: String) async throws -> String {
        // Generate a unique filename using the URL's hash
        let filename = String(imageUrl.hash) + ".png"
        
        // Check if already cached
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            throw NSError(domain: "ImageCache", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to access shared container"])
        }
        
        let fileURL = containerURL.appendingPathComponent(filename)
        
        // Return if already exists
        if fileManager.fileExists(atPath: fileURL.path) {
            return filename
        }
        
        // Download and cache image
        guard let url = URL(string: imageUrl),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else {
            throw NSError(domain: "ImageCache", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to download image"])
        }
        
        // Save to shared container
        guard let pngData = image.pngData() else {
            throw NSError(domain: "ImageCache", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG"])
        }
        
        try pngData.write(to: fileURL)
        return filename
    }
}
