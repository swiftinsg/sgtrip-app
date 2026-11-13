//
//  WelcomePage.swift
//  SGTrip
//
//  Created by Shivika on 13/11/26.
//

import SwiftUI
import MapKit

struct WelcomePage: View {
    let tower = CLLocationCoordinate2D(latitude: 1.284539, longitude: 103.782493)
    var body: some View {
        Map()
    }
}
#Preview {
    WelcomePage()
}
