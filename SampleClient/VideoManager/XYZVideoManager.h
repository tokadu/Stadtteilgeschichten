#import <Foundation/Foundation.h>
#import "XYZVideoCommunicatorDelegate.h"
#import "XYZVideoManagerDelegate.h"

@class XYZVideoCommunicator;

@interface XYZVideoManager : NSObject<XYZVideoCommunicatorDelegate>

@property XYZVideoCommunicator *communicator;
@property id<XYZVideoManagerDelegate> delegate;

- (void)retrieveVideos: (NSInteger)pageIndex;
- (void)retrieveVideoWithId: (NSString *)videoId;
- (void)retrieveEncodingTypes;
- (void)uploadVideo: (NSURL *) videoUrl withMetadata: (XYZVideo *)video;
@end