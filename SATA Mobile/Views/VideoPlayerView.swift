import SwiftUI
import AVKit

class CustomPlayerViewController: UIViewController {
    var playerViewController: AVPlayerViewController
    
    init(playerViewController: AVPlayerViewController) {
        self.playerViewController = playerViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(playerViewController)
        
        view.addSubview(playerViewController.view)
        
        playerViewController.view.frame = view.bounds
        
        playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        playerViewController.didMove(toParent: self)
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    var videoURL: URL
    var title: String
    var subtitle: String
    @State private var currentBPM: Int = 75  // Add this property

    func makeUIViewController(context: Context) -> UIViewController {
        let playerController = AVPlayerViewController()
        
        // Create AVPlayerItem and set metadata
        let playerItem = AVPlayerItem(url: videoURL)
        setMetadata(for: playerItem)
        
        // Configure player controller
        playerController.player = AVPlayer(playerItem: playerItem)
        playerController.allowsPictureInPicturePlayback = true
        playerController.videoGravity = .resizeAspect
        playerController.modalPresentationStyle = .fullScreen
        playerController.entersFullScreenWhenPlaybackBegins = true
        playerController.exitsFullScreenWhenPlaybackEnds = true
        
        // Start playing automatically
        playerController.player!.play()
        
        return CustomPlayerViewController(playerViewController: playerController)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Handle any updates if necessary
    }

    private func setMetadata(for item: AVPlayerItem) {
        let titleItem = AVMutableMetadataItem()
        titleItem.identifier = .commonIdentifierTitle
        titleItem.value = title as NSString

        let subtitleItem = AVMutableMetadataItem()
        subtitleItem.identifier = .iTunesMetadataTrackSubTitle
        subtitleItem.value = subtitle as NSString

        let infoItem = AVMutableMetadataItem()
        infoItem.identifier = .commonIdentifierDescription
        infoItem.value = "Info" as NSString

        item.externalMetadata = [titleItem, subtitleItem, infoItem]
    }
}

#Preview {
    let videoURL = URL(string: "https://embed-ssl.wistia.com/deliveries/cc8402e8c16cc8f36d3f63bd29eb82f99f4b5f88/accudvh5jy.mp4")!
    VideoPlayerView(videoURL:videoURL, title: "Title", subtitle: "Subtitle")
}
