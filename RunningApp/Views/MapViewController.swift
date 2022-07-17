//
//  ViewController.swift
//  RunningApp
//
//  Created by Julian Worden on 7/9/22.
//

// Hi Nate! This is my first time using a State enum for tracking states,
// Combine, and MVVM. I'd love to hear how I did and whether or not
// there are any best practices you'd recommend I adhere to. Thanks!

// NOTE: When running this app on Simulator, it will crash the first
// time location tracking is approved. This crash does not occur on a
// real device. This occurs because the viewModel.showUserLocationOnMap() method
// attempts to access the currentUserCoordinates property in locationService before
// it is set by the locationManagerDidChangeAuthorization CLLocationManagerDelegate
// method. That's because the CLLocationManagerDelegate methods aren't run when
// expected in Simulator, but they are run as expected on a real device.

import Combine
import MapKit
import UIKit

class MapViewController: UIViewController {
    enum State {
        case loaded
        case runStarted
        case runEnded
        case error
    }

    let viewModel = MapViewModel()
    var subscribers = Set<AnyCancellable>()
    var polylineSubscriber: AnyCancellable?
    var locationService = LocationService.instance

    let screenshot = UIImageView()
    let mapView = MKMapView()
    let infoView = UIView()
    let centerUserLocationButton = UIButton(configuration: .plain())
    let shareButton = UIButton(configuration: .plain())
    let totalDistanceTraveledLabel = UILabel()
    lazy var unitOfMeasurementStack = UIStackView(arrangedSubviews: [unitOfMeasurementLabel, unitOfMeasurementSelector])
    let unitOfMeasurementLabel = UILabel()
    let unitOfMeasurementSelector = UISegmentedControl()
    lazy var startStopButtonStack = UIStackView(arrangedSubviews: [startRunButton, endRunButton])
    let startRunButton = UIButton(configuration: .borderedProminent())
    let endRunButton = UIButton(configuration: .borderedProminent())

