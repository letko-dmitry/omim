//
//  Annotation.swift
//  MapsWithMeLibExample
//
//  Created by Dmitry Letko on 4/15/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

import CoreLocation
import MapsWithMeLib

final class Annotation: NSObject, MapAnnotation {
    let coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
