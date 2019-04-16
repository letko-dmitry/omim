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
    func mapViewDidChangeRegion(_ view: MapView) {
        let region = mapView.region

        print("region.topRight: \(region.topRight)")
        print("region.bottomLeft: \(region.bottomLeft)")
    }
}
