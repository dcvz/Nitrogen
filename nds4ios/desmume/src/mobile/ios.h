//
//  ios.h
//  nds4ios
//
//  Created by David Chavez on 3/07/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

#include "path.h"
#include "video.h"
#include "saves.h"
#include "slot1.h"
#include "addons.h"
#include "throttle.h"
#include "render3D.h"
#include "NDSSystem.h"
#include "cheatSystem.h"

#define GPU_DISPLAY_WIDTH           256
#define GPU_DISPLAY_HEIGHT          192
#define GPU_SCREEN_SIZE_BYTES       (GPU_DISPLAY_WIDTH * GPU_DISPLAY_HEIGHT * GPU_DISPLAY_COLOR_DEPTH)

#define DS_FRAMES_PER_SECOND        59.8261

#define SPU_SAMPLE_SIZE             8
#define SPU_SAMPLE_RATE             44100.0
#define SPU_NUMBER_CHANNELS         2
#define SPU_SAMPLE_RESOLUTION       16
#define SPU_BUFFER_BYTES            ((SPU_SAMPLE_RATE / DS_FRAMES_PER_SECOND) * SPU_SAMPLE_SIZE)

extern VideoInfo video;
extern int frameskiprate;
extern volatile int currDisplayBuffer;
extern volatile int newestDisplayBuffer;
extern u16 displayBuffers[3][256 * 192 * 4];

struct MainLoopData {
    u64 freq;
    int framestoskip;
    int framesskipped;
    int skipnextframe;
    u64 lastticks;
    u64 curticks;
    u64 diffticks;
    u64 fpsticks;
    int fps;
    int fps3d;
    int fpsframecount;
    int toolframecount;
};

extern struct MainLoopData mainLoopData;
extern struct NDS_fw_config_data fw_config;

void core();
void user();
bool doRomLoad(const char* path, const char* logical);
void throttle(bool allowSleep = true, int forceFrameSkip = -1);
