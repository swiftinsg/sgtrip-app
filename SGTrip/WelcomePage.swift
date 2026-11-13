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

    // Rough bounding box around Singapore, so the map can't pan away from it.
     let singaporeRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
        span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
    )

     var singaporeBounds: MapCameraBounds {
        MapCameraBounds(
            centerCoordinateBounds: singaporeRegion,
            minimumDistance: 1000,
            maximumDistance: 30000
        )
    }

    @State  var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
            span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        )
    )

    var body: some View {
        TabView{
            Tab("map",systemImage:"map"){
                RecommendationTab()
            }
            Tab("home",systemImage: "house") {
                VStack{
                    Text("SGTrip")
                        .font(.largeTitle)
                        .bold()
                    
                    GeometryReader { proxy in
                        VStack(spacing: 0) {
                            Map(position: $position, bounds: singaporeBounds) {
                                Marker("Haw Par Villa", systemImage: "building", coordinate: tower)
                            }
                            // Only take up half of the screen height.
                            .frame(height: proxy.size.height * 0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            
            Tab("memories",systemImage: "heart"){
                MemoriesTab()
            }
        }
    }
}

#Preview {
    WelcomePage()
}
