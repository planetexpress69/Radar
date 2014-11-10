//
//  ViewController.m
//  Radar
//
//  Created by Martin Kautz on 10.11.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "ViewController.h"
#import "CoolCell.h"

@interface ViewController ()
// ---------------------------------------------------------------------------------------------------------------------
@property (nonatomic, strong)               NSInputStream   *inputStream;
@property (nonatomic, strong)               NSOutputStream  *outputStream;
@property (nonatomic, strong)               NSMutableData   *data;
@property (nonatomic, strong)               NSMutableArray  *theStore;
@property (nonatomic, weak)     IBOutlet    UITableView     *theTableView;
@property (nonatomic, weak)     IBOutlet    UIButton        *theButton;
@property (nonatomic, assign)               BOOL            isListening;
// ---------------------------------------------------------------------------------------------------------------------
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.theStore = [NSMutableArray new];
    [self.theButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.theButton addTarget:self action:@selector(touch:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)touch:(id)sender
{
    if (self.isListening) {
        [self.theButton setTitle:@"Start" forState:UIControlStateNormal];
        [self stopListening];
    } else {
        [self.theButton setTitle:@"Stop" forState:UIControlStateNormal];
        [self startListening];
    }
    self.isListening = !self.isListening;
}

- (void)startListening
{
    CFReadStreamRef readStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"ais.exploratorium.edu", 80, &readStream, NULL);
    self.inputStream = (NSInputStream *)CFBridgingRelease(readStream);
    [self.inputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
}

- (void)stopListening
{
    [self.inputStream close];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.inputStream = nil;
    [self.theStore removeAllObjects];
    [self.theTableView reloadData];

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
            len = [(NSInputStream *)self.inputStream read:buf maxLength:1024];
            if(len) {
                [self.data appendBytes:(const void *)buf length:len];

                NSString *newStrAlternate = [[NSString alloc]initWithData:self.data encoding:NSUTF8StringEncoding];
                NSArray *exploded = [newStrAlternate componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

                NSString *part;

                for (part in exploded) {
                    if ([part hasPrefix:@"!AIVDM"]) {
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
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
            break;

            NSLog(@"NSStreamEventEndEncountered");
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
    coolCell.theTextfield.text = self.theStore[indexPath.row];
    return coolCell;

}



@end
