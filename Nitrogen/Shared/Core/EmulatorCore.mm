//
//  EmulatorCore.m
//  Nitrogen
//
//  Created by David Chavez on 17/03/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

#import "EmulatorCore.h"
#import "OETimingUtils.h"
#import "OESoundInterface.h"

#include "ios.h"
#undef BOOL

// MARK: - Emulator Core

@interface EmulatorCore()
@property (assign, nonatomic) BOOL running;
@property (assign, nonatomic) BOOL shouldStop;
@property (assign, nonatomic) BOOL shouldResyncTime;
@end

@implementation EmulatorCore

// MARK: - Initializers

- (id)init {
    if ((self = [super init])) {
        NSUInteger count = [self audioBufferCount];
        ringBuffers = (__strong OERingBuffer **)calloc(count, sizeof(OERingBuffer *));

#ifdef HAVE_NEON
        INFO("HAVE_NEON\n");
        enable_runfast();
#endif

        if (video.layout > 2) {
            video.layout = video.layout_old = 0;
        }

        [self loadSettings];

        Desmume_InitOnce();
        NDS_FillDefaultFirmwareConfigData(&fw_config);

        INFO("Init NDS\n");

        int slot1_device_type = NDS_SLOT1_RETAIL;
        switch (slot1_device_type) {
            case NDS_SLOT1_NONE:
            case NDS_SLOT1_RETAIL:
            case NDS_SLOT1_R4:
            case NDS_SLOT1_RETAIL_NAND:
                break;
            default:
                slot1_device_type = NDS_SLOT1_RETAIL;
                break;
        }

        switch (addon_type) {
            case NDS_ADDON_NONE:
                break;
            case NDS_ADDON_CFLASH:
                break;
            case NDS_ADDON_RUMBLEPAK:
                break;
            case NDS_ADDON_GBAGAME:
                if (!strlen(GBAgameName)) {
                    addon_type = NDS_ADDON_NONE;
                    break;
                }
                // TODO: check for file exist
                break;
            case NDS_ADDON_GUITARGRIP:
                break;
            case NDS_ADDON_EXPMEMORY:
                break;
            case NDS_ADDON_PIANO:
                break;
            case NDS_ADDON_PADDLE:
                break;
            default:
                addon_type = NDS_ADDON_NONE;
                break;
        }

        slot1Change((NDS_SLOT1_TYPE)slot1_device_type);
        addonsChangePak(addon_type);

        NDS_Init();

        cur3DCore = 1;
        NDS_3D_ChangeCore(cur3DCore);

        LOG("Init sound core\n");
        CommonSettings.spu_advanced = true;
        CommonSettings.spuInterpolationMode = SPUInterpolation_Cosine;
        openEmuSoundInterfaceBuffer = [self ringBufferAtIndex:0];

        NSInteger result = SPU_ChangeSoundCore(SNDCORE_OPENEMU, (int)SPU_BUFFER_BYTES);
        if(result == -1) {
            SPU_ChangeSoundCore(SNDCORE_DUMMY, 0);
        }

        SPU_SetSynchMode(1, 2);
        SPU_SetVolume(100);

        static const char* nickname = "dcvz";
        fw_config.nickname_len = strlen(nickname);
        for(int i = 0 ; i < fw_config.nickname_len ; ++i)
            fw_config.nickname[i] = nickname[i];

        static const char* message = "let there be light";
        fw_config.message_len = strlen(message);
        for(int i = 0 ; i < fw_config.message_len ; ++i)
            fw_config.message[i] = message[i];

        fw_config.language =  1;

        video.setfilter(video.NONE);

        NDS_CreateDummyFirmware(&fw_config);

        InitSpeedThrottle();

        mainLoopData.freq = 1000;
        mainLoopData.lastticks = GetTickCount();
    }

    return self;
}


#pragma mark - Emulation Methods

- (BOOL)loadROM:(NSString *)path {
    strncpy(PathInfo::pathToModule, [[path stringByDeletingLastPathComponent] fileSystemRepresentation], MAX_PATH);
    bool ret = doRomLoad([path fileSystemRepresentation], [path fileSystemRepresentation]);
    return ret ? YES : NO;
}

- (void)startEmulation {
    if (!self.running) {
        self.running = YES;
        self.shouldStop = NO;

        [NSThread detachNewThreadSelector:@selector(updateFrame) toTarget:self withObject:nil];
    }
}

- (void)resetEmulation {

}

- (void)pauseEmulation {
    if (!self.running) { return; }
    //NDS_Pause();
    self.running = NO;
}

