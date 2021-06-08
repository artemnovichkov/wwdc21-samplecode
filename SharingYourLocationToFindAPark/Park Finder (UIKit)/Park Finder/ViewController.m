/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that illustrates a use case of the CLLocationButton.
*/

#import "ViewController.h"
#import <Foundation/Foundation.h>

@interface ViewController ()

@end

const float BUTTON_SHADOW_OPACITY = 0.25;
const float BUTTON_HEIGHT = 54;
const float BUTTON_WIDTH = 215;
const float BUTTON_ALPHA = 0.8;
const float BUTTON_BOTTOM_MARGIN = 30;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;

    // Add a map view to display the parks.
    self.mapview = [[MKMapView alloc] initWithFrame:self.view.bounds];
    [self.mapview setShowsUserLocation: YES];
    self.mapview.translatesAutoresizingMaskIntoConstraints = false;
    self.mapview.mapType = MKMapTypeStandard;
    self.mapview.delegate = self;
    [self.view addSubview:self.mapview];
    [self.mapview.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.mapview.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.mapview.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.mapview.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

    // Add a location button.
    self.locationButton = [[CLLocationButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_WIDTH, BUTTON_HEIGHT)];
    self.locationButton.icon = CLLocationButtonIconArrowFilled;
    self.locationButton.label = CLLocationButtonLabelCurrentLocation;
    self.locationButton.backgroundColor = [UIColor linkColor];
    self.locationButton.tintColor = UIColor.whiteColor;
    self.locationButton.cornerRadius = BUTTON_HEIGHT / 2;
    self.locationButton.layer.shadowOpacity = BUTTON_SHADOW_OPACITY;
    self.locationButton.alpha = BUTTON_ALPHA;
    self.locationButton.translatesAutoresizingMaskIntoConstraints = false;
    [self.locationButton addTarget:self action:@selector(didPressLocationButton:)
      forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.locationButton];
    [self.locationButton.widthAnchor constraintEqualToConstant:BUTTON_WIDTH].active = YES;
    [self.locationButton.heightAnchor constraintEqualToConstant:BUTTON_HEIGHT].active = YES;
    [self.locationButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.locationButton.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor constant: -BUTTON_BOTTOM_MARGIN].active = YES;
}

// Start updating location when user taps the button.
- (void)didPressLocationButton:(id) sender {
    // Location button doesn't require the additional step of calling `requestWhenInUseAuthorization()`.
    [locationManager startUpdatingLocation];
}

// Helper function that adds park pins on the map view.
- (void)addPins:(CLLocation *)location {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark*> *placemarks, NSError *error) {
        if (!placemarks) {
            return;
        } else if (placemarks && placemarks.count > 0) {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(placemark.location.coordinate, 1500, 1500);
            MKCoordinateRegion adjustedRegion = [self.mapview regionThatFits:viewRegion];
            [self.mapview setRegion:adjustedRegion animated:NO];
            
            MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
            [searchRequest setNaturalLanguageQuery:@"Park"];
            [searchRequest setRegion:self.mapview.region];
            [searchRequest setRegion:viewRegion];

            MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:searchRequest];
            [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *searcherror) {
                if (!searcherror) {
                    [self.mapview removeAnnotations: self.mapview.annotations];
                    for (MKMapItem *item in [response mapItems]) {
                        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
                        [annotation setCoordinate: item.placemark.coordinate];
                        [annotation setTitle: item.placemark.name];
                        [self.mapview addAnnotation:annotation];
                    }
                }
            }];
        }
    }];
}

#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (locations.lastObject != NULL) {
        [self addPins: locations.lastObject];
        [locationManager stopUpdatingLocation];
    }
}

@end
