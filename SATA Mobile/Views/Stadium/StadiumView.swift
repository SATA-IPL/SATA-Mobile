import SwiftUI
import MapKit

/// A view that displays detailed information about a stadium, including a 3D map view and stadium details
struct StadiumView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: StadiumsViewModel
    @State var stadium: Stadium
    @State private var distance: CLLocationDistance = 900
    
    // MARK: - Initialization
    
    /// Initializes a new stadium view
    /// - Parameters:
    ///   - viewModel: The view model managing stadiums data
    ///   - stadium: The stadium to display
    ///   - distance: The initial camera distance from the stadium
    init(viewModel: StadiumsViewModel, stadium: Stadium, distance: CLLocationDistance = 900) {
        self.viewModel = viewModel
        _stadium = State(initialValue: stadium)
        _distance = State(initialValue: distance)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
        UINavigationBar.appearance().standardAppearance = appearance
    }
    
    // MARK: - Helper Methods
    
    /// Opens the stadium location in Apple Maps with driving directions
    func openInMaps() {
        let placemark = MKPlacemark(coordinate: stadium.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = stadium.stadiumName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
                    MapContainerView(stadium: stadium, distance: distance)
                        .ignoresSafeArea()
                        .frame(height: 700)
                    
                    VStack {
                        VariableBlurView(maxBlurRadius: 20, direction: .blurredTopClearBottom)
                            .frame(height: proxy.safeAreaInsets.top)
                            .ignoresSafeArea()
                        Spacer()
                    }
                    
                    BottomContentView(stadium: stadium, proxy: proxy)
                        .ignoresSafeArea()

                }
                .preferredColorScheme(.dark)
                .toolbar(content: {
                    GlassToolbar(
                        title: "Stadium",
                        dismiss: dismiss,
                        openInMaps: openInMaps,
                        isFavorite: stadium.isFavorite,
                        toggleFavorite: {
                            viewModel.toggleFavorite(for: stadium)
                            stadium.isFavorite.toggle()
                        }
                    )
                })
                .navigationBarTitleDisplayMode(.inline)
                .ignoresSafeArea()
                .toolbarBackground(.hidden, for: .navigationBar)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Map Container View

/// A view that displays an interactive 3D map of the stadium location
struct MapContainerView: View {
    // MARK: - Properties
    @State var stadium: Stadium
    @State private var position: MapCameraPosition = .automatic
    @State private var heading: CLLocationDirection = 100
    private let rotationSpeed: CLLocationDirection = 0.1
    @State var distance: CLLocationDistance
    
    /// Custom map style configuration
    private var customMapStyle: MapStyle {
        .standard(
            elevation: .realistic,
            pointsOfInterest: .excludingAll,
            showsTraffic: false
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        Map(
            position: $position,
            interactionModes: [.pan, .zoom, .rotate],
            selection: .constant(nil)
        )
        .onAppear {
            let mapCamera = MKMapCamera(
                lookingAtCenter: stadium.coordinate,
                fromDistance: distance,
                pitch: 65,
                heading: heading
            )
            
            let cameraPosition = MapCameraPosition.camera(.init(mapCamera))
            
            position = cameraPosition
            startPanning()
        }
        .mapStyle(customMapStyle)
        .mapControls {
            // Empty to disable compass while maintaining interactions
        }
    }
    
    // MARK: - Helper Methods
    
    /// Starts the continuous panning animation of the map camera
    private func startPanning() {
        // Use a timer to update the heading gradually
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            // Increment the heading by a small amount for gradual panning
            heading += rotationSpeed
            if heading >= 360 {
                heading = 0 // Reset heading after a full rotation
            }
            
            // Update the camera position with the new heading
            let mapCamera = MKMapCamera(
                lookingAtCenter: stadium.coordinate,
                fromDistance: distance,
                pitch: 60,
                heading: heading
            )
            
            let cameraPosition = MapCameraPosition.camera(.init(mapCamera))
            
            position = cameraPosition
        }
    }
}

// MARK: - Bottom Content View

/// A view displaying stadium information in a glass-like container at the bottom of the screen
struct BottomContentView: View {
    // MARK: - Properties
    let stadium: Stadium
    let proxy: GeometryProxy
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Spacer()
            bottomContentContainer
                .padding(.bottom, 120)
                .background(
                    bottomContentGradientBackground,
                    alignment: .bottom
                )
                .background(
                    bottomContentBlurBackground
                        .frame(width: proxy.size.width)
                )
        }
    }
    
    // MARK: - Subviews
    
    /// Container for the bottom content with padding and spacing
    private var bottomContentContainer: some View {
        VStack(spacing: 24) {
             capacityView
                
            Text(stadium.stadiumName)
                .font(.system(size: 34, weight: .semibold))
                .fontDesign(.serif)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Built in \(stadium.yearBuilt)")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    /// View displaying the stadium's capacity
    private var capacityView: some View {
        HStack {
            Image(systemName: "person.3.fill")
                .font(.system(size: 12))
            Text("Capacity: \(stadium.stadiumSeats)")
                .font(.system(size: 14))
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.2))
        .background(Material.ultraThin)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        )
        .fontDesign(.default)
    }
    
    /// Background gradient for the bottom content
    private var bottomContentGradientBackground: some View {
         // Updated Gradient to blend seamlessly with the map
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color(.systemBackground).opacity(0.6),
                        Color(.systemBackground).opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: proxy.size.width)
    }
    
    /// Blur effect for the bottom content background
    private var bottomContentBlurBackground: some View {
        VariableBlurView(maxBlurRadius: 20, direction: .blurredBottomClearTop)
    }
}

// MARK: - Glass Toolbar

/// A custom toolbar with a glass-like appearance
struct GlassToolbar: ToolbarContent {
    // MARK: - Properties
    let title: String
    let dismiss: DismissAction
    let openInMaps: () -> Void
    let isFavorite: Bool
    let toggleFavorite: () -> Void
    
    // MARK: - Body
    
    var body: some ToolbarContent {
         ToolbarItem(placement: .principal) {
            VStack {
                Text(title)
                    .fontDesign(.serif)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
         }
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
            }
            .foregroundStyle(.white)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
            }
            .foregroundStyle(.white)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: openInMaps) {
                Image(systemName: "location.fill")
            }
            .foregroundStyle(.white)
        }
    }
}
