//
//  ContentView.swift
//  WalmartCountriesAssessment
//
//  Created by Brandon on 3/10/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        CountriesViewControllerRepresentable()
    }
}

struct CountriesViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let countriesVC = CountriesViewController()
        let navigationController = UINavigationController(rootViewController: countriesVC)
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No updates needed
    }
}

#Preview {
    ContentView()
}
