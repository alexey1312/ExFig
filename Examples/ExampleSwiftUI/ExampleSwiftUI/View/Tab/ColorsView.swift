import SwiftUI

struct ColorsView: View {
    @State
    private var slider: CGFloat = 0.5

    var body: some View {
        TabStackedView(tabTitle: "Colors") {
            Text("Text on primary background")
                .font(.body())
                .foregroundColor(.textSecondary)

            HStack {
                Text("Text on secondary background")
                    .font(.body())
                    .padding()
                Spacer()
            }
            .background(Color.backgroundSecondary)

            Text("Tint")
                .font(.body())
                .foregroundColor(.textSecondary)

            Button(
                action: {},
                label: {
                    Text("Button")
                        .font(.body())
                }
            )

            Slider(value: $slider, in: 0 ... 1)

            Spacer()

            Button(
                action: {
                    //
                },
                label: {
                    Text("Solid button")
                        .font(.body())
                        .foregroundColor(.textPrimary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            Rectangle()
                                .cornerRadius(12, antialiased: true)
                                .foregroundColor(Color.button)
                        )
                }
            )
        }
    }
}

struct ColorsView_Previews: PreviewProvider {
    static var previews: some View {
        ColorsView()
            .accentColor(.tint)
    }
}
