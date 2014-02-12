//
//  SBBrightCoveVideoUploadOperation.m
//
//  Created by Cory Hymel on 2/6/14.
//  Copyright (c) 2014 Simble. All rights reserved.
//

#import "SBBrightCoveVideoUploadOperation.h"

#define kBrightCoveServiceURL  @"http://api.brightcove.com/services/post"

@interface SBBrightCoveVideoUploadOperation ()
@property NSURL     *videoURL;
@property NSString  *fileExtension;
@end

@implementation SBBrightCoveVideoUploadOperation

- (id)initWithLocalVideoWithURL:(NSURL*)videoURL fileExtenstion:(NSString*)fileExtension {
    if (![super init])
        return nil;
    self.videoURL      = videoURL;
    self.fileExtension = fileExtension;
    return self;
}

/**
 There are few things that were not built to be as dynamic as possible. They are: 
 1. The video file extension. This classes uses .m4v as default. 
 2. The video name. It auto creates a unique video name based on the data in the format of MMddyyyyHHmm using the current NSDate for reference.
 3. Video description: The video description is set as "Created at: MMddyyyHHmm" format using the current NSDate for reference.
 */

- (void)main {
    
    @autoreleasepool {
        
        if (self.isCancelled)
            return;
        
        NSAssert(self.fileExtension, @"A file extension is required.");
        NSAssert(self.videoURL,      @"A NSURL to a video is required.");

        // ==============
        // Creating base content
        // ==============
        
        //This is how we name our files
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"MMddyyyyHHmm"];
        
        
        //Set the video name
        NSString *name;
        if (!self.videoName) {
           name = [dateFormatter stringFromDate:[NSDate date]];
        }
        else {
            name = self.videoName;
        }
        
        //Set the video description
        NSString *videoDescription;
        if (!self.videoDescription) {
            videoDescription   = [NSString stringWithFormat:@"Created at: %@", name];
        }
        else {
            videoDescription = self.videoDescription;
        }
        
        NSString *videoFileName      = [NSString stringWithFormat:@"%@.%@", name, self.fileExtension];
        NSString *contentDisposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name, videoFileName];
        
       
        //Parameters for the video object, more fields can be found here: https://docs.brightcove.com/en/video-cloud/media/reference.html#Video
        NSMutableDictionary *videoParameters = [NSMutableDictionary new];
        [videoParameters setValue:name forKey:@"name"];
        [videoParameters setValue:videoDescription forKey:@"shortDescription"];
        
        //Parameters for create_video endpoint
        NSMutableDictionary *postParameters = [NSMutableDictionary new];
        [postParameters setValue:kBrightCoveWriteAPIKey forKey:@"token"];
        [postParameters setValue:videoParameters        forKey:@"video"];
        [postParameters setValue:videoFileName          forKey:@"filename"];
        [postParameters setValue:@"false"               forKey:@"create_multiple_renditions"];
        
        //Create the JSON adding in the method call
        NSMutableDictionary *JSONDictionary = [NSMutableDictionary new];
        [JSONDictionary setValue:@"create_video" forKey:@"method"];
        [JSONDictionary setValue:postParameters forKey:@"params"];
        
        //Convert to JSON
        NSError *conversionError;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:JSONDictionary
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&conversionError];
        
        if (conversionError) {
            NSLog(@"error converting to JSON: %@", conversionError);
            self.completion ? self.completion(NO, @"Could not convert movie data to JSON format.") : nil;
            return;
        }
        
        //Create the post
        NSString *post = [[NSString alloc] initWithData:jsonData encoding:NSASCIIStringEncoding];

        
        // BrightCove service URL
        NSString *urlString     = [NSString stringWithFormat:kBrightCoveServiceURL];
        NSString *escUrlString  = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *boundary      = @"MULTI_PART_BOUNDRY";
        NSString *contentType   = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        
        
        
        // ==============
        // Build post request
        // ==============
        
        NSMutableData *postData = [[NSMutableData alloc] init];
        
        // Add JSON-RPC
        [postData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"JSON\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[@"Content-Type: application/json\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
        
        // Add video
        [postData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[contentDisposition dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSData *videoData = [NSData dataWithContentsOfURL:self.videoURL];
        [postData appendData:videoData];
        [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

        
        
        // ==============
        // Creating request
        // ==============
        
        NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] init];
        [theRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
        [theRequest setURL:[NSURL URLWithString:escUrlString]];
        [theRequest setHTTPMethod:@"POST"];
        [theRequest setHTTPBody:postData];
        
        
        
        //Check right before we make the network call
        if (self.isCancelled)
            return;
        
        
        // ==============
        // Execute request
        // ==============
        
        NSHTTPURLResponse *response;
        NSError *responseError;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:theRequest
                                                     returningResponse:&response
                                                                 error:&responseError];
        
        
        
        // ==============
        // Error handling
        // ==============
        
        if (responseError) {
            NSString *errorString = [NSString stringWithFormat:@"Failed with status code %ld. This means:\n%@", (long)response.statusCode,[NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]];
            
            self.completion ? self.completion(NO, errorString) : nil;
        }
       
        else if (!responseData) {
            self.completion ? self.completion(NO, @"Could not establish a connection.") : nil;
        }
        
        else {
            self.completion ? self.completion(YES, nil) : nil;
        }

    }
}


@end
