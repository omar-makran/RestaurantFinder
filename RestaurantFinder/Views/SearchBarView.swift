//
//  SearchBarView.swift
//  RestaurantFinder
//
//  Created by Omar Makran on 21/4/2025.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var isEditing = false
    
    var onCancel: () -> Void
    
    private let primaryColor = Color(red: 0.98, green: 0.306, blue: 0.004)
    private let secondaryColor = Color(red: 1, green: 0.678, blue: 0)
    
    var body: some View {
        HStack(spacing: 12) {
            // search icon and text field container
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isFocused ? primaryColor : .gray)
                    .padding(.leading, 12)
                
                TextField("Search restaurants...", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .frame(height: 44)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                if !text.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            text = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(primaryColor)
                            .padding(.trailing, 12)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                    .shadow(
                        color: colorScheme == .dark ? .clear : Color.black.opacity(0.1),
                        radius: 5,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isFocused ?
                        AnyShapeStyle(LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )) :
                        AnyShapeStyle(Color.clear),
                        lineWidth: isFocused ? 2 : 0
                    )
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .onTapGesture {
                isFocused = true
            }
            
            // cancel button
            if isFocused {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        text = ""
                        isFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        onCancel()
                    }
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(primaryColor)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
    
    init(text: Binding<String>, onCancel: @escaping () -> Void) {
        self._text = text
        self.onCancel = onCancel
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SearchBarView(text: .constant("Sushi"), onCancel: {})
                .preferredColorScheme(.light)
                .previewLayout(.sizeThatFits)
                .padding()
            
            SearchBarView(text: .constant(""), onCancel: {})
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}
