#import "XYZVideoViewController.h"
#import "XYZVideoManagerDelegate.h"
#import "XYZVideoManager.h"
#import "XYZVideoCommunicator.h"
#import "XYZAppDelegate.h"


#import "UIImageView+AFNetworking.h"
#import "MediaPlayer/MediaPlayer.h"

#import <QuartzCore/QuartzCore.h>

@interface XYZVideoViewController () <XYZVideoManagerDelegate> {
    XYZVideoManager *_manager;
}

@property NSMutableArray *videoList;

@end

@implementation XYZVideoViewController

MPMoviePlayerController *moviePlayer;
bool isReady;

@synthesize playerView;
@synthesize detailsView;
@synthesize relatedVideosView;
@synthesize videoDescription;
@synthesize videoTitle;
@synthesize videoAddress;
@synthesize tableView = _tableView;

UIView *activityView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"Recieved video Id %@, querying the server for details..", self.videoId);
    
    self.videoList = [[NSMutableArray alloc] init];
    
    [self initializeVideoManager];
    
    [self showActivityViewer];
    [_manager retrieveVideoWithId:self.videoId];
    
    self.detailsView.layer.borderColor = [[UIColor grayColor] CGColor];
    self.detailsView.layer.borderWidth = 1.0f;
    self.detailsView.layer.cornerRadius = 5;
}

- (void) initializeVideoManager
{
    _manager = [[XYZVideoManager alloc] init];
    _manager.communicator = [[XYZVideoCommunicator alloc] init];
    _manager.communicator.delegate = _manager;
    _manager.delegate = self;
}

-(void) showErrorMessage
{
    UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"An error ocurred" message:@"There was an error contacting the server. Please retry the operation." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Video Manager Delegate

- (void)didReceiveVideos:(XYZVideo *)video
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideActivityViewer];
        
        NSLog(@"Recieved video %@", video);
        
        self.videoTitle.text = video.title;
        
        if ([video.videoDescription isKindOfClass:[NSNull class]]){
            self.videoDescription.hidden = YES;
        } else {
            self.videoDescription.text = video.videoDescription;
        }
        
        if ([video.formattedAddress isKindOfClass:[NSNull class]]){
            self.videoAddress.hidden = YES;
        } else {
            self.videoAddress.text = video.formattedAddress;
        }
        
        if(video.playbackUrl){
            [self playURL:video.playbackUrl];
        }
        
        if(video.relatedVideos && [video.relatedVideos count]){
            [self.videoList removeAllObjects];
            [self.videoList addObjectsFromArray:video.relatedVideos];
            [self.tableView reloadData];
        } else {
            self.tableView.hidden = YES;
        }
    });
}

- (void)operationFailedWithError:(NSError *)error
{
    NSLog(@"Error %@; %@", error, [error localizedDescription]);
    
    [self hideActivityViewer];
    [self showErrorMessage];
}


#pragma mark - Video Element

- (void) playURL:(NSString *)url
{
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:url]];
    [moviePlayer.view setFrame:CGRectMake(0, 65, 320, 182)];
    [moviePlayer play];
    [self.view addSubview:moviePlayer.view];
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

#pragma mark - Related Videos Table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.videoList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ListPrototypeCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    XYZVideo *video = [self.videoList objectAtIndex:indexPath.row];
    cell.textLabel.text = video.title;
    cell.detailTextLabel.text = video.length;
    
    if (![video.thumbnailUrl isKindOfClass:[NSNull class]])
    {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:video.thumbnailUrl]];
        
        [cell.imageView setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"fallback_thumbnail"]
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
        {
            cell.imageView.image = [self image:image scaledToSize:CGSizeMake(80, 80)];
        }
        failure:nil];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Related Videos";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
     [self performSegueWithIdentifier:@"navigateToRelatedVideo" sender:indexPath];
}

- (UIImage *)image:(UIImage*)originalImage scaledToSize:(CGSize)size
{
    if (CGSizeEqualToSize(originalImage.size, size))
    {
        return originalImage;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    [originalImage drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString: @"navigateToRelatedVideo"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        long row = [indexPath row];
        XYZVideo *selectedVideo = [self.videoList objectAtIndex:row];
        
        XYZVideoViewController *dest = [segue destinationViewController];
        dest.videoId = [selectedVideo valueForKeyPath:@"videoId"];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [moviePlayer stop];
}

-(void)viewWillAppear:(BOOL)animated
{
    if(self.isMovingToParentViewController)
    {
        return;
    }
    
    [_manager retrieveVideoWithId:self.videoId];
}

@end
