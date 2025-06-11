// ToastView.swift
import SwiftUI

struct Toast: Equatable, Identifiable {
    var id = UUID()
    var style: ToastStyle
    var message: String
    var duration: Double = 3.0 // Default duration
    var width: Double = .infinity

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

enum ToastStyle {
    case error
    case warning
    case success
    case info

    var themeColor: Color {
        switch self {
        case .error: return ChikflixTheme.primary // Red for errors
        case .warning: return Color.orange
        case .success: return Color.green
        case .info: return ChikflixTheme.inputBackground // Dark gray for info
        }
    }

    var iconFileName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

struct ToastView: View {
    let style: ToastStyle
    let message: String
    let width: Double
    var onCancelTapped: (() -> Void)

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: style.iconFileName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(style.themeColor)

            Text(message)
                .font(ChikflixTheme.Fonts.caption) // Using Chikflix theme font
                .foregroundColor(ChikflixTheme.textPrimary) // White text

            Spacer(minLength: 10)

            // Removed explicit cancel button for auto-dismiss style
            // If needed, it can be added back:
            /*
            Button {
                onCancelTapped()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ChikflixTheme.textSecondary)
            }
            */
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: width)
        .background(ChikflixTheme.secondaryBackground) // Dark background similar to alerts
        .cornerRadius(ChikflixTheme.Dimensions.cornerRadius) // Consistent corner radius
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3) // Subtle shadow
        .overlay(
            Rectangle() // Left accent bar
                .fill(style.themeColor)
                .frame(width: 5)
                .cornerRadius(ChikflixTheme.Dimensions.cornerRadius, corners: [.topLeft, .bottomLeft]),
            alignment: .leading
        )
        .padding(.horizontal, 16) // Outer padding for the toast
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    mainToastView()
                        .offset(y: -30) // Adjust vertical offset from bottom
                }
                .animation(.spring(), value: toast)
            )
            .onChange(of: toast) { oldToast, newToast in
                showToast()
            }
    }

    @ViewBuilder func mainToastView() -> some View {
        if let toast = toast {
            VStack {
                Spacer() // Pushes toast to the bottom
                ToastView(
                    style: toast.style,
                    message: toast.message,
                    width: toast.width
                ) {
                    dismissToast()
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func showToast() {
        guard let toast = toast else { return }

        // Haptic feedback for info toasts
        if toast.style == .info || toast.style == .success {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }


        if toast.duration > 0 {
            workItem?.cancel()

            let task = DispatchWorkItem {
                dismissToast()
            }
            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
        }
    }

    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        workItem?.cancel()
        workItem = nil
    }
}

extension View {
    func toastView(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}
