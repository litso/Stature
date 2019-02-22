//
//  VerticalMeasurementController.swift
//  Stature
//
//  Created by Robert Manson on 2/21/19.
//

import UIKit
import SceneKit
import ARKit

class VerticalMeasurementController: UIViewController {

    @IBOutlet weak var measureButton: BannerButton!
    @IBOutlet var sceneView: ARSCNView!
    var audioVolumeChanged: NSKeyValueObservation?
    var grids: [Grid] = []
    var selectedGrid: Grid? {
        get {
            return grids.first(where: { $0.isSelected })
        }
        set {
            guard let newValue = newValue else {
                grids.forEach { $0.isSelected = false }
                return
            }
            guard let index = grids.index(where: { $0.anchor.identifier == newValue.anchor.identifier }) else {
                return
            }

            grids.forEach { $0.isSelected = false }
            grids[index].isSelected = true
        }
    }

    var distanceMeasurement: Measurement<UnitLength>? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.measureButton.isHidden = self?.distanceMeasurement == nil
            }
        }
    }

    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    lazy var statusViewController: StatusViewController? = children.compactMap({ $0 as? StatusViewController }).first

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self

        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
//        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints

        let scene = SCNScene()
        sceneView.scene = scene

        statusViewController?.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectGrid(_:)))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        tapGesture.delegate = self
        sceneView.addGestureRecognizer(tapGesture)

        let audioSession = AVAudioSession.sharedInstance()

        try? audioSession.setCategory(.playback, mode: .measurement, options: .mixWithOthers)
        audioSession.addObserver(self, forKeyPath: "outputVolume",
                                 options: NSKeyValueObservingOptions.new, context: nil)

        audioVolumeChanged = audioSession.observe(\.outputVolume, options: [.new, .old]) { [weak self] _, _  in
            guard let self = self else { return }
            if self.distanceMeasurement != nil {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "Show Measurement", sender: self)
                }
            }
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAudioInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppBecameActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resetTracking()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sceneView.session.pause()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ShowMeasurementController {
            viewController.measurement = distanceMeasurement
        }
    }

    @IBAction func measureButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "Show Measurement", sender: self)
    }
}

// MARK: - Audio Session Management

extension VerticalMeasurementController {
    @objc func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    let audioSession = AVAudioSession.sharedInstance()
                    try? audioSession.setActive(true, options: [])
                }
            }
        }
    }

    @objc func handleAppBecameActive(_: Notification) {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(true, options: [])
    }
}

// MARK: - Tap Gesture Recognizer

extension VerticalMeasurementController: UIGestureRecognizerDelegate {
    @IBAction func selectGrid(_ sender: UITapGestureRecognizer) {
        statusViewController?.cancelScheduledMessage(for: .selectGrid)

        let tapPoint = sender.location(in: sceneView)

        let results = sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)

        guard let result = results.first,
            let identifier = result.anchor?.identifier,
            let grid = grids.first(where: { $0.anchor.identifier == identifier })  else {
            return
        }

        print("Grid Selected")

        selectedGrid = grid

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        sceneView.session.run(configuration)
    }

    /// Determines if the tap gesture for presenting the `VirtualObjectSelectionViewController` should be used.
    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return selectedGrid == nil
    }
}

// MARK: - Session Helpers

private extension VerticalMeasurementController {
    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        grids = []
        distanceMeasurement = nil
    }

    func restartExperience() {
        guard isRestartAvailable else { return }
        isRestartAvailable = false

        statusViewController?.cancelAllScheduledMessages()

        resetTracking()

        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }

    func displayErrorMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - ARSCNViewDelegate

extension VerticalMeasurementController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        let grid = Grid(anchor: anchor)
        self.grids.append(grid)
        node.addChildNode(grid)

        if selectedGrid == nil {
            statusViewController?.showMessage("Tap the floor", messageType: .selectGrid)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }

        guard let foundGrid = self.grids.first( where: { $0.anchor.identifier == anchor.identifier }) else {
            return
        }

        foundGrid.update(anchor: anchor)
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let selectedGrid = selectedGrid,
            let distance = verticalDistanceFromCamera(to: selectedGrid.anchor) {
            let distanceMeasurement = Measurement<UnitLength>(value: Double(distance), unit: .meters)
            self.distanceMeasurement = distanceMeasurement
            statusViewController?.showMessage(distanceMeasurement.inchesDescription, messageType: .heightReading)
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        guard selectedGrid == nil else { return }
        statusViewController?.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)

        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController?.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController?.cancelScheduledMessage(for: .trackingStateEscalation)
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }

        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]

        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")

        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
}

private extension VerticalMeasurementController {
    func verticalDistanceFromCamera(to anchor: ARAnchor) -> Float? {
        guard let currentFrame = sceneView.session.currentFrame else { return nil }

        let camera = currentFrame.camera
        let anchorPosition = anchor.transform.columns.3
        let cameraPosition = camera.transform.columns.3

        return abs(cameraPosition.y - anchorPosition.y)
    }
}
