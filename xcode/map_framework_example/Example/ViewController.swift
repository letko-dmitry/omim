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

    private lazy var mapEngine = MapEngine()
    private lazy var mapView = MapView(engine: mapEngine)

    private let annotation = Annotation(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.annotationManager.delegate = self

        contentView.addSubview(mapView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        mapView.annotationManager.add([annotation])
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
}

// MARK: - MapAnnotationManagerDelegate
extension ViewController: MapAnnotationManagerDelegate {
    func mapAnnotationManager(_ manager: MapAnnotationManager, didSelect annotation: MapAnnotation) {
        print("didSelect: \(annotation)")
    }

    func mapAnnotationManager(_ manager: MapAnnotationManager, didDeselect annotation: MapAnnotation) {
        print("didDeselect: \(annotation)")
    }
}
