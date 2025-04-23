//
//  HomeView.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/14/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject var appViewModel: AppViewModel

    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel())
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 0) { // Remove default spacing, manage manually
                    Image("Hawcx_Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                        .clipped()
                        .overlay (
                            Text("HAWCX")
                                .font(.system(size: 60, weight: .medium, design: .serif))
                                .padding(.top, 150)
                                

                        )
                        .padding(.bottom, 50)
                    
                    VStack(spacing: 10) {
                        Text("Welcome to Hawcx")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(viewModel.username) // Display username from ViewModel
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("This is a sample app built using the Hawcx passwordless framework. You can take this as a template and build your application on top of this.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal) // Padding within the banner
                    }
                    .foregroundColor(.white) // Text color inside banner
                    .padding(.vertical, 20) // Vertical padding inside banner
                    .frame(maxWidth: .infinity) // Make banner full width
                    .background(Color.blue) // Banner background color
                    .cornerRadius(10) // Add rounded corners
              
                }
            }
            
            Spacer() // Pushes buttons to the bottom
            
            VStack(spacing: 15) {
                Button {
                    viewModel.logoutButtonTapped()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity) // Make button wide
                }
                .primaryButtonStyle() // Use primary style
                .tint(.red) // Use red tint for logout
                .padding(.horizontal)
            }
            .padding(.bottom) // Add padding at the bottom
        }
        .padding(.horizontal, 15)
        .onAppear {
            viewModel.appViewModel = appViewModel
            viewModel.username = appViewModel.loggedInUsername ?? "User"
        }
        .navigationTitle("Home") // Set navigation bar title
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}
