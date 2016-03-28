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

typedef NS_ENUM(NSUInteger, NDSButton)
{
    NDSButtonRight,
    NDSButtonLeft,
    NDSButtonDown,
    NDSButtonUp,
    NDSButtonSelect,
    NDSButtonStart,
    NDSButtonB,
    NDSButtonA,
    NDSButtonY,
    NDSButtonX,
    NDSButtonL,
    NDSButtonR,
    NDSButtonCount
};


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
- (void)resumeEmulation;
- (void)stopEmulation;

#pragma mark - Cheats
- (NSUInteger)numberOfCheats;
- (NSString *)cheatNameAtPosition:(NSUInteger)position;
- (BOOL)cheatEnabledAtPosition:(NSUInteger)position;
- (NSString *)cheatCodeAtPosition:(NSUInteger)position;
- (NSUInteger)cheatTypeAtPosition:(NSUInteger)position;
- (void)addCheatWithDescription:(NSString *)description code:(NSString *)code;
- (void)updateCheatWithDescription:(NSString *)description code:(NSString *)code atPosition:(NSUInteger)position;
- (void)saveCheats;
- (void)setCheatEnabled:(BOOL)enabled atPosition:(NSUInteger)position;
- (void)deleteCheatAtPosition:(NSUInteger)position;

#pragma mark - Controller Properties
- (void)pressedButton:(NDSButton)button;
- (void)releasedButton:(NDSButton)button;
- (void)touchScreenAtPoint:(CGPoint)point;
- (void)touchesEnded;

#pragma mark - Emulation Properties
- (const void *)videoBuffer;
- (NSInteger)fps;
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
