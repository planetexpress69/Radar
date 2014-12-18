//
//  Pin.m
//  Radar
//
//  Created by Martin Kautz on 18.12.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "Pin.h"

@implementation Pin

- (id)initWithTitle:(NSString *) title andCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (self = [super init]) {
        _coordinate     = coordinate;
        _title          = title;
    }
    return self;
}


- (void)dealloc {
}


@end