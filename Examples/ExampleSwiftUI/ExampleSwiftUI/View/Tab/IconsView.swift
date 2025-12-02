import SwiftUI

struct IconsView: View {
    var images = [
        Image.ic16KeyEmergency,
        Image.ic16KeySandglass,
        Image.ic16Notification,
        Image.ic24ArrowRight,
        Image.ic24Close,
        Image.ic24Dots,
        Image.ic24DropdownDown,
        Image.ic24DropdownUp,
        Image.ic24FullscreenDisable,
        Image.ic24FullscreenEnable,
        Image.ic24ShareIos,
    ]

    var body: some View {
        TabStackedView(tabTitle: "Icons") {
            ForEach(0 ..< images.count) { index in
                images[index]
            }
            Spacer()
        }
        .foregroundColor(.tint)
    }
}

struct IconsView_Previews: PreviewProvider {
    static var previews: some View {
        IconsView()
    }
}
