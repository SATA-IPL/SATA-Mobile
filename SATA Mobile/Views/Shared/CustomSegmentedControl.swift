import SwiftUI

struct CustomSegmentedControl<Section: Hashable>: View {
    @Binding var selectedSection: Section
    let sections: [Section]
    
    var body: some View {
        HStack {
            ForEach(sections, id: \.self) { section in
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
        .padding(.horizontal)
    }
}
