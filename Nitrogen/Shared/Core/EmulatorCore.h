//
//  EmulatorCore.h
//  NItrogen
//
//  Created by David Chavez on 17/03/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "OERingBuffer.h"

@interface EmulatorCore : NSObject {
    NSTimeInterval gameInterval;

    OERingBuffer __strong **ringBuffers;
    double _sampleRate;
}


@property (nonatomic, copy) void (^updateFrameBlock)();
@property (strong, nonatomic) NSString *batterySavesPath;

#pragma mark - Emulation Setup Methods
- (BOOL)loadROM:(NSString *)path;
- (void)startEmulation;
- (void)resetEmulation;
- (void)pauseEmulation;
- (void)stop;

#pragma mark - Controller Properties
- (void)touchScreenAtPoint:(CGPoint)point;
- (void)touchesEnded;

#pragma mark - Emulation Properties
- (const void *)videoBuffer;
- (CGRect)screenRect;
- (CGSize)aspectSize;
- (CGSize)bufferSize;
- (GLenum)pixelFormat;
- (GLenum)pixelType;
- (GLint)internalPixelFormat;
- (NSTimeInterval)frameInterval;

#pragma mark - Audio Properties
- (double)audioSampleRate;
- (NSUInteger)channelCount;
- (NSUInteger)audioBufferCount;
- (void)getAudioBuffer:(void *)buffer frameCount:(NSUInteger)frameCount bufferIndex:(NSUInteger)index;
- (NSUInteger)audioBitDepth;
- (NSUInteger)channelCountForBuffer:(NSUInteger)buffer;
- (NSUInteger)audioBufferSizeForBuffer:(NSUInteger)buffer;
- (double)audioSampleRateForBuffer:(NSUInteger)buffer;
- (OERingBuffer *)ringBufferAtIndex:(NSUInteger)index;

@end
