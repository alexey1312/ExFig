import SwiftUI

struct TabStackedView<Content>: View where Content: View {
    let tabTitle: String
    let content: () -> Content

    init(tabTitle: String, @ViewBuilder content: @escaping () -> Content) {
        self.tabTitle = tabTitle
        self.content = content
    }

    var body: some View {
        NavigationView {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 16) {
                    content()
                }
                Spacer()
            }
            .navigationBarTitle(tabTitle)
            .padding()
            .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
        }
    }
}

struct TabStackedView_Previews: PreviewProvider {
    static var previews: some View {
        TabStackedView(tabTitle: "Hey") {
            Text("123")
            Spacer()
            Text("456")
        }
    }
}
