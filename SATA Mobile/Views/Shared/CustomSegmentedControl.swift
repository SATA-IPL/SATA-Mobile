import SwiftUI

// MARK: - CustomSegmentedControl
/// A custom segmented control that displays a horizontal list of selectable sections
/// with animated selection state.
struct CustomSegmentedControl<Section: Hashable>: View {
    // MARK: - Properties
    /// The currently selected section, bound to an external state
    @Binding var selectedSection: Section
    
    /// Array of sections to be displayed in the control
    let sections: [Section]
    
    // MARK: - Body
    var body: some View {
        HStack {
            ForEach(sections, id: \.self) { section in
                sectionButton(for: section)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Private Methods
    /// Creates a button for a specific section
    /// - Parameter section: The section to create a button for
    /// - Returns: A button view configured for the section
    private func sectionButton(for section: Section) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = section
            }
        }) {
            Text(String(describing: section).capitalized)
                .font(.system(.title2, weight: .bold).width(.compressed))
                .foregroundStyle(selectedSection == section ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
