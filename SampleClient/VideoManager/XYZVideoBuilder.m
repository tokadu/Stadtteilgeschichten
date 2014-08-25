#import "XYZVideoBuilder.h"
#import "XYZVideo.h"

@implementation XYZVideoBuilder

+ (NSArray *)videosFromJSON:(NSData *)objectNotation error:(NSError **)error
{
    NSError *localError = nil;
    NSArray *parsedObject = [NSJSONSerialization JSONObjectWithData:objectNotation options:0 error:&localError];
    
    if (localError != nil) {
        *error = localError;
        return nil;
    }
    
    NSMutableArray *videos = [[NSMutableArray alloc] init];
    NSLog(@"Count %d", parsedObject.count);
    
    for (NSDictionary *videoDic in parsedObject) {
        id video = [XYZVideoBuilder createVideo:videoDic];
        [videos addObject:video];
    }
    
    NSLog(@"Parsing Complete");
    
    return videos;
}

+ (XYZVideo *)singleVideoFromJSON:(NSData *)objectNotation error:(NSError **)error
{
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:objectNotation options:0 error:&localError];
    
    if (localError != nil) {
        *error = localError;
        return nil;
    }
    
    XYZVideo *video = [self createVideo:parsedObject];
    
    NSLog(@"Parsing Complete");
    
    return video;
}

+ (XYZVideo *) createVideo:(NSDictionary *)videoDictionary
{
    XYZVideo *video = [[XYZVideo alloc] init];
    
    video.videoId = [@([[videoDictionary objectForKey:@"Id" ] integerValue]) description];
    video.title = [videoDictionary objectForKey:@"Title"];
    video.length = [videoDictionary objectForKey:@"Length"];
    
    if ([video.length isKindOfClass:[NSNull class]]){
        video.length = @"";
    }

    video.videoDescription = [videoDictionary objectForKey:@"Description"];
    video.formattedAddress = [videoDictionary objectForKey:@"FormattedAddress"];
    video.latitude = [videoDictionary objectForKey:@"Latitude"];
    video.longitude = [videoDictionary objectForKey:@"Longitude"];
    video.qrTag = [videoDictionary objectForKey:@"QrTag"];
    
    NSArray *playbackUrlsArray = [videoDictionary objectForKey:@"Videos"];
    NSDictionary *playbackUrl;
    
    if([playbackUrlsArray count]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(EncodingType == %@)", @"application/vnd.apple.mpegurl"];
        NSArray *filteredArray = [playbackUrlsArray filteredArrayUsingPredicate:predicate];
        
        if([filteredArray count]){
            playbackUrl = filteredArray[0];
        } else {
            playbackUrl = playbackUrlsArray[0];
        }
        
        NSString *sanitizedUrl = [[playbackUrl objectForKey:@"Url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        video.playbackUrl = sanitizedUrl;
    }
    
    NSArray *thumbnails = [videoDictionary objectForKey:@"Thumbnails"];
    NSDictionary *videoThumbnail;
    
    if([thumbnails count]){
        videoThumbnail = thumbnails[0];
        video.thumbnailUrl = [videoThumbnail objectForKey:@"Url"];
    }
    
    return video;
}

@end