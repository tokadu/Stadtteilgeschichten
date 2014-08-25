#import "XYZCaptureNewVideoViewController.h"
#import "XYZVideoManager.h"
#import "XYZVideoCommunicator.h"
#import "XYZAppDelegate.h"

#import "AVFoundation/AVAsset.h"

@interface XYZCaptureNewVideoViewController () <XYZVideoManagerDelegate> {
    XYZVideoManager *_manager;
}
@end

@implementation XYZCaptureNewVideoViewController

UIView *activityView;
NSArray *encodingValues;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self showActivityViewer];
    [self initializeVideoManager];
    // start searching for our location coordinates
    [self startUpdatingCurrentLocation];
    [_manager retrieveEncodingTypes];
}

- (void) initializeEncodingTypePicker {
    UIPickerView *encodingPicker = [[UIPickerView alloc]init];
    [encodingPicker setDataSource:self];
    [encodingPicker setDelegate:self];
    encodingPicker.showsSelectionIndicator = YES;
    
    [encodingPicker selectRow:2 inComponent:0 animated:YES];
    
    self.encondigTypeTextField.inputView = encodingPicker;
}

- (void) initializeVideoManager
{
    _manager = [[XYZVideoManager alloc] init];
    _manager.communicator = [[XYZVideoCommunicator alloc] init];
    _manager.communicator.delegate = _manager;
    _manager.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)cancelCapture:(id)sender {
    [self dismissViewControllerAnimated: YES completion: nil];
}

- (IBAction)createVideo:(id)sender {			
    if([self formIsValid]) {
        [self.view endEditing:YES];
        [self uploadVideo];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Validation error" message:@"Der Titel und ein Video werden benötigt."
                                                       delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
    }
}

- (BOOL) formIsValid {
    return [self.titleTextField.text length] > 0 && (self.movieURL && ![self.movieURL isKindOfClass:[NSNull class]]);
}

- (IBAction)takeVideo:(UIButton *)sender {
    [self getVideoFromSource:UIImagePickerControllerSourceTypeCamera];
}

- (IBAction)pickVideo:(UIButton *)sender {
    [self getVideoFromSource:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
}

- (void) getVideoFromSource:(UIImagePickerControllerSourceType) sourceType {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = sourceType;
    picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    
    [self presentViewController:picker animated:YES completion:NULL];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    self.movieURL = info[UIImagePickerControllerMediaURL];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void) showErrorMessage
{
    UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"An error ocurred" message:@"There was an error contacting the server. Please retry the operation." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
}

#pragma mark - UITextFieldDelegate

// dismiss the keyboard for the textfields
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.qrTagTextField resignFirstResponder];
    
	return YES;
}

#pragma mark - Upload Video

- (void) uploadVideo {
    [self showActivityViewer];
    
    XYZVideo *video = [XYZVideo alloc];
    
    video.title = [self.titleTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    video.videoDescription = [self.descriptionTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    video.qrTag = [self.qrTagTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    video.resolution = self.encondigTypeTextField.text;
    
    if (CLLocationCoordinate2DIsValid(_currentCoordinate))
    {
        video.latitude = [NSString stringWithFormat:@"%.4F", _currentCoordinate.latitude];
        video.longitude = [NSString stringWithFormat:@"%.4F", _currentCoordinate.longitude];
        video.formattedAddress = _addressLabel.text;
    }
    
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:self.movieURL];
    CMTime time = [avUrl duration];
    int seconds = ceil(time.value/time.timescale);
    
    video.length = [@(seconds) description];
    
    [_manager uploadVideo:self.movieURL withMetadata:video];
}

#pragma mark - Video Manager Delegate

- (void) operationFailedWithError:(NSError *)error{
    [self hideActivityViewer];
    [self showErrorMessage];
}


- (void) uploadCompleted{
    [self hideActivityViewer];
    
    UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"Success" message:@"Das Video wurde erfolgreich hochgeladen." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
};

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void) didReceiveEncodingTypes:(NSArray *)encodingTypes {
    encodingValues = encodingTypes;
    [self initializeEncodingTypePicker];
    [self hideActivityViewer];
}

#pragma mark - Activity View

-(void)showActivityViewer
{
    XYZAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    UIWindow *window = delegate.window;
    activityView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, window.bounds.size.width, window.bounds.size.height)];
    activityView.backgroundColor = [UIColor blackColor];
    activityView.alpha = 0.5;
    
    UIActivityIndicatorView *activityWheel = [[UIActivityIndicatorView alloc] initWithFrame: CGRectMake(window.bounds.size.width / 2 - 12, window.bounds.size.height / 2 - 12, 24, 24)];
    activityWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    activityWheel.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                      UIViewAutoresizingFlexibleRightMargin |
                                      UIViewAutoresizingFlexibleTopMargin |
                                      UIViewAutoresizingFlexibleBottomMargin);
    
    [activityView addSubview:activityWheel];
    [window addSubview: activityView];
    
    [[[activityView subviews] objectAtIndex:0] startAnimating];
}

