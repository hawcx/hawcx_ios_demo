//
//  HomeView.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//

import SwiftUI
import HawcxFramework

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showProfileMenu = false
    
    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel())
    }
    
    var body: some View {
        ZStack {
            // Netflix-style dark background
            ChikflixTheme.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Netflix-style header
                headerView
                
                // Main content area
                ScrollView {
                    VStack(spacing: 20) {
                        // Hero banner content
                        featuredContentView
                        
                        // Content rows
                        contentCategoryRow(title: "Popular on Chikflix", items: generateDummyContent(count: 8))
                        contentCategoryRow(title: "Continue Watching", items: generateDummyContent(count: 5))
                        contentCategoryRow(title: "New Releases", items: generateDummyContent(count: 7))
                        contentCategoryRow(title: "TV Shows", items: generateDummyContent(count: 6))
                        
                        // Space at bottom
                        Spacer(minLength: 20)
                    }
                }
                
                // Netflix-style footer tab bar
                footerTabBar
            }
            .onAppear {
                viewModel.appViewModel = appViewModel
                viewModel.username = appViewModel.loggedInUsername ?? "User"
            }
            
            // Profile menu overlay (if shown)
            if showProfileMenu {
                profileMenuOverlay
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $viewModel.navigateToWebLogin) {
            WebLoginView(appViewModel: appViewModel)
                .environmentObject(appViewModel)
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            // Chikflix logo
            Text("CHIKFLIX")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ChikflixTheme.primary)
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 20) {
                // Web Login button (styled as Cast icon)
                Button {
                    viewModel.webLoginButtonTapped()
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.title3)
                        .foregroundColor(ChikflixTheme.textPrimary)
                }
                
                // Profile menu button
                Button {
                    withAnimation {
                        showProfileMenu.toggle()
                    }
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(ChikflixTheme.textPrimary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(ChikflixTheme.background.opacity(0.95))
    }

    private var featuredContentView: some View {
        ZStack(alignment: .bottom) {
            // NETFLIX-STYLE BACKGROUND WITH MULTI-LAYERED EFFECTS
            ZStack {
                // Base image - Replace "Dev1" with your image name
                Image("Team")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 500)
                    .brightness(-0.1) // Slightly darken the image
                
                // First overlay - dark vignette effect
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.7)
                    ]),
                    center: .center,
                    startRadius: 150,
                    endRadius: 300
                )
                .opacity(0.7)
                
                // Second overlay - color tint (use your brand color)
                ChikflixTheme.primary
                    .opacity(0.15)
                    .blendMode(.overlay)
                
                // Third overlay - film grain texture for cinematic feel
                Color.black
                    .opacity(0.05)
                    .blendMode(.multiply)
            }
            .frame(height: 500)
            .clipped()
            .overlay(
                // Content overlay with your logo and text
                VStack(spacing: 15) {
                    Text("CHIKFLIX ORIGINAL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(ChikflixTheme.textPrimary)
                        .padding(.top, 100)
                        .padding(.horizontal, 20)
                        .background(
                            // Optional text background for better legibility
                            Color.black.opacity(0.3)
                                .blur(radius: 5)
                        )
                    
                    Text("SECURE CONNECTION")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(ChikflixTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                        .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 2)
                    
                    Color.clear
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
                        .padding(.top, 30)
                }
            )
            
            // Bottom gradient overlay for content fade
            LinearGradient(
                gradient: Gradient(colors: [
                    ChikflixTheme.background.opacity(0),
                    ChikflixTheme.background.opacity(0.8),
                    ChikflixTheme.background
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            
            // Action buttons
            VStack(spacing: 15) {
                // Genre tags
                HStack(spacing: 15) {
                    Text("Secure")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(3)
                    
                    Text("Passwordless")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(3)
                    
                    Text("Fast")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(3)
                }
                .padding(.bottom, 5)
                
                // Main buttons
                HStack(spacing: 10) {
                    // Play button (styled for devices list)
                    Button {
                    } label: {
                        HStack {
                            Image(systemName: "iphone.gen3")
                            Text("My Devices")
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .frame(height: 42)
                        .background(ChikflixTheme.textPrimary)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                    }
                    
                    // More Info button (for web login)
                    Button {
                        viewModel.webLoginButtonTapped()
                    } label: {
                        HStack {
                            Image(systemName: "qrcode")
                            Text("Web Login")
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .frame(height: 42)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(ChikflixTheme.textPrimary)
                        .cornerRadius(4)
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    private func contentCategoryRow(title: String, items: [DummyContent]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(ChikflixTheme.textPrimary)
                .padding(.leading, 15)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(items) { item in
                        contentThumbnail(item)
                    }
                }
                .padding(.horizontal, 15)
            }
        }
        .padding(.top, 5)
    }
    
    private func contentThumbnail(_ content: DummyContent) -> some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(content.color)
                .frame(width: 110, height: 160)
                .cornerRadius(4)
                .overlay(
                    Image(systemName: content.icon)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )
        }
    }
    
    private var footerTabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(title: "Home", icon: "house.fill", isSelected: true)
            tabBarButton(title: "New & Hot", icon: "play.circle", isSelected: false)
            tabBarButton(title: "My Devices", icon: "iphone.gen3", isSelected: false)
            tabBarButton(title: "My Chikflix", icon: "person.circle", isSelected: false) {
                withAnimation {
                    showProfileMenu.toggle()
                }
            }
        }
        .padding(.vertical, 10)
        .background(ChikflixTheme.background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
    
    private func tabBarButton(title: String, icon: String, isSelected: Bool, action: (() -> Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? ChikflixTheme.textPrimary : ChikflixTheme.textSecondary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? ChikflixTheme.textPrimary : ChikflixTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var profileMenuOverlay: some View {
        ZStack(alignment: .topTrailing) {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        showProfileMenu = false
                    }
                }
            
            // Menu panel
            VStack(alignment: .leading, spacing: 15) {
                // Header with username
                HStack {
                    Text(viewModel.username)
                        .font(.headline)
                        .foregroundColor(ChikflixTheme.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            showProfileMenu = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(ChikflixTheme.textSecondary)
                    }
                }
                .padding(.bottom, 5)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Menu options
                Button {
                    withAnimation {
                        showProfileMenu = false
                    }
                } label: {
                    menuItem(icon: "iphone.gen3", title: "Manage Devices")
                }
                
                Button {
                    viewModel.webLoginButtonTapped()
                    withAnimation {
                        showProfileMenu = false
                    }
                } label: {
                    menuItem(icon: "qrcode.viewfinder", title: "Web Login")
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Logout button
                Button {
                    viewModel.logoutButtonTapped()
                } label: {
                    menuItem(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out")
                        .foregroundColor(ChikflixTheme.primary)
                }
                
                Spacer()
                
                // Hawcx attribution
                ChikflixFooterView()
            }
            .padding(20)
            .frame(width: 270)
            .background(ChikflixTheme.secondaryBackground)
            .cornerRadius(4, corners: [.topLeft, .bottomLeft])
            .shadow(color: .black.opacity(0.5), radius: 10, x: -5, y: 0)
            .padding(.top, 55) // Adjust to header height
            .transition(.move(edge: .trailing))
        }
        .zIndex(1)
    }
    
    private func menuItem(icon: String, title: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
            
            Text(title)
                .font(.system(size: 16))
        }
        .foregroundColor(ChikflixTheme.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
    
    // MARK: - Helper Methods
    
    private func generateDummyContent(count: Int) -> [DummyContent] {
        let icons = ["film", "tv", "play.rectangle", "play.circle", "rectangle.stack", "person.2", "star", "heart"]
        let colors: [Color] = [
            Color(hex: "E50914").opacity(0.7),
            Color(hex: "8E44AD"),
            Color(hex: "2980B9"),
            Color(hex: "16A085"),
            Color(hex: "F39C12"),
            Color(hex: "D35400"),
            Color(hex: "C0392B"),
            Color(hex: "1E8449")
        ]
        
        return (0..<count).map { index in
            let iconIndex = index % icons.count
            let colorIndex = index % colors.count
            return DummyContent(
                id: UUID(),
                title: "Content \(index + 1)",
                icon: icons[iconIndex],
                color: colors[colorIndex]
            )
        }
    }
}

// MARK: - Support Structs

// Dummy content for the UI
struct DummyContent: Identifiable {
    let id: UUID
    let title: String
    let icon: String
    let color: Color
}

// Custom corner radius modifier
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Custom shape for specific corner rounding
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
