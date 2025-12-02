import SwiftUI

struct IllustrationsView: View {
    var body: some View {
        TabStackedView(tabTitle: "Illustrations") {
            Image.imgZeroEmpty
            Image.imgZeroError
            Image.imgZeroInternet
            Spacer()
        }
    }
}

struct IllustrationsView_Previews: PreviewProvider {
    static var previews: some View {
        IllustrationsView()
    }
}
