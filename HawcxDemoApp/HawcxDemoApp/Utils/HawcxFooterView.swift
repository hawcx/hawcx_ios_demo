//
//  HawcxFooterView.swift
//  HawcxDemoApp
//
//  Created by Agam Bhullar on 4/15/25.
//

import SwiftUI

struct HawcxFooterView: View {
    var body: some View {
        VStack(spacing: 5) {
            Divider()
                .padding(.horizontal, 40)
//                .padding(.bottom, 5)
            
            HStack(spacing: 8) {
                // Small Hawcx logo image (use the actual logo if available)
                Image("Hawcx_Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                
                Text("Powered by Hawcx©")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
//            Text("All Rights Reserved.")
//                .font(.system(size: 12))
//                .foregroundColor(.gray)
//                .padding(.bottom, 8)
        }

    }
}

// Alternative version without Image dependency for previews or if logo is unavailable
struct HawcxTextFooterView: View {
    var body: some View {
        VStack(spacing: 10) {
            Divider()
                .padding(.horizontal, 40)
                .padding(.bottom, 5)
            
            HStack(spacing: 6) {
                // Logo symbol using SF Symbol as an alternative
                Image(systemName: "shield.checkmark.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.blue)
                
                Text("Powered by Hawcx")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text("© \(Calendar.current.component(.year, from: Date())) Hawcx Security. All Rights Reserved.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    HawcxFooterView()
}
