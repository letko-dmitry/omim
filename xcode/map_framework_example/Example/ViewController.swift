//
//  ViewController.swift
//  Test
//
//  Created by Dmitry Letko on 3/26/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

import UIKit
import MapsWithMeLib

final class ViewController: UIViewController {
    @IBOutlet private var contentView: UIView!

    private lazy var mapSymbols = [
        MapSymbols(name: "categories",
                   imageFileUrl: Bundle.main.url(forResource: "icons@3x", withExtension: "texture")!,
                   mapFileUrl: Bundle.main.url(forResource: "icons@3x", withExtension: "sdf")!)
    ]
    private lazy var mapEngine = MapEngine(symbols: mapSymbols)
    private lazy var mapView = MapView(engine: mapEngine)

    private let annotationA = Annotation(coordinate: CLLocationCoordinate2D(latitude: 53.93952, longitude: 27.598032))
    private let annotationB = Annotation(coordinate: CLLocationCoordinate2D(latitude: 53.93952 + 0.1, longitude: 27.598032 + 0.1))

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.annotationManager.delegate = self

        contentView.addSubview(mapView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.annotationManager.add([annotationA, annotationB])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        mapView.frame = contentView.bounds
    }
}

// MARK: - MapViewDelegate
extension ViewController: MapViewDelegate {
    func mapView(_ renderer: MapView, regionDidChangeAnimated animated: Bool) {
        let region = mapView.region

        print("region.topRight: \(region.topRight)")
        print("region.bottomLeft: \(region.bottomLeft)")
        print("-=-=-=")
    }

    func mapViewDidChangeCountry(_ view: MapView) {
        print("mapViewDidChangeCountry: \(view.countryIdentifier)")

        guard view.countryIdentifier == "Barbados" else { return }

        let fileUrl = Bundle.main.url(forResource: "Barbados", withExtension: "mwm")!

        print("fileUrl: \(fileUrl)")

        let country = MapCountry("Barbados", fileUrl: fileUrl)

        mapEngine.loadCountry(country)
    }
}

// MARK: - MapAnnotationManagerDelegate
extension ViewController: MapAnnotationManagerDelegate {
    func mapAnnotationManager(_ manager: MapAnnotationManager, didSelect annotation: MapAnnotation) {
        print("didSelect: \(annotation)")

        let region = MapViewRegion(topRight: annotationB.coordinate,
                                   bottomLeft: annotationA.coordinate)

        mapView.setRegion(region, edgeInsets: UIEdgeInsets(top: 30, left: 30, bottom: 200, right: 30), animated: true)
    }

    func mapAnnotationManager(_ manager: MapAnnotationManager, didDeselect annotation: MapAnnotation) {
        print("didDeselect: \(annotation)")
    }
}