- (void)resumeEmulation {
    if (self.running) { return; }
    //NDS_UnPause();
    self.running = YES;
}

- (void)stopEmulation {
    self.shouldStop = YES;
    self.running = NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NDS_FreeROM();
        execute = false;
        NDS_Reset();
    });
}

- (void)executeFrame {
    core();
    user();
    //throttle(true, -1);
    [self draw];
}

- (void)updateFrame {
    gameInterval = 1.0 / [self frameInterval];
    NSTimeInterval gameTime = OEMonotonicTime();

    OESetThreadRealtime(gameInterval, 0.007, 0.03); // guessed from bsnes
    while (!self.shouldStop) {
        if (self.shouldResyncTime) {
            self.shouldResyncTime = NO;
            gameTime = OEMonotonicTime();
        }

        gameTime += gameInterval;

        @autoreleasepool {
            if (self.running) {
                [self executeFrame];
                self.updateFrameBlock();
            }
        }

        OEWaitUntil(gameTime);
    }
}


#pragma mark - Save States

- (void)saveStateAtSlot:(NSUInteger)slot {
    savestate_slot(slot);
}

- (void)restoreStateAtSlot:(NSUInteger)slot {
    loadstate_slot(slot);
}


#pragma mark - Cheats

- (NSUInteger)numberOfCheats {
    return (cheats != NULL) ? cheats->getSize() : 0;
}

- (NSString *)cheatNameAtPosition:(NSUInteger)position {
    if (cheats == NULL || position >= cheats->getSize()) return nil;
    return [NSString stringWithCString:cheats->getItemByIndex(position)->description encoding:NSUTF8StringEncoding];
}

- (BOOL)cheatEnabledAtPosition:(NSUInteger)position {
    if (cheats == NULL || position >= cheats->getSize()) return NO;
    return cheats->getItemByIndex(position)->enabled ? YES : NO;
}

- (NSString *)cheatCodeAtPosition:(NSUInteger)position {
    if (cheats == NULL || position >= cheats->getSize()) return nil;
    char buffer[1024] = {0};
    cheats->getXXcodeString(*cheats->getItemByIndex(position), buffer);
    return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}

- (NSUInteger)cheatTypeAtPosition:(NSUInteger)position {
    if (cheats == NULL || position >= cheats->getSize()) return 0;
    return cheats->getItemByIndex(position)->type;
}

