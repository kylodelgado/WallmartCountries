//
//  ContentView.swift
//  WalmartCountriesAssessment
//
//  Created by Brandon on 3/10/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CountriesViewControllerRepresentable()
    }
}

struct CountriesViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CountriesViewController {
        return CountriesViewController()
    }
    
    func updateUIViewController(_ uiViewController: CountriesViewController, context: Context) {
    }
}

#Preview {
    ContentView()
}
