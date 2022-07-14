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
    let totalDistanceTraveledLabel = UILabel()
    lazy var startStopButtonStack = UIStackView(arrangedSubviews: [startRunButton, endRunButton])
    let startRunButton = UIButton(configuration: .borderedProminent())
    let endRunButton = UIButton(configuration: .borderedProminent())
    let centerButton = UIButton(configuration: .plain())

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

        centerButton.setTitle("CENTER LOCATION", for: .normal)
        centerButton.addTarget(self, action: #selector(centerUserLocation), for: .touchUpInside)

        startStopButtonStack.axis = .horizontal
        startStopButtonStack.spacing = 15
        startStopButtonStack.distribution = .fillEqually

        startRunButton.setTitle("START RUN", for: .normal)
        startRunButton.addTarget(self, action: #selector(setStartingLocation), for: .touchUpInside)

        endRunButton.setTitle("END RUN", for: .normal)
        endRunButton.addTarget(self, action: #selector(setEndingLocation), for: .touchUpInside)
    }

    func layoutViews() {
        view.addSubview(mapView)
        view.addSubview(totalDistanceTraveledLabel)
        view.addSubview(startStopButtonStack)
        view.addSubview(centerButton)

        mapView.translatesAutoresizingMaskIntoConstraints = false
        totalDistanceTraveledLabel.translatesAutoresizingMaskIntoConstraints = false
        startStopButtonStack.translatesAutoresizingMaskIntoConstraints = false
        centerButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            totalDistanceTraveledLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            totalDistanceTraveledLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            startRunButton.heightAnchor.constraint(equalToConstant: 70),

            startStopButtonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            startStopButtonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            startStopButtonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),

            centerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func configureSubscribers() {
        subscribers = [
            viewModel.$mapViewShowsUserLocation.assign(to: \.showsUserLocation, on: mapView),
            viewModel.$mapViewRegion.sink(receiveValue: { region in
                self.mapView.setRegion(region!, animated: true)
                self.polylineSubscriber = self.viewModel.$mapViewPolyline.sink(receiveValue: { polyline in
                    self.mapView.addOverlay(polyline)
                })
            })
        ]
    }

    @objc func setStartingLocation() {
        viewModel.startingLocation = viewModel.userLocationsArray[0]
    }

    @objc func setEndingLocation() {
        guard viewModel.startingLocation != nil else { return }
        viewModel.endingLocation = viewModel.userLocationsArray[0]
        totalDistanceTraveledLabel.text = "Congratulations! You ran \(viewModel.totalDistanceTraveled)m"
    }

    @objc func centerUserLocation() {
        viewModel.centerMapOnUserCoordinates(withCoordinates: LocationService.instance.currentUserCoordinates!)
    }
}
