//
//  Pin.h
//  Radar
//
//  Created by Martin Kautz on 18.12.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Pin : NSObject <MKAnnotation>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *mmsi;
- (id)initWithTitle:(NSString *) title andCoordinate:(CLLocationCoordinate2D)coordinate;

@end