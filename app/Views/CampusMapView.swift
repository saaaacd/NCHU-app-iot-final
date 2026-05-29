//
//  CampusMapView.swift
//  NCHUHelper
//
//  Created by AI Assistant on 2025/9/23.
//

import SwiftUI
import MapKit
import UIKit

// MARK: - Building Annotation
class BuildingAnnotation: NSObject, MKAnnotation {
    let building: Building
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    init(building: Building) {
        self.building = building
        self.coordinate = CLLocationCoordinate2D(latitude: building.lat, longitude: building.lng)
        self.title = building.name
        self.subtitle = "大樓代號：\(building.code)"
        super.init()
    }
}

// MARK: - Campus Map View
struct CampusMapView: View {
    @StateObject private var buildingStore = BuildingStore()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.1201, longitude: 120.6737), // 中興大學位置
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map View
                MapViewRepresentable(
                    region: $region,
                    buildings: buildingStore.all,
                    onBuildingSelected: { building in
                        openGoogleMap(building: building)
                    }
                )
                .edgesIgnoringSafeArea(.all)
                
                // Controls Overlay
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        // Map Controls
                        VStack(spacing: 8) {
                            // Reset View Button
                            Button(action: resetMapView) {
                                Image(systemName: "location")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(theme.accent.color)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            
                            // Building Count Info
                            Text("\(buildingStore.all.count) 個建築物")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("校園地圖")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(theme.accent.color)
                }
            }
            .task {
                await loadBuildings()
            }
            .alert("錯誤", isPresented: $showingError) {
                Button("確定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadBuildings() async {
        await CampusUtils.loadBuildings(for: buildingStore)
        
        if let error = buildingStore.errorMessage, buildingStore.all.isEmpty {
            errorMessage = error
            showingError = true
        }
        
        print("📍 Map loaded \(buildingStore.all.count) buildings")
    }
    
    private func resetMapView() {
        withAnimation(.easeInOut(duration: 1.0)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 24.1201, longitude: 120.6737),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private func openGoogleMap(building: Building) {
        CampusUtils.openGoogleMap(for: building) { errorMessage in
            showError(errorMessage)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - MapKit UIViewRepresentable
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let buildings: [Building]
    let onBuildingSelected: (Building) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = false
        mapView.mapType = .standard
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if needed
        if !mapView.region.center.isEqual(to: region.center, tolerance: 0.0001) {
            mapView.setRegion(region, animated: true)
        }
        
        // Update annotations
        let currentAnnotations = mapView.annotations.compactMap { $0 as? BuildingAnnotation }
        let currentBuildingIDs = Set(currentAnnotations.map { $0.building.id })
        let newBuildingIDs = Set(buildings.map { $0.id })
        
        // Remove annotations that are no longer needed
        let annotationsToRemove = currentAnnotations.filter { !newBuildingIDs.contains($0.building.id) }
        mapView.removeAnnotations(annotationsToRemove)
        
        // Add new annotations
        let buildingsToAdd = buildings.filter { building in
            !currentBuildingIDs.contains(building.id) && building.lat != 0.0 && building.lng != 0.0
        }
        
        let newAnnotations = buildingsToAdd.map { BuildingAnnotation(building: $0) }
        mapView.addAnnotations(newAnnotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let buildingAnnotation = annotation as? BuildingAnnotation else {
                return nil
            }
            
            let identifier = "BuildingAnnotation"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            annotationView.annotation = annotation
            annotationView.markerTintColor = UIColor.systemBlue
            annotationView.glyphText = buildingAnnotation.building.code
            annotationView.canShowCallout = false
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let buildingAnnotation = view.annotation as? BuildingAnnotation else { return }
            mapView.deselectAnnotation(view.annotation, animated: false)
            parent.onBuildingSelected(buildingAnnotation.building)
        }
    }
}


// MARK: - CLLocationCoordinate2D Extension
extension CLLocationCoordinate2D {
    func isEqual(to other: CLLocationCoordinate2D, tolerance: Double) -> Bool {
        return abs(latitude - other.latitude) < tolerance &&
               abs(longitude - other.longitude) < tolerance
    }
}

// MARK: - Preview
#Preview {
    CampusMapView()
        .environmentObject(ThemeManager())
}
