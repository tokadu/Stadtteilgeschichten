#import "XYZVideo.h"
#import "XYZVideoListViewController.h"
#import "XYZVideoManagerDelegate.h"
#import "XYZVideoManager.h"
#import "XYZVideoCommunicator.h"
#import "XYZAppDelegate.h"
#import "XYZVideoViewController.h"

#import "UIImageView+AFNetworking.h"

const int kLoadingCellTag = 1273;

@interface XYZVideoListViewController () <XYZVideoManagerDelegate> {
    XYZVideoManager *_manager;
}

@property NSMutableArray *videoList;

@end

@implementation XYZVideoListViewController

UIView *activityView;
NSInteger _currentPage;
bool _hasMorePages = YES;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    
    _currentPage = 1;
    self.videoList = [[NSMutableArray alloc] init];
   
    [self initializeVideoManager];
    [self showActivityViewer];
    [self fetchVideos];
}

- (void) initializeVideoManager
{
    _manager = [[XYZVideoManager alloc] init];
    _manager.communicator = [[XYZVideoCommunicator alloc] init];
    _manager.communicator.delegate = _manager;
    _manager.delegate = self;
}

- (void)fetchVideos
{
    [_manager retrieveVideos:_currentPage];
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

- (void) removeLoadingIndicatorCell
{
    UITableViewCell *cell = (UITableViewCell *)[self.tableView viewWithTag:kLoadingCellTag];
    
    if(cell != nil){
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - UIRefreshControl

-(void)refreshView:(UIRefreshControl *)refresh
{
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Lade Videos..."];
 
    [self fetchVideos];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM d, h:mm a"];
    NSString *lastUpdated = [NSString stringWithFormat:@"Zuletzt aktualisiert um %@",[formatter stringFromDate:[NSDate date]]];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
    [refresh endRefreshing];
}

#pragma mark - Video Manager Delegate

- (void)didReceiveVideos:(NSArray *)videos
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideActivityViewer];
        
        if([videos count])
        {
            [self.videoList addObjectsFromArray:videos];
            _currentPage++;
        }
        else
        {
            _hasMorePages = NO;
            [self removeLoadingIndicatorCell];
        }
        
        [self.tableView reloadData];
    });
}

- (void)operationFailedWithError:(NSError *)error
{
    NSLog(@"Error %@; %@", error, [error localizedDescription]);
    
    [self hideActivityViewer];
    [self showErrorMessage];
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
    if(activityView != nil){
        [[[activityView subviews] objectAtIndex:0] stopAnimating];
        [activityView removeFromSuperview];
        activityView = nil;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_currentPage == 1) {
        return 0;
    }
    
    if (_hasMorePages) {
        return self.videoList.count + 1;
    }
    
    return self.videoList.count;
}

- (UITableViewCell *)videoCellForIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"ListPrototypeCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    XYZVideo *video = [self.videoList objectAtIndex:indexPath.row];
    cell.textLabel.text = video.title;
    cell.detailTextLabel.text = video.length;
    
    if (![video.thumbnailUrl isKindOfClass:[NSNull class]]){
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:video.thumbnailUrl]];
        [cell.imageView setImageWithURLRequest:request
                              placeholderImage:[UIImage imageNamed:@"fallback_thumbnail"]
                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                           cell.imageView.image = [self image:image scaledToSize:CGSizeMake(80, 80)];
                                       } failure:nil];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.videoList.count) {
        return [self videoCellForIndexPath:indexPath];
    } else {
        return [self loadingCell];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (cell.tag == kLoadingCellTag) {
        [self fetchVideos];
    }
}

- (UITableViewCell *)loadingCell {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.center = cell.center;
    [cell addSubview:activityIndicator];
    
    [activityIndicator startAnimating];
    
    cell.tag = kLoadingCellTag;
    
    return cell;
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
    if ([[segue identifier] isEqualToString: @"showDetailsSegue"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        XYZVideo *selectedVideo = [self.videoList objectAtIndex:indexPath.row];
        
        XYZVideoViewController *dest = [segue destinationViewController];
        dest.videoId = [selectedVideo valueForKeyPath:@"videoId"];
    }
}


@end
