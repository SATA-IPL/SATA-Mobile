import SwiftUI
import AVKit
import Combine
import AVFoundation

// MARK: - CustomPlayerViewController
/// Custom view controller that manages video playback and Picture-in-Picture functionality
class CustomPlayerViewController: UIViewController {
    // MARK: - Properties
    var playerViewController: AVPlayerViewController
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    
    // MARK: - Initialization
    init(playerViewController: AVPlayerViewController) {
        self.playerViewController = playerViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure audio session for PIP
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
        
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.frame = view.bounds
        playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerViewController.didMove(toParent: self)
        
        setupObservers()
        
        // Enable PIP if available
        if AVPictureInPictureController.isPictureInPictureSupported() {
            playerViewController.allowsPictureInPicturePlayback = true
            
            // Configure player layer for PIP
            Task {
                if let asset = playerViewController.player?.currentItem?.asset,
                   let _ = try? await asset.loadTracks(withMediaType: .video) {
                    (playerViewController.view.layer as? AVPlayerLayer)?.videoGravity = .resizeAspect
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        guard let player = playerViewController.player else { return }
        
        // Observe player status
        statusObserver = player.observe(\.status, options: [.new]) { [weak self] player, _ in
            switch player.status {
            case .failed:
                self?.handlePlaybackError(player.error)
            case .readyToPlay:
                player.play()
            default:
                break
            }
        }
        
        // Add periodic time observer
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] _ in
            self?.handleTimeUpdate()
        }
    }
    
    private func handlePlaybackError(_ error: Error?) {
        // Show alert or handle error appropriately
        print("Playback error: \(error?.localizedDescription ?? "unknown error")")
    }
    
    private func handleTimeUpdate() {
        // Handle time updates if needed
    }
    
    deinit {
        if let timeObserver = timeObserver {
            playerViewController.player?.removeTimeObserver(timeObserver)
        }
        statusObserver?.invalidate()
    }
    
    // MARK: - PIP Delegate Methods
    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        // Handle PIP will start
    }
    
    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        // Handle PIP did start
    }
    
    func playerViewControllerWillStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        // Handle PIP will stop
    }
    
    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        // Handle PIP did stop
    }
}

// MARK: - VideoPlayerView
/// SwiftUI view that wraps AVPlayerViewController for video playback
struct VideoPlayerView: UIViewControllerRepresentable {
    // MARK: - Properties
    var videoURL: URL
    var title: String
    var subtitle: String
    
    // MARK: - UIViewControllerRepresentable
    func makeUIViewController(context: Context) -> UIViewController {
        let playerController = AVPlayerViewController()
        let playerItem = AVPlayerItem(url: videoURL)
        
        // Configure error handling and playback settings
        playerItem.preferredForwardBufferDuration = 5
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        
        setMetadata(for: playerItem)
        
        let player = AVPlayer(playerItem: playerItem)
        playerController.player = player
        
        // Configure player controller
        playerController.allowsPictureInPicturePlayback = true
        playerController.videoGravity = .resizeAspect
        playerController.modalPresentationStyle = .fullScreen
        playerController.entersFullScreenWhenPlaybackBegins = true
        playerController.exitsFullScreenWhenPlaybackEnds = true
        playerController.showsPlaybackControls = true
        
        // Enable background playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
        
        return CustomPlayerViewController(playerViewController: playerController)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Handle any updates if necessary
    }

    // MARK: - Private Methods
    private func setMetadata(for item: AVPlayerItem) {
        let metadataItems = [
            createMetadataItem(identifier: .commonIdentifierTitle, value: title),
            createMetadataItem(identifier: .iTunesMetadataTrackSubTitle, value: subtitle),
            createMetadataItem(identifier: .commonIdentifierDescription, value: "Info")
        ]
        
        item.externalMetadata = metadataItems
    }
    
    private func createMetadataItem(identifier: AVMetadataIdentifier, value: String) -> AVMutableMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as NSString
        item.extendedLanguageTag = "und"
        return item
    }
}

// MARK: - Preview
#Preview {
    let videoURL = URL(string: "https://embed-ssl.wistia.com/deliveries/cc8402e8c16cc8f36d3f63bd29eb82f99f4b5f88/accudvh5jy.mp4")!
    VideoPlayerView(videoURL:videoURL, title: "Title", subtitle: "Subtitle")
}
