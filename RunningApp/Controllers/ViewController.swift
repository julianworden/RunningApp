//
//  ViewController.swift
//  RunningApp
//
//  Created by Julian Worden on 7/9/22.
//

import MapKit
import UIKit

class ViewController: UIViewController {

    let mapView = MKMapView()
    let totalDistanceTraveledLabel = UILabel()
    lazy var startStopButtonStack = UIStackView(arrangedSubviews: [startRunButton, endRunButton])
    let startRunButton = UIButton(configuration: .borderedProminent())
    let endRunButton = UIButton(configuration: .borderedProminent())

    var userLocationsArray = [CLLocation]()
    var userCoordinatesArray = [CLLocationCoordinate2D]() {
        didSet {
            drawPolyline()
        }
    }
    var startingLocation: CLLocation?
    var endingLocation: CLLocation?
    var totalDistanceTraveled: String {
        guard let endingLocation = endingLocation else { return ""  }
        return endingLocation.distance(from: startingLocation!).formatted()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        configureViews()
        layoutViews()
        checkLocationAuthorizationStatus()
    }

    func configureViews() {
        mapView.delegate = self

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

        mapView.translatesAutoresizingMaskIntoConstraints = false
        totalDistanceTraveledLabel.translatesAutoresizingMaskIntoConstraints = false
        startStopButtonStack.translatesAutoresizingMaskIntoConstraints = false

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
            startStopButtonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15)
        ])
    }

    @objc func setStartingLocation() {
        startingLocation = userLocationsArray[0]
    }

    @objc func setEndingLocation() {
        guard startingLocation != nil else { return }
        endingLocation = userLocationsArray[0]
        totalDistanceTraveledLabel.text = "Congratulations! You ran \(totalDistanceTraveled)m"
    }
}

// swiftlint:disable force_cast
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let routeRenderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        routeRenderer.lineWidth = 5
        routeRenderer.strokeColor = .systemBlue
        return routeRenderer
    }

    func checkLocationAuthorizationStatus() {
        switch LocationService.instance.locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            LocationService.instance.userLocationUpdatedDelegate = self
            centerMapOnUserCoordinates(withCoordinates: LocationService.instance.currentUserCoordinates!)
        default:
            LocationService.instance.locationManager.requestWhenInUseAuthorization()
        }
    }

    func centerMapOnUserCoordinates(withCoordinates coordinates: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }

    func drawPolyline() {
        let polyLine = MKPolyline(coordinates: userCoordinatesArray, count: userCoordinatesArray.count)
        mapView.addOverlay(polyLine)
    }
}

extension ViewController: UserLocationUpdatedDelegate {
    func userLocationUpdated(toLocation location: CLLocation) {
        centerMapOnUserCoordinates(withCoordinates: location.coordinate)
        userCoordinatesArray.insert(location.coordinate, at: 0)
        userLocationsArray.insert(location, at: 0)
    }
}
