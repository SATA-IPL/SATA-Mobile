import SwiftUI
import MapKit

struct StadiumView: View {
    @Environment(\.dismiss) private var dismiss
    @State var stadium: Stadium
    @State private var distance: CLLocationDistance = 900
    
    init(stadium: Stadium, distance: CLLocationDistance = 900) {
        _stadium = State(initialValue: stadium)
        _distance = State(initialValue: distance)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
        UINavigationBar.appearance().standardAppearance = appearance
    }
    
    
    func openInMaps() {
        let placemark = MKPlacemark(coordinate: stadium.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = stadium.stadiumName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    
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
                    GlassToolbar(title: "Lisbon", dismiss: dismiss, openInMaps: openInMaps)
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

struct MapContainerView: View {
    @State var stadium: Stadium
    @State private var position: MapCameraPosition = .automatic
    @State private var heading: CLLocationDirection = 100
    private let rotationSpeed: CLLocationDirection = 0.1
    @State var distance: CLLocationDistance

    private var customMapStyle: MapStyle {
        .standard(
            elevation: .realistic,
            pointsOfInterest: .excludingAll,
            showsTraffic: false
        )
    }
    
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

struct BottomContentView: View {
    let stadium: Stadium
    let proxy: GeometryProxy

    var body: some View {
        VStack {
            Spacer()
            bottomContentContainer
                .padding(.bottom, 120)
                .background(
                    bottomContentBackground,
                    alignment: .bottom
                )
                .background(
                    bottomContentBlurBackground
                        .frame(width: proxy.size.width)
                )
        }
    }

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

    private var bottomContentBackground: some View {
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
    
    private var bottomContentBlurBackground: some View {
        VariableBlurView(maxBlurRadius: 20, direction: .blurredBottomClearTop)
    }
}

// MARK: - Glass Toolbar

struct GlassToolbar: ToolbarContent {
    let title: String
    let dismiss: DismissAction
    let openInMaps: () -> Void
    
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
            Button(action: openInMaps) {
                Image(systemName: "location.fill")
            }
            .foregroundStyle(.white)
        }
    }
}
