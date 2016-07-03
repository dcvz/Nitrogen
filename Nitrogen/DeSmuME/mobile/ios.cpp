//
//  ios.cpp
//  Nitrogen
//
//  Created by David Chavez on 3/07/16.
//  Copyright © 2016 Mystical. All rights reserved.
//

#include "ios.h"
#include "SPU.h"
#include "types.h"
#include "debug.h"
#include "slot1.h"
#include "version.h"
#include "metaspu.h"
#include "rasterize.h"

int scanline_filter_a = 0, scanline_filter_b = 2, scanline_filter_c = 2, scanline_filter_d = 4;

GPU3DInterface *core3DList[] = {
    &gpu3DNull,
    //&gpu3Dgl,
    &gpu3DRasterize,
    NULL
};

void Mic_DeInit(){}
BOOL Mic_Init(){return true;}
void Mic_Reset(){}
u8 Mic_ReadSample(){return 0x99;}
void mic_savestate(EMUFILE* os){}
bool mic_loadstate(EMUFILE* is, int size){ return true;}

volatile bool execute = false;
volatile bool paused = true;
volatile BOOL pausedByMinimize = FALSE;
bool autoframeskipenab=1;
int frameskiprate=1;
int lastskiprate=0;
int emu_paused = 0;
bool frameAdvance = false;
bool continuousframeAdvancing = false;
bool staterewindingenabled = false;
bool FrameLimit = true;
const char* IniName = NULL;
bool useMmapForRomLoading;
bool enableMicrophone = false;

//triple buffering logic
u16 displayBuffers[3][256*192*4];
volatile int currDisplayBuffer=-1;
volatile int newestDisplayBuffer=-2;

struct MainLoopData mainLoopData = {0};
struct NDS_fw_config_data fw_config;

VideoInfo video;


// MARK: - Emulator C++ Methods

bool NDS_Pause(bool showMsg = true) {
    if(paused) return false;

    emu_halt();
    paused = TRUE;
    SPU_Pause(1);
    while (!paused) {}
    if (showMsg) INFO("Emulation paused\n");

    return true;
}

void NDS_UnPause(bool showMsg = true) {
    if (/*romloaded &&*/ paused) {
        paused = FALSE;
        pausedByMinimize = FALSE;
        execute = TRUE;
        SPU_Pause(0);
        if (showMsg) INFO("Emulation unpaused\n");

    }
}

void display() {
    if(int diff = (currDisplayBuffer+1)%3 - newestDisplayBuffer)
        newestDisplayBuffer += diff;
    else newestDisplayBuffer = (currDisplayBuffer+2)%3;

    memcpy(displayBuffers[newestDisplayBuffer],GPU_screen,256*192*4);
}

void throttle(bool allowSleep, int forceFrameSkip) {
    int skipRate = (forceFrameSkip < 0) ? frameskiprate : forceFrameSkip;
    int ffSkipRate = (forceFrameSkip < 0) ? 9 : forceFrameSkip;

    if(lastskiprate != skipRate) {
        lastskiprate = skipRate;
        mainLoopData.framestoskip = 0; // otherwise switches to lower frameskip rates will lag behind
    }

    if(!mainLoopData.skipnextframe || forceFrameSkip == 0 || frameAdvance || (continuousframeAdvancing && !FastForward)) {
        mainLoopData.framesskipped = 0;

        if (mainLoopData.framestoskip > 0)
            mainLoopData.skipnextframe = 1;
    } else {
        mainLoopData.framestoskip--;

        if (mainLoopData.framestoskip < 1)
            mainLoopData.skipnextframe = 0;
        else
            mainLoopData.skipnextframe = 1;

        mainLoopData.framesskipped++;

        NDS_SkipNextFrame();
    }

    if(FastForward) {
        if(mainLoopData.framesskipped < ffSkipRate) {
            mainLoopData.skipnextframe = 1;
            mainLoopData.framestoskip = 1;
        }
        if (mainLoopData.framestoskip < 1)
            mainLoopData.framestoskip += ffSkipRate;
    } else if((/*autoframeskipenab && frameskiprate ||*/ FrameLimit) && allowSleep) {
        SpeedThrottle();
    }

    if (autoframeskipenab && frameskiprate) {
        if(!frameAdvance && !continuousframeAdvancing) {
            AutoFrameSkip_NextFrame();
            if (mainLoopData.framestoskip < 1)
                mainLoopData.framestoskip += AutoFrameSkip_GetSkipAmount(0,skipRate);
        }
    } else {
        if (mainLoopData.framestoskip < 1)
            mainLoopData.framestoskip += skipRate;
    }

    if (frameAdvance && allowSleep) {
        frameAdvance = false;
        emu_halt();
        SPU_Pause(1);
    }

    if(execute && emu_paused && !frameAdvance) {
        // safety net against running out of control in case this ever happens.
        NDS_UnPause(); NDS_Pause();
    }

    //ServiceDisplayThreadInvocations();
}

void user() {
    display();

    gfx3d.frameCtrRaw++;
    if(gfx3d.frameCtrRaw == 60) {
        mainLoopData.fps3d = gfx3d.frameCtr;
        gfx3d.frameCtrRaw = 0;
        gfx3d.frameCtr = 0;
    }

    mainLoopData.toolframecount++;

    //Update_RAM_Search(); // Update_RAM_Watch() is also called.

    mainLoopData.fpsframecount++;
    mainLoopData.curticks = GetTickCount();
    bool oneSecond = mainLoopData.curticks >= mainLoopData.fpsticks + mainLoopData.freq;
    if(oneSecond) {
        mainLoopData.fps = mainLoopData.fpsframecount;
        mainLoopData.fpsframecount = 0;
        mainLoopData.fpsticks = GetTickCount();
    }

    if(nds.idleFrameCounter==0 || oneSecond) {
        //calculate a 16 frame arm9 load average
        for(int cpu = 0; cpu < 2; cpu++) {
            int load = 0;
            //printf("%d: ",cpu);
            for(int i = 0; i < 16; i++) {
                //blend together a few frames to keep low-framerate games from having a jittering load average
                //(they will tend to work 100% for a frame and then sleep for a while)
                //4 frames should handle even the slowest of games
                s32 sample =
                nds.runCycleCollector[cpu][(i+0+nds.idleFrameCounter)&15]
                +	nds.runCycleCollector[cpu][(i+1+nds.idleFrameCounter)&15]
                +	nds.runCycleCollector[cpu][(i+2+nds.idleFrameCounter)&15]
                +	nds.runCycleCollector[cpu][(i+3+nds.idleFrameCounter)&15];
                sample /= 4;
                load = load/8 + sample*7/8;
            }
            //printf("\n");
            load = std::min(100,std::max(0,(int)(load*100/1120380)));
        }
    }
}

void core() {
    NDS_beginProcessingInput();
    NDS_endProcessingInput();
    NDS_exec<false>();
    SPU_Emulate_user();
}

void unpause() {
    if(!execute) NDS_Pause(false);
    if (emu_paused && autoframeskipenab && frameskiprate) AutoFrameSkip_IgnorePreviousDelay();
    NDS_UnPause();
}

bool doRomLoad(const char* path, const char* logical) {
    NDS_Pause(false);
    if(NDS_LoadROM(path, logical) >= 0) {
        INFO("Loading %s was successful\n",path);
        unpause();
        if (autoframeskipenab && frameskiprate) AutoFrameSkip_IgnorePreviousDelay();
        return true;
    }
    return false;
}

bool nds4droid_loadrom(const char* path) {
    return doRomLoad(path, path);
}