- (void)addCheatWithDescription:(NSString *)description code:(NSString *)code {
    if (cheats == NULL) return;

    NSString *cheat = [code stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    cheats->add_AR([cheat UTF8String], [description UTF8String], FALSE);
}

- (void)updateCheatWithDescription:(NSString *)description code:(NSString *)code atPosition:(NSUInteger)position {
    if (cheats == NULL) return;

    const char* descBuff = [description cStringUsingEncoding:NSUTF8StringEncoding];
    const char* codeBuff = [code cStringUsingEncoding:NSUTF8StringEncoding];
    cheats->update_AR(codeBuff, descBuff, TRUE, position);
}

- (void)saveCheats {
    if (cheats) cheats->save();
}

- (void)setCheatEnabled:(BOOL)enabled atPosition:(NSUInteger)position {
    if (cheats) cheats->getItemByIndex(position)->enabled = enabled;
}

- (void)deleteCheatAtPosition:(NSUInteger)position {
    if(cheats) cheats->remove(position);
}


#pragma mark - Controller Methods

static BOOL _b[] = {0,0,0,0,0,0,0,0,0,0,0,0,0};
#define all_button _b[0], _b[1], _b[2], _b[3], _b[4], _b[5], _b[6], _b[7], _b[8], _b[9], _b[10], _b[11]

- (void)pressedButton:(NDSButton)button {
    _b[button] = true;
    NDS_setPad(all_button, false, false);
}

- (void)releasedButton:(NDSButton)button {
    _b[(int)button] = false;
    NDS_setPad(all_button, false, false);
}

- (void)touchScreenAtPoint:(CGPoint)point {
    NDS_setTouchPos(point.x, point.y);
}

- (void)touchesEnded {
    NDS_releaseTouch();
}


#pragma mark - Emulation Properties

- (const void *)videoBuffer {
    return video.finalBuffer();
}

- (NSInteger)fps {
    return mainLoopData.fps;
}

- (CGRect)screenRect {
    return CGRectMake(0, 0, video.width, video.height);
}

- (CGSize)aspectSize {
    return CGSizeMake(2, 3);
}

- (CGSize)bufferSize {
    return CGSizeMake(video.width, video.height);
}

- (GLenum)pixelFormat {
    return GL_RGBA;
}

- (GLenum)pixelType {
    return GL_UNSIGNED_BYTE;
}

- (GLint)internalPixelFormat {
    return GL_RGBA;
}

- (NSTimeInterval)frameInterval {
    return DS_FRAMES_PER_SECOND;
}

#pragma mark - Audio Properties
- (NSUInteger)audioBufferCount {
    return 1;
}

- (NSUInteger)channelCount {
    return SPU_NUMBER_CHANNELS;
}

- (double)audioSampleRate {
    return SPU_SAMPLE_RATE;
}

- (NSUInteger)channelCountForBuffer:(NSUInteger)buffer {
    return [self channelCount];
}

- (NSUInteger)audioBufferSizeForBuffer:(NSUInteger)buffer {
    return (NSUInteger)SPU_BUFFER_BYTES;
}

- (double)audioSampleRateForBuffer:(NSUInteger)buffer {
    return [self audioSampleRate];
}

- (void)getAudioBuffer:(void *)buffer frameCount:(NSUInteger)frameCount bufferIndex:(NSUInteger)index {
    [[self ringBufferAtIndex:index] read:buffer maxLength:frameCount * [self channelCountForBuffer:index] * sizeof(UInt16)];
}

- (NSUInteger)audioBitDepth {
    return SPU_SAMPLE_RESOLUTION;
}

- (OERingBuffer *)ringBufferAtIndex:(NSUInteger)index {
    if (ringBuffers[index] == nil) {
        ringBuffers[index] = [[OERingBuffer alloc] initWithLength:[self audioBufferSizeForBuffer:index] * 16];
    }

    return ringBuffers[index];
}

#pragma mark - Helper Methods

- (void)draw {
    int todo;
    bool alreadyDisplayed;

    {
        //find a buffer to display
        todo = newestDisplayBuffer;
        alreadyDisplayed = (todo == currDisplayBuffer);

        //something new to display:
        if(!alreadyDisplayed) {
            //start displaying a new buffer
            currDisplayBuffer = todo;
            video.srcBuffer = (u8*)displayBuffers[currDisplayBuffer];
        }
    }

    //convert pixel format to 32bpp for compositing
    //why do we do this over and over? well, we are compositing to
    //filteredbuffer32bpp, and it needs to get refreshed each frame..
    //const int size = video.size();
    const int size = 256*384;
    u16* src = (u16*)video.srcBuffer;

    u32* dest = video.buffer;
    for(int i=0;i<size;++i)
        *dest++ = 0xFF000000ul | RGB15TO32_NOALPHA(*src++);

    video.filter();
}


- (void)loadSettings {
    CommonSettings.num_cores = sysconf( _SC_NPROCESSORS_ONLN );
    NSLog(@"%i cores detected", CommonSettings.num_cores);
    CommonSettings.cheatsDisable = false;
    CommonSettings.autodetectBackupMethod = 0;
    //enableMicrophone = false;

    video.rotation =  0;
    video.rotation_userset = video.rotation;
    video.layout_old = video.layout = 0;
    video.swap = 1;

    CommonSettings.hud.FpsDisplay = true;
    CommonSettings.hud.FrameCounterDisplay = false;
    CommonSettings.hud.ShowInputDisplay = false;
    CommonSettings.hud.ShowGraphicalInputDisplay = false;
    CommonSettings.hud.ShowLagFrameCounter = false;
    CommonSettings.hud.ShowMicrophone = false;
    CommonSettings.hud.ShowRTC = false;
    video.screengap = 256*192*4;
    CommonSettings.showGpu.main = 1;
    CommonSettings.showGpu.sub = 1;
    frameskiprate = 1;

    CommonSettings.micMode = (TCommonSettings::MicMode)1;

    CommonSettings.advanced_timing = false;
    CommonSettings.CpuMode = 1;
    CommonSettings.jit_max_block_size = 12;

    CommonSettings.GFX3D_Zelda_Shadow_Depth_Hack = 0;
    CommonSettings.GFX3D_HighResolutionInterpolateColor = 0;
    CommonSettings.GFX3D_EdgeMark = 0;
    CommonSettings.GFX3D_Fog = 1;
    CommonSettings.GFX3D_Texture = 1;
    CommonSettings.GFX3D_LineHack = 0;
    useMmapForRomLoading = false;
    fw_config.language = 1;

    CommonSettings.wifi.mode = 0;
    CommonSettings.wifi.infraBridgeAdapter = 0;
}

@end
