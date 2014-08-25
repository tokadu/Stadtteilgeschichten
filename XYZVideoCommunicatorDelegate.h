#import <Foundation/Foundation.h>
#import "XYZVideo.h"

@protocol XYZVideoCommunicatorDelegate

- (void)receivedVideoList:(NSData *)objectNotation;
- (void)receivedRelatedVideos:(NSData *)objectNotation;
- (void)receivedVideo:(NSData *) singleObject;
- (void)fetchingDataFailedWithError:(NSError *)error;
- (void)receivedEncondingTypes:(NSData *)encodingTypes;
- (void)assetCreated:(NSData *)assetDetails;
- (void)uploadCompleted;
- (void)publishCompleted;

@end
