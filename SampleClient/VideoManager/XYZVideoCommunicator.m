#import "XYZVideoCommunicator.h"
#import "XYZVideoCommunicatorDelegate.h"

const int DEFAULT_PAGE_SIZE = 20;

@implementation XYZVideoCommunicator
NSString *serverAddress = @"http://contosomediaservice.cloudapp.net";
NSString *paginationQueryString = @"?pageIndex=%1$i&pageSize=%2$i";
NSString *encodingTypesQueryString = @"/resolutions";
NSString *urlAsString = nil;

- (id)init {
    self = [super init];
    if (self) {
        urlAsString = [serverAddress stringByAppendingString: @"/api/videos/"];
    }
    
    return self;
}

- (void)retrieveVideos: (NSInteger)pageIndex
{
    return [self retrieveVideos:pageIndex withPageSize:DEFAULT_PAGE_SIZE];
}

- (void)retrieveVideos: (NSInteger)pageIndex withPageSize:(NSInteger) pageSize
{
    NSString *formattedQueryString = [NSString stringWithFormat:paginationQueryString, pageIndex, pageSize];
    NSString *retrieveVideosUrl = [urlAsString stringByAppendingString: formattedQueryString];
    
    [self queryEndpoint:retrieveVideosUrl:@selector(receivedVideoList:)];
}

- (void)retrieveEncodingTypes {
    NSString *retrieveEncodingTypesUrl = [urlAsString stringByAppendingString: encodingTypesQueryString];
    [self queryEndpoint:retrieveEncodingTypesUrl:@selector(receivedEncondingTypes:)];
}

- (void)retrieveRecommendedVideos: (NSString *)videoId
{
    NSString *urlWithVideoId = [[urlAsString stringByAppendingString:videoId] stringByAppendingString:@"/recommendations"];
    
    [self queryEndpoint:urlWithVideoId:@selector(receivedRelatedVideos:)];
}

- (void)retrieveVideoWithId: (NSString *)videoId
{
    NSString *urlWithVideoId = [urlAsString stringByAppendingString:videoId];
    [self queryEndpoint:urlWithVideoId:@selector(receivedVideo:)];
}

- (void)createSASLocatorForVideo: (XYZVideo *) video{
    
    NSString *queryString = [@"generateasset/?filename=" stringByAppendingString: [[video.title stringByAppendingString:@".mov"] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSString *createAssetUrl = [urlAsString stringByAppendingString:queryString];
    [self queryEndpoint:createAssetUrl:@selector(assetCreated:)];
};

- (void)uploadVideo: (NSURL *)videoUrl toSASLocator:(NSURL *)sasUrl{
    
    NSLog(@"Started video upload to Azure Storage");
    
    NSInputStream *videoStream = [[NSInputStream alloc] initWithURL:videoUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:sasUrl];
    
    [request setHTTPMethod:@"PUT"];
    
    [request addValue:@"video/mp4" forHTTPHeaderField:@"Content-Type"];
    
    NSData* myData = [NSData dataWithContentsOfURL:videoUrl];

    NSString *lengthStr = [NSString stringWithFormat: @"%d", [myData length]];
    
    [request addValue:lengthStr forHTTPHeaderField:@"Content-Length"];
    [request addValue:@"BlockBlob" forHTTPHeaderField:@"x-ms-blob-type"];
    [request setHTTPBodyStream:videoStream];
    
    NSLog(@"Sending upload request");
    
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSLog(@"Reading upload response");
        
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [HTTPResponse statusCode];
        
        if (error || statusCode != 201) {
            [self.delegate fetchingDataFailedWithError:error];
        } else{
            NSLog(@"Upload video to Azure Storage Completed");
            [self.delegate uploadCompleted];
        }
    }];
};

- (void)publishAsset: (NSString *)assetId withMetadata:(XYZVideo *)videoMetadata;
{
    NSString *publishAssetUrl = [urlAsString stringByAppendingString:@"publish"];
    
    NSMutableDictionary *payload = [[NSMutableDictionary alloc]initWithCapacity:10];
    
    [payload setObject:assetId forKey:@"AssetId"];
    [payload setObject:videoMetadata.title forKey:@"Title"];
    [payload setObject:videoMetadata.length forKey:@"Length"];
    [payload setObject:videoMetadata.resolution forKey:@"Resolution"];
    
    if(videoMetadata.videoDescription != (id)[NSNull null] && videoMetadata.videoDescription.length != 0 ){
        [payload setObject:videoMetadata.videoDescription forKey:@"Description"];
    }

    if(videoMetadata.formattedAddress != (id)[NSNull null] && videoMetadata.formattedAddress.length != 0 ){
        [payload setObject:videoMetadata.formattedAddress forKey:@"FormattedAddress"];
    }
    
    if(videoMetadata.qrTag != (id)[NSNull null] && videoMetadata.qrTag.length != 0 ){
        [payload setObject:videoMetadata.videoDescription forKey:@"QrTag"];
    }

    if(videoMetadata.longitude != (id)[NSNull null] && videoMetadata.longitude.length != 0 ){
        [payload setObject:videoMetadata.longitude forKey:@"Longitude"];
    }

    if(videoMetadata.videoDescription != (id)[NSNull null] && videoMetadata.videoDescription.length != 0 ){
        [payload setObject:videoMetadata.videoDescription forKey:@"Description"];
    }

    [self postEndpoint:publishAssetUrl withPayload:payload];
}

- (void)postEndpoint:(NSString *)endpoint withPayload:(NSDictionary *)payload {
    NSURL *url = [[NSURL alloc] initWithString:endpoint];
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingPrettyPrinted error:&err];

    if (err)
    {
        [self.delegate fetchingDataFailedWithError:err];
        NSLog(@"Error generating payload, details %@", err);
        return;
    }

    NSLog(@"Posting endpoint %@\n With data %@", url, jsonData);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [jsonData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: jsonData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        if (error)
        {
            [self.delegate fetchingDataFailedWithError:error];
        }
        else
        {
            [self.delegate publishCompleted];
        }
    }];
}

-(void) queryEndpoint: (NSString*) endpointUrl :(SEL)responseHandler{
    NSURL *url = [[NSURL alloc] initWithString:endpointUrl];
    
    NSLog(@"Querying endpoint %@", url);
    
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:url] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (error)
            {
                [self.delegate fetchingDataFailedWithError:error];
            }
            else
            {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [[self delegate] performSelector:responseHandler withObject:data];
#pragma clang diagnostic pop
            }
    }];
}
@end