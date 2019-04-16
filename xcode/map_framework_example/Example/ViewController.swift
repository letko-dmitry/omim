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
    private lazy var mapAnnotationManager = MapAnnotationManager(engine: mapEngine)

    private let annotation = Annotation(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    private var selectedAnnotation: Annotation?

    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.addSubview(mapView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        mapView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        mapAnnotationManager.add([annotation])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        mapView.delegate = nil
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

// MARK: - private
private extension ViewController {
    @IBAction func hanleTapOnButton() {
        if let deselectAnnotation = selectedAnnotation {
            selectedAnnotation = nil

            mapAnnotationManager.deselectAnnotations(deselectAnnotation)
        } else {
            selectedAnnotation = annotation

            mapAnnotationManager.selectAnnotations(annotation)
        }
    }
}
