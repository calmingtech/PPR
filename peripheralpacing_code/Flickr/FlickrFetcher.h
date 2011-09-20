//
//  FlickrFetcher.h
//  Created for CS193p Spring 2011
//  Stanford University
//

#import <Foundation/Foundation.h>

typedef enum {
	FlickrFetcherPhotoFormatSquare,
	FlickrFetcherPhotoFormatLarge,
	FlickrFetcherPhotoFormatThumbnail,
	FlickrFetcherPhotoFormatSmall,
	FlickrFetcherPhotoFormatMedium,
	FlickrFetcherPhotoFormatOriginal
} FlickrFetcherPhotoFormat;

@interface FlickrFetcher : NSObject
{
}

// Queries flickr.com to get an array of photos matching *any* of the given tags.
// The returned array contains a dictionary of flickr photo information: http://flickr.com/api/flickr.photos.search.html
// The best way to get a feel for the included return values is to call this method and take a look (with NSLog).

+ (NSArray *)photosWithTags:(NSArray *)tags;

// Returns a photo's image data for a given dictionary of flickr information about that photo.
// The returned NSData is suitable to be passed to [UIImage imageWithData:] or stored in a file or Core Data database.
// All four keys (id, server, farm, secret) must be in the flickrInfo dictionary or this will return nil.
// The dictionaries returned in the arrays by the method above are suitable for passing to this method unmodified.

+ (NSData *)imageDataForPhotoWithFlickrInfo:(NSDictionary *)flickrInfo format:(FlickrFetcherPhotoFormat)format;

@end
