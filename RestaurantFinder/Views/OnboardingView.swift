//
//  SplashView.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 21/4/2025.
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private let pages: [OnboardingPage] = [
        .init(image: "findingDelicous",
              title: "AjiTakl Finder",
              description: "Your go‑to app for finding delicious food wherever you are."),
        .init(image: "FindTheBest",
              title: "Discover Nearby",
              description: "Find the best restaurants within walking distance from your location."),
        .init(image: "searchRestau",
              title: "Search & Filter",
              description: "Easily search by name or cuisine to find exactly what you're craving.")
    ]

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        UIPageControl.appearance().currentPageIndicatorTintColor =
            UIColor(red: 1, green: 0.678, blue: 0, alpha: 1)
    }

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: 20) {
                        Image(pages[index].image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350, height: 350)
                            .scaleEffect(currentPage == index ? 1 : 0.8)
                            .offset(y: currentPage == index ? 0 : 100)
                            .rotation3DEffect(
                                .degrees(currentPage == index ? 0 : 10),
                                axis: (x: 1, y: 0, z: 0)
                            )
                            .animation(.spring(response: 0.6, dampingFraction: 0.7),
                                       value: currentPage)

                        Text(pages[index].title)
                            .font(.largeTitle).bold()
                            .multilineTextAlignment(.center)
                            .opacity(currentPage == index ? 1 : 0)
                            .offset(y: currentPage == index ? 0 : 30)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8)
                                        .delay(0.2), value: currentPage)

                        Text(pages[index].description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .opacity(currentPage == index ? 1 : 0)
                            .offset(y: currentPage == index ? 0 : 20)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8)
                                        .delay(0.3), value: currentPage)
                            .padding(.horizontal, 40)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .animation(.spring(), value: currentPage)
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))

            Spacer()

            // MARK: — Bottom‑center Button
            Button {
                if currentPage < pages.count - 1 {
                    currentPage += 1
                } else {
                    onComplete()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                    .font(.headline)
                    .frame(width: 200, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.306, blue: 0.004),
                                        Color(red: 1,    green: 0.678, blue: 0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .foregroundColor(.white)
            }
            .shadow(color: Color(red: 0.98, green: 0.306, blue: 0.004).opacity(0.3),
                    radius: 6, x: 0, y: 4)
            .modifier(PulseAnimation())
            .padding(.bottom, 40)
        }
    }
}

// MARK: — Button Pulse Animation
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

// MARK: — Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingView(onComplete: {}).preferredColorScheme(.light)
            OnboardingView(onComplete: {}).preferredColorScheme(.dark)
        }
    }
}
