//
//  ContentView.swift
//  FirstProject
//
//  Created by maksimchernukha on 06.09.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var isEnglish: Bool = true
    @State private var showMainPage: Bool = false
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer(minLength: 200)
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.red.opacity(0.8))
                            .frame(width: 120, height: 120)
                        Text("T")
                            .font(.system(size: 80, weight: .black, design: .serif))
                            .foregroundColor(Color(.systemBackground))
                    }
                    Text(isEnglish ? "Welcome to To-Do List!" : "Добро пожаловать в To-Do!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    Button(action: {
                        showMainPage = true
                    }) {
                        Text(isEnglish ? "Continue" : "Продолжить")
                            .multilineTextAlignment(.center)
                            .frame(width: 120, height: 40)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(40)
                    }
                    Spacer()
                    Button(action: {
                        isEnglish.toggle()
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text(isEnglish ? "Change Language" : "Сменить язык")
                                .fontWeight(.heavy)
                                .foregroundColor(.blue)
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
            // Use a hidden NavigationLink to navigate programmatically
            NavigationLink("", isActive: $showMainPage) {
                MainPageView()
            }
            .hidden()
        }
    }
}

#Preview {
    ContentView()
}

struct ZMainPageView: View {
    var body: some View {
        Text("Main Page")
    }
}
