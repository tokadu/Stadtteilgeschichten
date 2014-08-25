#import <Foundation/Foundation.h>
#import "XYZVideo.h"

@protocol XYZVideoCommunicatorDelegate;

@interface XYZVideoCommunicator : NSObject

@property (weak, nonatomic) NSObject<XYZVideoCommunicatorDelegate> *delegate;

- (void)retrieveVideos: (NSInteger)pageIndex;

- (void)retrieveVideos: (NSInteger)pageIndex withPageSize:(NSInteger) pageSize;

- (void)retrieveEncodingTypes;

- (void)retrieveVideoWithId: (NSString *)videoId;

- (void)retrieveRecommendedVideos: (NSString *)videoId;

- (void)createSASLocatorForVideo: (XYZVideo *) video;

- (void)uploadVideo: (NSURL *)videoUrl toSASLocator:(NSURL *)sasUrl;

- (void)publishAsset: (NSString *)assetId withMetadata:(XYZVideo *)videoMetadata;

@end