    var state = State.loaded {
        didSet {
            switch state {
            case .loaded:
                configureLoadedUI()
            case .runStarted:
                configureRunStartedUI()
            case .runEnded:
                configureRunEndedUI()
            case .error:
                configureErrorUI()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        locationService.userApprovedLocationTrackingDelegate = self
        locationService.userDeniedLocationTrackingDelegate = self
    }

    func configurePersistentViewProperties() {
        mapView.delegate = viewModel

        view.backgroundColor = .white

        infoView.backgroundColor = .white
        infoView.layer.shadowColor = UIColor.black.cgColor
        infoView.layer.shadowRadius = 5
        infoView.layer.shadowOffset = .zero
        infoView.layer.shadowOpacity = 0.5
        infoView.layer.cornerRadius = 20

        centerUserLocationButton.setImage(UIImage(systemName: "location"), for: .normal)
        centerUserLocationButton.addTarget(self, action: #selector(centerUserLocationButtonTapped), for: .touchUpInside)

        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)

        unitOfMeasurementStack.axis = .vertical
        unitOfMeasurementStack.distribution = .fill
        unitOfMeasurementStack.spacing = 15
        unitOfMeasurementStack.alignment = .center

        unitOfMeasurementLabel.text = "Select a distance unit:"
        unitOfMeasurementLabel.font = UIFont(name: "Avenir Book", size: 16)

        let milesAction = UIAction(title: "Miles") { _ in
            self.viewModel.selectedLengthUnit = .miles
        }
        let kilometersAction = UIAction(title: "Kilometers") { _ in
            self.viewModel.selectedLengthUnit = .kilometers
        }
        unitOfMeasurementSelector.insertSegment(action: milesAction, at: 0, animated: true)
        unitOfMeasurementSelector.insertSegment(action: kilometersAction, at: 1, animated: true)
        unitOfMeasurementSelector.selectedSegmentIndex = 0

        totalDistanceTraveledLabel.font = UIFont(name: "Avenir Heavy", size: 50)
        totalDistanceTraveledLabel.adjustsFontSizeToFitWidth = true
        totalDistanceTraveledLabel.textAlignment = .center

        startStopButtonStack.axis = .horizontal
        startStopButtonStack.spacing = 15
        startStopButtonStack.distribution = .fillEqually

        startRunButton.addTarget(self, action: #selector(startRunButtonTapped), for: .touchUpInside)

        endRunButton.setTitle("END RUN", for: .normal)
        endRunButton.addTarget(self, action: #selector(endRunButtonTapped), for: .touchUpInside)
        endRunButton.isEnabled = false
    }

    func configureLoadedUI() {
        shareButton.isEnabled = false
        totalDistanceTraveledLabel.isHidden = true
        startRunButton.setTitle("START RUN", for: .normal)
    }

    func configureRunStartedUI() {
        startRunButton.isEnabled = false
        endRunButton.isEnabled = true
        unitOfMeasurementStack.isHidden = true
        totalDistanceTraveledLabel.isHidden = false
    }

    func configureRunEndedUI() {
        startRunButton.setTitle("NEW RUN", for: .normal)
        shareButton.isEnabled = true
        endRunButton.isEnabled = false
        startRunButton.isEnabled = true
        totalDistanceTraveledLabel.text = "Nice! You ran \(viewModel.totalDistanceTravelled)"

        // This block prevents the mapView from zooming in on an unexpected place
        // when the run is ended before a polyline exists
        if viewModel.userCoordinatesArray.count < 5 {
            mapView.setCenter(locationService.currentUserCoordinates!, animated: true)
        } else {
            mapView.setVisibleMapRect(viewModel.mapViewPolyline.boundingMapRect,
                                      edgePadding: UIEdgeInsets(top: 50,
                                                                left: 50,
                                                                bottom: infoView.frame.size.height,
                                                                right: 50),
                                      animated: true)
        }
    }

    func configureErrorUI() {
        let alertController = UIAlertController(title: "Error: Unable to Track Location",
                                                message: "Enable location tracking in Settings and restart the app.",
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }

    func layoutViews() {
        view.addSubview(mapView)
        view.addSubview(infoView)
        infoView.addSubview(centerUserLocationButton)
        infoView.addSubview(shareButton)
        infoView.addSubview(unitOfMeasurementStack)
        infoView.addSubview(totalDistanceTraveledLabel)
        infoView.addSubview(startStopButtonStack)

        mapView.translatesAutoresizingMaskIntoConstraints = false
        infoView.translatesAutoresizingMaskIntoConstraints = false
        centerUserLocationButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        unitOfMeasurementStack.translatesAutoresizingMaskIntoConstraints = false
        totalDistanceTraveledLabel.translatesAutoresizingMaskIntoConstraints = false
        startStopButtonStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            infoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            infoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            infoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            infoView.heightAnchor.constraint(equalToConstant: 180),

            centerUserLocationButton.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 5),
            centerUserLocationButton.leadingAnchor.constraint(equalTo: infoView.leadingAnchor),

            shareButton.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 5),
            shareButton.trailingAnchor.constraint(equalTo: infoView.trailingAnchor),

            unitOfMeasurementStack.topAnchor.constraint(equalTo: infoView.topAnchor,
                                                              constant: 15),
            unitOfMeasurementSelector.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 15),
            unitOfMeasurementSelector.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -15),

            totalDistanceTraveledLabel.centerXAnchor.constraint(equalTo: infoView.centerXAnchor),
            totalDistanceTraveledLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 30),
            totalDistanceTraveledLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 15),
            totalDistanceTraveledLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -15),

            startRunButton.heightAnchor.constraint(equalToConstant: 70),

            startStopButtonStack.topAnchor.constraint(equalTo: unitOfMeasurementStack.bottomAnchor, constant: 15),
            startStopButtonStack.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 15),
            startStopButtonStack.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -15)
        ])
    }

    func configureSubscribers() {
        subscribers = [
            viewModel.$mapViewShowsUserLocation.assign(to: \.showsUserLocation, on: mapView),
            viewModel.$mapViewRegion.sink(receiveValue: { [weak self] region in
                self?.mapView.setRegion(region!, animated: true)
                self?.polylineSubscriber = self?.viewModel.$mapViewPolyline.sink(receiveValue: { polyline in
                    self?.mapView.addOverlay(polyline)
                })
            }),
            viewModel.$totalDistanceTravelled
                .map { String($0) }
                .sink(receiveValue: { [weak self] distance in
                    self?.totalDistanceTraveledLabel.text = distance
                })
        ]
    }

    @objc func startRunButtonTapped() {
        state = .runStarted
        viewModel.startRun()
        mapView.removeOverlays(mapView.overlays)
    }

    @objc func endRunButtonTapped() {
        state = .runEnded
        viewModel.endRun()
    }

    @objc func centerUserLocationButtonTapped() {
        viewModel.centerMapOnUserCoordinates(withCoordinates: locationService.currentUserCoordinates!)
    }

    @objc func shareButtonTapped() {
        screenshot.image = view.screenshot()

        guard let screenshot = screenshot.image else { return }
        let activityViewController = UIActivityViewController(activityItems: [screenshot], applicationActivities: nil)
        present(activityViewController, animated: true)
    }
}

extension MapViewController: UserApprovedLocationTrackingDelegate {
    func userApprovedLocationTracking() {
        configurePersistentViewProperties()
        state = .loaded
        layoutViews()
        viewModel.showUserLocationOnMap()
        configureSubscribers()
    }
}

extension MapViewController: UserDeniedLocationTrackingDelegate {
    func presentLocationTrackingFailedError(withError error: Error) {
        print("ERROR: \(error.localizedDescription)")
        state = .error
    }
}
