#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreLocation/CoreLocation.h>
#import "XYZVideoManagerDelegate.h"

@interface XYZCaptureNewVideoViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, CLLocationManagerDelegate, XYZVideoManagerDelegate>

- (IBAction)cancelCapture:(id)sender;
- (IBAction)createVideo:(id)sender;
- (IBAction)takeVideo:(UIButton *)sender;
- (IBAction)pickVideo:(UIButton *)sender;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (readonly) CLLocationCoordinate2D currentCoordinate;
@property (copy, nonatomic) NSURL *movieURL;

@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (strong, nonatomic) IBOutlet UITextField *qrTagTextField;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UILabel *addressLabel;
@property (strong, nonatomic) IBOutlet UITextField *encondigTypeTextField;

@end
