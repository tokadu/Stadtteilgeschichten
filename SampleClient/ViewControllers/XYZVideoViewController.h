#import <UIKit/UIKit.h>
#import "XYZVideo.h"

@interface XYZVideoViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UILabel *videoDescription;
@property (strong, nonatomic) IBOutlet UILabel *videoTitle;
@property (strong, nonatomic) IBOutlet UILabel *videoAddress;

@property (strong, nonatomic) IBOutlet UIView *playerView;
@property (strong, nonatomic) IBOutlet UIView *detailsView;
@property (strong, nonatomic) IBOutlet UIView *relatedVideosView;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property NSString *videoId;

@end
