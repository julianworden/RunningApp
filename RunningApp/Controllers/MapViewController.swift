//
//  ViewController.swift
//  RunningApp
//
//  Created by Julian Worden on 7/9/22.
//

import Combine
import MapKit
import UIKit

class MapViewController: UIViewController {
    let viewModel = MapViewModel()
    var subscribers = Set<AnyCancellable>()
    var polylineSubscriber: AnyCancellable?

    let mapView = MKMapView()
    let infoView = UIView()
    let centerButton = UIButton(configuration: .plain())
    let totalDistanceTraveledLabel = UILabel()
    let unitOfMeasurementSelector = UISegmentedControl()
    lazy var startStopButtonStack = UIStackView(arrangedSubviews: [startRunButton, endRunButton])
    let startRunButton = UIButton(configuration: .borderedProminent())
    let endRunButton = UIButton(configuration: .borderedProminent())

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        configureViews()
        layoutViews()
        viewModel.checkLocationAuthorizationStatus()
        configureSubscribers()
    }

    func configureViews() {
        mapView.delegate = viewModel

        infoView.backgroundColor = .white
        infoView.layer.cornerRadius = 20

        centerButton.setImage(UIImage(systemName: "location"), for: .normal)
        centerButton.addTarget(self, action: #selector(centerUserLocationButtonTapped), for: .touchUpInside)

        unitOfMeasurementSelector.insertSegment(withTitle: "Miles", at: 0, animated: true)
        unitOfMeasurementSelector.insertSegment(withTitle: "Kilometers", at: 1, animated: true)
        unitOfMeasurementSelector.selectedSegmentIndex = 0

        totalDistanceTraveledLabel.isHidden = true
        totalDistanceTraveledLabel.font = UIFont(name: "Avenir Heavy", size: 22)

        startStopButtonStack.axis = .horizontal
        startStopButtonStack.spacing = 15
        startStopButtonStack.distribution = .fillEqually

        startRunButton.setTitle("START RUN", for: .normal)
        startRunButton.addTarget(self, action: #selector(startRunButtonTapped), for: .touchUpInside)

        endRunButton.setTitle("END RUN", for: .normal)
        endRunButton.addTarget(self, action: #selector(endRunButtonTapped), for: .touchUpInside)
        endRunButton.isEnabled = false
    }

    func layoutViews() {
        view.addSubview(mapView)
        view.addSubview(infoView)
        infoView.addSubview(centerButton)
        infoView.addSubview(unitOfMeasurementSelector)
        infoView.addSubview(totalDistanceTraveledLabel)
        infoView.addSubview(startStopButtonStack)

        mapView.translatesAutoresizingMaskIntoConstraints = false
        totalDistanceTraveledLabel.translatesAutoresizingMaskIntoConstraints = false
        startStopButtonStack.translatesAutoresizingMaskIntoConstraints = false
        infoView.translatesAutoresizingMaskIntoConstraints = false
        centerButton.translatesAutoresizingMaskIntoConstraints = false
        unitOfMeasurementSelector.translatesAutoresizingMaskIntoConstraints = false
        totalDistanceTraveledLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            centerButton.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 5),
            centerButton.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 0),

            unitOfMeasurementSelector.bottomAnchor.constraint(equalTo: totalDistanceTraveledLabel.topAnchor,
                                                              constant: -15),
            unitOfMeasurementSelector.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 15),
            unitOfMeasurementSelector.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -15),

            totalDistanceTraveledLabel.centerXAnchor.constraint(equalTo: infoView.centerXAnchor),
            totalDistanceTraveledLabel.bottomAnchor.constraint(equalTo: startStopButtonStack.topAnchor, constant: -15),

            startRunButton.heightAnchor.constraint(equalToConstant: 70),

            startStopButtonStack.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -15),
            startStopButtonStack.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 15),
            startStopButtonStack.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -15),

            infoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            infoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            infoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            infoView.heightAnchor.constraint(equalToConstant: view.frame.size.height / 3)

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
                    self?.totalDistanceTraveledLabel.text = "Distance: \(distance)"
                })
        ]
    }

    @objc func startRunButtonTapped() {
        viewModel.startRun()
        startRunButton.isEnabled = false
        endRunButton.isEnabled = true
        totalDistanceTraveledLabel.isHidden = false
        viewModel.userCoordinatesArray.removeAll()
        viewModel.userLocationsArray.removeAll()
        mapView.removeOverlays(mapView.overlays)
    }

    @objc func endRunButtonTapped() {
        viewModel.endRun()
        endRunButton.isEnabled = false
        startRunButton.isEnabled = true
        mapView.setVisibleMapRect(viewModel.mapViewPolyline.boundingMapRect,
                                  edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: infoView.frame.size.height, right: 50),
                                  animated: true)
    }

    @objc func centerUserLocationButtonTapped() {
        viewModel.centerMapOnUserCoordinates(withCoordinates: LocationService.instance.currentUserCoordinates!)
    }
}
