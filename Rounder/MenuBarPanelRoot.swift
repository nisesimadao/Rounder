import SwiftUI

struct MenuBarPanelRoot: View {
    let content: MenuBarPanelView

    var body: some View {
        ScrollView {
            content
        }
        .scrollBounceBehavior(.basedOnSize)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .tint(.accentColor)
        .environment(\.controlActiveState, .key)
    }
}
