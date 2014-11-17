//
//  ViewController.m
//  Radar
//
//  Created by Martin Kautz on 10.11.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "ViewController.h"
#import "CoolCell.h"
#import "libais.h"

@interface ViewController ()
// ---------------------------------------------------------------------------------------------------------------------
@property (nonatomic, strong)               NSInputStream   *inputStream;
@property (nonatomic, strong)               NSMutableData   *data;
@property (nonatomic, strong)               NSMutableArray  *theStore;
@property (nonatomic, assign)               NSInteger       count;
@property (nonatomic, weak)     IBOutlet    UITableView     *theTableView;
@property (nonatomic, weak)     IBOutlet    UIButton        *theButton;
@property (nonatomic, weak)     IBOutlet    UITextField     *theTextField;
// ---------------------------------------------------------------------------------------------------------------------
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.theStore = [NSMutableArray new];
    [self.theButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.theButton addTarget:self action:@selector(touch:) forControlEvents:UIControlEventTouchUpInside];
    [self.theButton setBackgroundColor:[UIColor darkGrayColor]];
    [self.theButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.theButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    self.theButton.layer.cornerRadius = 6.0f;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)touch:(id)sender
{
    if (self.inputStream) {
        [self.theButton setTitle:@"Start" forState:UIControlStateNormal];
        [self stopListening];
    } else {
        [self.theButton setTitle:@"Stop" forState:UIControlStateNormal];
        [self startListening];
    }
}

- (void)startListening
{
    self.count = 0;
    CFReadStreamRef readStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"ais.exploratorium.edu", 80, &readStream, NULL);
    self.inputStream = (NSInputStream *)CFBridgingRelease(readStream);
    [self.inputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    self.theTextField.text = @"...";
}

- (void)stopListening
{
    [self.inputStream close];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.inputStream = nil;
    [self.theStore removeAllObjects];
    [self.theTableView reloadData];
    self.count = 0;
    self.theTextField.text = [NSString stringWithFormat:@"%d", 0];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {

        case NSStreamEventNone:
            NSLog(@"NSStreamEventNone");
            break;

        case NSStreamEventOpenCompleted:
            NSLog(@"NSStreamEventOpenCompleted");
            break;

        case NSStreamEventHasBytesAvailable:
        {
            if(!self.data) {
                self.data = [NSMutableData data];
            }
            uint8_t buf[1024];
            unsigned int len = 0;
            len = (int)[(NSInputStream *)self.inputStream read:buf maxLength:1024];
            if(len) {
                [self.data appendBytes:(const void *)buf length:len];

                NSString *newStrAlternate   = [[NSString alloc]initWithData:self.data encoding:NSUTF8StringEncoding];
                NSArray *exploded           = [newStrAlternate componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                NSString *part              = nil;

                for (part in exploded) {
                    if ([part hasPrefix:@"!A"]) {
                        self.count ++;
                        self.theTextField.text = [NSString stringWithFormat:@"%ld", (long)self.count];
                        [self.theStore addObject:part];
                        if (self.theStore.count > 20) {
                            [self.theStore removeObjectAtIndex:0];
                        }
                        [self.theTableView reloadData];
                    } 
                }

                self.data = nil;

            } else {
                NSLog(@"no buffer!");
            }

            break;
        }

        case NSStreamEventHasSpaceAvailable:
            NSLog(@"NSStreamEventHasSpaceAvailable");
            break;

        case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccurred");
            break;

        case NSStreamEventEndEncountered:
        {
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            aStream = nil;
            break;
        }
        default:
            NSLog(@"Unknown event");
    }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.theStore.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CoolCell *coolCell = (CoolCell *)[tableView dequeueReusableCellWithIdentifier:@"CoolCell" forIndexPath:indexPath];
    NSString *rawRecord = self.theStore[indexPath.row];
    coolCell.theTextfield.text = [self decode:rawRecord];
    return coolCell;
}

- (NSString *)decode:(NSString *)string
{
    struct gps_device_t     session;
    struct ais_t            ais;
    const char *msg = [string cStringUsingEncoding:NSUTF8StringEncoding];
    char dest[string.length];
    strncpy(dest, msg, sizeof(dest));
    size_t len = sizeof(dest);
    printf("msg: %s\nlen: %zu\n", dest, len);
    char buf[JSON_VAL_MAX * 2 + 1];
    size_t buflen = sizeof(buf);

    aivdm_decode(dest, len, &session, &ais, 0);
    printf("type: %d, repeat: %d, mmsi: %d\n", ais.type, ais.repeat, ais.mmsi);
    json_aivdm_dump(&ais, NULL, true, buf, buflen);
    printf("JSN: %s\n", buf);
    return [NSString stringWithFormat:@"%s", buf];
}


@end
