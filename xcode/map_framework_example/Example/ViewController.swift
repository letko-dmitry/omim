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

    private lazy var renderer = MWMapViewRenderer()

    override func viewDidLoad() {
        super.viewDidLoad()

        renderer.mapDownloadingDelegate = self
        renderer.setup(with: contentView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        renderer.handleViewWillApear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        renderer.handleViewDidDisappear()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        renderer.handleViewDidLayoutSubviews()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        renderer.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        renderer.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        renderer.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        renderer.touchesCancelled(touches, with: event)
    }
}

extension ViewController: MWMMapDownloadingDelegate {
    func handleMapDownloaded() {

    }

    func handleMapLoadingQueued() {

    }

    func handleMapLoadingFinishedWithError() {

    }

    func handleMapLoadingProgress(_ progress: CGFloat) {
        
    }
}
