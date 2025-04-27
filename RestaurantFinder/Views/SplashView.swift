//
//  SplashView.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 21/4/2025.
//

import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5
    @State private var ajiOffset: CGFloat = -200
    @State private var taklOffset: CGFloat = 200
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Image("AjiTaklIcon2")
                    .frame(width: 300, height: 300)
                    .foregroundColor(Color(red: 1, green: 0.6784313725490196, blue: 0))

                HStack(spacing: 0) {
                    Text("Aji")
                        .foregroundColor(Color(red: 0.980, green: 0.306, blue: 0.004))
                        .offset(x: ajiOffset)
                    
                    Text("Takl")
                        .foregroundColor(Color(red: 1, green: 0.6784313725490196, blue: 0))
                        .offset(x: taklOffset)
                }
                .font(.system(size: 70))
                .fontWeight(.bold)
                .padding(.top, 16)
                
                Spacer()
                Spacer()
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.1)) {
                    scale = 1.0
                    opacity = 1.0
                }
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                    ajiOffset = 0
                }
                
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
                    taklOffset = 0
                }
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}