-(void)hideActivityViewer
{
    [[[activityView subviews] objectAtIndex:0] stopAnimating];
    activityView.alpha = 0.0;
    [activityView removeFromSuperview];
    activityView = nil;
}

#pragma mark - UIPickerView

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}


-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [encodingValues count];
}


-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [encodingValues objectAtIndex: row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSString *selectedValue = [encodingValues objectAtIndex: row];
    NSLog(@"Selected Value: %@", selectedValue);
    
    self.encondigTypeTextField.text = selectedValue;
}

#pragma mark - CLLocationManagerDelegate

- (void)startUpdatingCurrentLocation
{
    // if location services are restricted do nothing
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
    {
        self.locationLabel.text = @"Service steht nicht zur Verfügung.";
        _currentCoordinate = kCLLocationCoordinate2DInvalid;
        return;
    }
    
    // if locationManager does not currently exist, create it
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
        _locationManager.distanceFilter = 10.0f; // we don't need to be any more accurate than 10m
        [_locationManager setActivityType:CLActivityTypeOtherNavigation];
    }
    [_locationManager startUpdatingLocation];
}

- (void)stopUpdatingCurrentLocation
{
    [_locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // if the location is older than 30s ignore
    if (fabs([newLocation.timestamp timeIntervalSinceDate:[NSDate date]]) > 30)
    {
        return;
    }
    
    _currentCoordinate = [newLocation coordinate];
    
    // update the current location cells detail label with these coords
    self.locationLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", _currentCoordinate.latitude, _currentCoordinate.longitude];
    
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:_currentCoordinate.latitude longitude:_currentCoordinate.longitude];
    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
    {
        if (error)
        {
            NSLog(@"Geocode failed with error: %@", error);
            [self displayError:error];
            return;
        }
        NSLog(@"Received placemarks: %@", placemarks);
        self.addressLabel.text = [self getAddress:placemarks];
    }];
    
    // after recieving a location, stop updating
    [self stopUpdatingCurrentLocation];
}

// display the results
- (NSString *)getAddress:(NSArray*)placemark
{
    /*
    NSArray const *keys = @[@"name",
                            @"thoroughfare",
                            @"subThoroughfare",
                            @"locality",
                            @"subLocality",
                            @"administrativeArea",
                            @"subAdministrativeArea",
                            @"postalCode",
                            @"ISOcountryCode",
                            @"country"];
    */
    
    if (placemark.count > 0)
    {
    
        CLPlacemark* address = placemark[0];
    
        NSString *name = [address name];
        NSString *locality = [address locality];
        NSString *postalCode = [address postalCode];
        NSString *country = [address country];

        return [NSString stringWithFormat:@"%@, %@, %@, %@", name, locality, postalCode, country];
    }
    return @"(unbekannt)";
}

// display a given NSError in an UIAlertView
- (void)displayError:(NSError *)error
{
        NSString *message;
        switch ([error code])
        {
            case kCLErrorGeocodeFoundNoResult: message = @"Kein Addresse zum aktuellen Standort gefunden.";
                break;
            case kCLErrorGeocodeCanceled: message = @"Aktion wurde abgebrochen.";
                break;
            case kCLErrorGeocodeFoundPartialResult: message = @"Kein Addresse zum aktuellen Standort gefunden.";
                break;
            default: message = [error description];
                break;
        }
        
        UIAlertView *alert =  [[UIAlertView alloc] initWithTitle:@"Fehler beim Ermitteln des akt. Standortes"
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        [alert show];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    
    // stop updating
    [self stopUpdatingCurrentLocation];
    
    // since we got an error, set selected location to invalid location
    _currentCoordinate = kCLLocationCoordinate2DInvalid;
    
    // show the error alert
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = @"Fehler beim Ermitteln des akt. Standortes";
    alert.message = [error localizedDescription];
    [alert addButtonWithTitle:@"OK"];
    [alert show];
}


@end
