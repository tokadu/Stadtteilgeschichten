#import "XYZVideoManager.h"
#import "XYZVideoBuilder.h"
#import "XYZVideoCommunicator.h"

@implementation XYZVideoManager

NSURL *movieUrl;
NSURL *sasUrl;
NSString *assetId;
NSString *_videoId;
id recievedVideo;
XYZVideo *newVideo;

- (void)retrieveVideos: (NSInteger)pageIndex
{
    [self.communicator retrieveVideos:pageIndex];
}

- (void)retrieveVideoWithId: (NSString *)videoId;
{
    _videoId = videoId;
    [self.communicator retrieveVideoWithId:videoId];
}

- (void) retrieveEncodingTypes {
    [self.communicator retrieveEncodingTypes];
}

- (void)uploadVideo: (NSURL *) videoUrl withMetadata:(XYZVideo *)video;
{
    movieUrl = videoUrl;
    newVideo = video;
    
    [self.communicator createSASLocatorForVideo:newVideo];
}

#pragma mark - VideoCommunicatorDelegate

- (void)receivedVideoList:(NSData *)objectNotation
{
    NSError *error = nil;
    NSArray *videos = [XYZVideoBuilder videosFromJSON:objectNotation error:&error];
    
    if (error != nil) {
        [self.delegate operationFailedWithError:error];
        
    } else {
        [self.delegate didReceiveVideos:videos];
    }
}

- (void)receivedVideo:(NSData *) singleObject{
    NSError *error = nil;
    recievedVideo = [XYZVideoBuilder singleVideoFromJSON:singleObject error:&error];
    
    if (error != nil) {
        [self.delegate operationFailedWithError:error];
    }
    
    [self.communicator retrieveRecommendedVideos:_videoId];
}

- (void)receivedRelatedVideos:(NSData *)objectNotation
{
    NSError *error = nil;
    NSArray *videos = [XYZVideoBuilder videosFromJSON:objectNotation error:&error];
    
    if (error == nil) {
        ((XYZVideo *)recievedVideo).relatedVideos = videos;
    }
    
    [self.delegate didReceiveVideos:recievedVideo];
}

- (void)fetchingDataFailedWithError:(NSError *)error
{
    NSLog(@"fetch data failed with error %@", error);
    [self.delegate operationFailedWithError:error];
}

- (void)assetCreated:(NSData *)assetDetails{
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:assetDetails options:0 error:&localError];
    
    if (localError != nil) {
        [self.delegate operationFailedWithError:localError];
    }
    
    assetId = [parsedObject objectForKey:@"AssetId"];
    NSString *sasLocatorString = [parsedObject objectForKey:@"SasLocator"];
    sasUrl = [[NSURL alloc] initWithString:sasLocatorString];
    
    [self.communicator uploadVideo:movieUrl toSASLocator:sasUrl];
};

- (void)uploadCompleted{
    [self.communicator publishAsset:assetId withMetadata:newVideo];
};

-(void)publishCompleted{
    sasUrl = NULL;
    movieUrl = NULL;
    assetId = NULL;
    newVideo = NULL;
    
    [self.delegate uploadCompleted];
}

-(void)receivedEncondingTypes:(NSData *)encodingTypesJSONData {
    NSError *localError = nil;
    NSArray *encodingTypes = [NSJSONSerialization JSONObjectWithData:encodingTypesJSONData options:0 error:&localError];
    
    if (localError != nil) {
        [self.delegate operationFailedWithError:localError];
    }
    
    [self.delegate didReceiveEncodingTypes:encodingTypes];
}
@end