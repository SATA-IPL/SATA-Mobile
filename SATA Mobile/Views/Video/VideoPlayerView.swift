import SwiftUI
import AVKit
import Combine
import AVFoundation

// MARK: - CustomPlayerViewController
/// Custom view controller that manages video playback and Picture-in-Picture functionality
class CustomPlayerViewController: UIViewController, AVPlayerViewControllerDelegate {
    // MARK: - Properties
    var playerViewController: AVPlayerViewController
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private let dismissAction: () -> Void
    private let presentAction: () -> Void
    
    // MARK: - Initialization
    init(playerViewController: AVPlayerViewController, 
         dismissAction: @escaping () -> Void,
         presentAction: @escaping () -> Void) {
        self.playerViewController = playerViewController
        self.dismissAction = dismissAction
        self.presentAction = presentAction
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
        
        playerViewController.delegate = self // Add delegate
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
        // Dismiss the full screen player when entering PiP
        dismissAction()
    }
    
    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        // Handle PIP did start
    }
    
    func playerViewControllerWillStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        // Handle PIP will stop
    }
    
    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        // Force UI update when PiP stops
        DispatchQueue.main.async {
            self.presentAction()
        }
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController,
                            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // Restore the UI first
        presentAction()
        
        // Wait for the UI to be ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Then present the player
            if self.presentedViewController == nil {
                self.present(playerViewController, animated: true) {
                    completionHandler(true)
                }
            } else {
                completionHandler(true)
            }
        }
    }
    
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
        return false // Prevent automatic dismissal when PiP starts
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, failedToStartPictureInPictureWithError error: Error) {
        print("Failed to start PiP:", error.localizedDescription)
    }
}

// MARK: - VideoPlayerView
/// SwiftUI view that wraps AVPlayerViewController for video playback
struct VideoPlayerView: UIViewControllerRepresentable {
    // MARK: - Properties
    @Binding var isPresented: Bool
    var videoURL: URL
    var title: String
    var subtitle: String
    var thumbnailURL: URL? // Add this new property
    
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
        
        // Set AirPlay artwork if thumbnail is available
        if let thumbnailURL = thumbnailURL {
            Task {
                if let (data, _) = try? await URLSession.shared.data(from: thumbnailURL),
                   let image = UIImage(data: data) {
                    player.currentItem?.externalMetadata.append(createArtworkMetadataItem(image: image))
                }
            }
        }
        
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
        
        let customController = CustomPlayerViewController(
            playerViewController: playerController,
            dismissAction: { 
                withAnimation {
                    isPresented = false
                }
            },
            presentAction: { 
                withAnimation {
                    isPresented = true
                }
            }
        )
        return customController
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
    
    private func createArtworkMetadataItem(image: UIImage) -> AVMutableMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = .commonIdentifierArtwork
        item.value = image.pngData() as (NSCopying & NSObjectProtocol)?
        item.dataType = kCMMetadataBaseDataType_PNG as String
        item.extendedLanguageTag = "und"
        return item
    }
}

// MARK: - Preview
#Preview {
    let videoURL = URL(string: "https://embed-ssl.wistia.com/deliveries/cc8402e8c16cc8f36d3f63bd29eb82f99f4b5f88/accudvh5jy.mp4")!
    let thumbnailURL = URL(string: "https://images.unsplash.com/photo-1486286701208-1d58e9338013?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")
    return VideoPlayerView(
        isPresented: .constant(true),
        videoURL: videoURL,
        title: "Title",
        subtitle: "Subtitle",
        thumbnailURL: thumbnailURL
    )
}
