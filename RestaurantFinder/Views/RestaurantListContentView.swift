//
//  RestaurantListContentView.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 25/04/2025.
//

import SwiftUI

struct RestaurantListContentView: View {
    @ObservedObject var viewModel: RestaurantListViewModel
    @Binding var searchText: String
    @Binding var selectedRestaurant: Restaurant?
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 20)
            
            SearchBarView(text: $searchText, onCancel: {
                searchText = ""
                viewModel.updateSearchText("")
            })
            .padding(.horizontal)
            
            contentState
        }
    }
    
    @ViewBuilder
    private var contentState: some View {
        switch (viewModel.isLoading, viewModel.filteredRestaurants.isEmpty) {
        case (true, _):
            LoadingStateView()
        case (false, true):
            EmptyStateView(searchText: searchText)
        case (false, false):
            RestaurantListStateView(
                viewModel: viewModel,
                selectedRestaurant: $selectedRestaurant
            )
        }
    }
}

// MARK: - Loading State
private struct LoadingStateView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State
private struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            if !searchText.isEmpty {
                Text("No restaurants found matching '\(searchText)'")
                    .foregroundColor(.secondary)
            } else {
                Text("No restaurants found nearby")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Restaurant List State
private struct RestaurantListStateView: View {
    @ObservedObject var viewModel: RestaurantListViewModel
    @Binding var selectedRestaurant: Restaurant?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredRestaurants) { restaurant in
                    Button {
                        selectedRestaurant = restaurant
                    } label: {
                        RestaurantRow(
                            restaurant: restaurant,
                            distance: viewModel.formattedDistance(to: restaurant)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
} 
