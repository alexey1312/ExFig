import FigmaAPI
import SwiftUI

// MARK: - Auth View

/// Main authentication view with OAuth and Personal Token tabs.
struct AuthView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Header
            header

            // Auth method picker
            Picker("Authentication Method", selection: $viewModel.selectedMethod) {
                ForEach(AuthMethod.allCases) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Method description
            Text(viewModel.selectedMethod.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Divider()
                .frame(maxWidth: 300)

            // Content based on selected method
            switch viewModel.selectedMethod {
            case .oauth:
                oauthContent
            case .personalToken:
                personalTokenContent
            }

            Spacer()

            // Status/Error message
            statusView
        }
        .padding(40)
        .frame(minWidth: 500, minHeight: 500)
        .task {
            await viewModel.checkExistingAuth()
        }
        .onReceive(NotificationCenter.default.publisher(for: .oauthCallback)) { notification in
            if let url = notification.userInfo?["url"] as? URL {
                Task {
                    await viewModel.handleOAuthCallback(url)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("ExFig Studio")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Connect your Figma account to get started")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - OAuth Content

    private var oauthContent: some View {
        VStack(spacing: 16) {
            switch viewModel.authState {
            case .authenticating:
                ProgressView()
                    .controlSize(.large)
                Text("Waiting for Figma authentication...")
                    .foregroundStyle(.secondary)

                Button("Cancel") {
                    Task {
                        await viewModel.cancelOAuth()
                    }
                }
                .buttonStyle(.bordered)

            case .authenticated:
                authenticatedContent

            default:
                Button {
                    Task {
                        await viewModel.startOAuthFlow()
                    }
                } label: {
                    Label("Sign in with Figma", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: 280)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    // MARK: - Personal Token Content

    private var personalTokenContent: some View {
        VStack(spacing: 16) {
            switch viewModel.authState {
            case .authenticated:
                authenticatedContent

            default:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Access Token")
                        .font(.headline)

                    SecureField("figd_xxxxxxxxxxxxxxxxxxxxxxxx", text: $viewModel.personalToken)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 360)
                        .disabled(viewModel.isValidatingToken)

                    Text("Get your token from Figma → Settings → Personal Access Tokens")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Link("Open Figma Settings", destination: URL(string: "https://www.figma.com/settings")!)
                        .font(.caption)
                }

                Button {
                    Task {
                        await viewModel.authenticateWithPersonalToken()
                    }
                } label: {
                    if viewModel.isValidatingToken {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Connect")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.personalToken.isEmpty || viewModel.isValidatingToken)
            }
        }
    }

    // MARK: - Authenticated Content

    private var authenticatedContent: some View {
        VStack(spacing: 16) {
            if case let .authenticated(user) = viewModel.authState, let user {
                // User avatar
                AsyncImage(url: URL(string: user.imgUrl)) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                    default:
                        ProgressView()
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())

                VStack(spacing: 4) {
                    Text(user.handle)
                        .font(.headline)

                    if let email = user.email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Label("Connected", systemImage: "checkmark.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("Connected to Figma")
                    .font(.headline)
            }

            Button("Sign Out") {
                Task {
                    await viewModel.signOut()
                }
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Status View

    @ViewBuilder
    private var statusView: some View {
        switch viewModel.authState {
        case let .error(message):
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
            .padding()
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

        default:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    AuthView(viewModel: AuthViewModel())
}
