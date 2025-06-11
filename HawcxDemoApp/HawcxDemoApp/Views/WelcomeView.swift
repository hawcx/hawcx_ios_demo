import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var currentPage = 0
    // Removed: @State private var navigateToLogin = false // No longer needed directly
    
    var body: some View {
        // NavigationStack is now managed by ContentView
        ZStack {
            ChikflixTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("CHIKFLIX")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(ChikflixTheme.primary)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(ChikflixTheme.textPrimary)
                            .rotationEffect(.degrees(90))
                    }
                    .padding(.horizontal, 5)
                    
                    // UPDATED NavigationLink to AuthenticateView
                    NavigationLink(destination: AuthenticateView(appViewModel: appViewModel)) {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.darkGray))
                            .foregroundColor(ChikflixTheme.textPrimary)
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                ScrollView {
                    contentGridView
                }
                
                Spacer()
                ChikflixFooterView()
            }
        }
        // Removed .environmentObject(appViewModel) as it's inherited
    }
    
    // Content grid view with movie/show tiles (No changes needed here)
    private var contentGridView: some View {
        ZStack(alignment: .bottom) {
            // Grid of content tiles
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 4) {
                // First row - Pass image names and hue colors
                contentTile(imageName: "Dev1", hueColor: .red, title: "ADOLESCENCE")
                contentTile(imageName: "Dev4", hueColor: .orange, title: "DEN OF THIEVES 2")
                contentTile(imageName: "Dev3", hueColor: .blue, title: "HOSTAGE")
                
                // Second row
                contentTile(imageName: "Dev2", hueColor: .purple, title: "MOVIE CLUB")
                contentTile(imageName: "Dev5", hueColor: .red, title: "YOU")
                contentTile(imageName: "Dev7", hueColor: .teal, title: "BLACK MIRROR")
                
                // Third row
                contentTile(imageName: "Dev6", hueColor: .yellow, title: "LOVE ON THE SPECTRUM")
                contentTile(imageName: "Dev8", hueColor: .green, title: "RANSOM CANYON")
                contentTile(imageName: "Dev9", hueColor: .pink, title: "HAVOC")
            }
            .padding(4)
            
            // Dark gradient overlay at bottom
            LinearGradient(
                gradient: Gradient(colors: [
                    ChikflixTheme.background.opacity(0),
                    ChikflixTheme.background.opacity(0.4),
                    ChikflixTheme.background.opacity(0.8),
                    ChikflixTheme.background
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 350)
            
            // Text overlay
            VStack(spacing: 10) {
                Text("Movies, shows, and")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("games in just a few taps")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Pagination dots
                HStack(spacing: 8) {
                    Circle()
                        .fill(currentPage == 0 ? Color.white : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(currentPage == 1 ? Color.white : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
                .padding(.top, 20)
            }
        }
    }
    
    // Enhanced content tile function with color hue overlay (No changes needed here)
    private func contentTile(
        imageName: String? = nil,
        color: Color = .gray.opacity(0.3),
        hueColor: Color? = nil,
        hueIntensity: Double = 0.3,
        title: String
    ) -> some View {
        VStack(alignment: .leading) {
            ZStack {
                // Fallback colored background
                Rectangle()
                    .fill(color)
                
                // Image if provided
                Group {
                    if let imageName = imageName, UIImage(named: imageName) != nil {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // Show placeholder if image isn't found
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(30)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .overlay(
                    // Netflix-style color hue effect
                    ZStack {
                        // First add a slight darkening
                        Color.black.opacity(0.2)
                        
                        // Then add the color hue overlay with blend mode
                        if let hueColor = hueColor {
                            hueColor
                                .opacity(hueIntensity)
                                .blendMode(.overlay)
                        }
                    }
                )
                
                // Semi-transparent gradient for better text visibility at bottom
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.7)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                }
                
                // Title text
                VStack {
                    Spacer()
                    Text(title)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(8)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .aspectRatio(0.7, contentMode: .fit)
            .cornerRadius(10)
            .clipped()
            
            // Add subtle shadow for depth
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
        }
    }
    
    // Alternate version with more Netflix-like styling (No changes needed here)
    private func netflixStyleTile(
        imageName: String? = nil,
        primaryColor: Color,
        title: String
    ) -> some View {
        VStack(alignment: .leading) {
            ZStack {
                // Base image
                Group {
                    if let imageName = imageName, UIImage(named: imageName) != nil {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // Placeholder
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(30)
                                    .foregroundColor(.white.opacity(0.7))
                            )
                    }
                }
                
                // Multi-layered Netflix style color grading
                Group {
                    // Subtle darkening
                    Color.black.opacity(0.3)
                    
                    // Primary color with blend mode
                    primaryColor
                        .opacity(0.5)
                        .blendMode(.softLight)
                    
                    // Secondary highlight tint (often opposite the primary color)
                    complementaryColor(for: primaryColor)
                        .opacity(0.2)
                        .blendMode(.overlay)
                    
                    // Grain texture for film-like quality (optional)
//                    Image("noise_texture") // Ensure you have this image or remove
//                        .resizable()
//                        .opacity(0.05)
//                        .blendMode(.overlay)
                }
                
                // Bottom gradient for text legibility
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                }
                
                // Netflix logo "N" watermark in corner (optional)
                VStack {
                    HStack {
                        Text("N")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.red)
                            .padding(6)
                        Spacer()
                    }
                    Spacer()
                }
            }
            .aspectRatio(0.7, contentMode: .fit)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
            
            // Title below image
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .padding(.top, 4)
        }
    }
    
    // Helper to generate complementary color (No changes needed here)
    private func complementaryColor(for color: Color) -> Color {
        let uiColor = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let complementaryHue = h < 0.5 ? h + 0.5 : h - 0.5
        return Color(UIColor(hue: complementaryHue, saturation: s, brightness: b, alpha: a))
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(AppViewModel()) // Ensure AppViewModel is provided
            .preferredColorScheme(.dark)
    }
}
