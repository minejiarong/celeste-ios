/*
 Simple DirectMedia Layer
 Copyright (C) 1997-2022 Sam Lantinga <slouken@libsdl.org>
 
 This software is provided 'as-is', without any express or implied
 warranty.  In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not
 claim that you wrote the original software. If you use this software
 in a product, an acknowledgment in the product documentation would be
 appreciated but is not required.
 2. Altered source versions must be plainly marked as such, and must not be
 misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.
 */

/*
 * @author Mark Callow, www.edgewise-consulting.com.
 *
 * Thanks to Alex Szpakowski, @slime73 on GitHub, for his gist showing
 * how to add a CAMetalLayer backed view.
 */

#include "../../SDL_internal.h"

#if SDL_VIDEO_DRIVER_UIKIT && (SDL_VIDEO_VULKAN || SDL_VIDEO_METAL)

#include "SDL_syswm.h"
#include "../SDL_sysvideo.h"

#import "SDL_uikitwindow.h"
#import "SDL_uikitmetalview.h"
#import <GameController/GameController.h>

static GCKeyboard *s_keyboard = nil;

static SDL_Scancode GCKeyCodeToSDLScancode(GCKeyCode keyCode) {
    // Map GCKeyCode to SDL_Scancode
    switch (keyCode) {
        case GCKeyCodeSpace: return SDL_SCANCODE_SPACE;
        case GCKeyCodeLeftArrow: return SDL_SCANCODE_LEFT;
        case GCKeyCodeRightArrow: return SDL_SCANCODE_RIGHT;
        case GCKeyCodeUpArrow: return SDL_SCANCODE_UP;
        case GCKeyCodeDownArrow: return SDL_SCANCODE_DOWN;
        case GCKeyCodeEscape: return SDL_SCANCODE_ESCAPE;
        case GCKeyCodeEnter: return SDL_SCANCODE_RETURN;
        case GCKeyCodeTab: return SDL_SCANCODE_TAB;
        case GCKeyCodeLeftShift: return SDL_SCANCODE_LSHIFT;
        case GCKeyCodeRightShift: return SDL_SCANCODE_RSHIFT;
        case GCKeyCodeLeftControl: return SDL_SCANCODE_LCTRL;
        case GCKeyCodeRightControl: return SDL_SCANCODE_RCTRL;
        case GCKeyCodeLeftAlt: return SDL_SCANCODE_LALT;
        case GCKeyCodeRightAlt: return SDL_SCANCODE_RALT;
        case GCKeyCodeW: return SDL_SCANCODE_W;
        case GCKeyCodeA: return SDL_SCANCODE_A;
        case GCKeyCodeS: return SDL_SCANCODE_S;
        case GCKeyCodeD: return SDL_SCANCODE_D;
        case GCKeyCodeJ: return SDL_SCANCODE_J;
        case GCKeyCodeK: return SDL_SCANCODE_K;
        case GCKeyCodeZ: return SDL_SCANCODE_Z;
        case GCKeyCodeX: return SDL_SCANCODE_X;
        case GCKeyCodeC: return SDL_SCANCODE_C;
        case GCKeyCodeV: return SDL_SCANCODE_V;
        case GCKeyCodeB: return SDL_SCANCODE_B;
        case GCKeyCodeN: return SDL_SCANCODE_N;
        case GCKeyCodeM: return SDL_SCANCODE_M;
        case GCKeyCodeQ: return SDL_SCANCODE_Q;
        case GCKeyCodeE: return SDL_SCANCODE_E;
        case GCKeyCodeR: return SDL_SCANCODE_R;
        case GCKeyCodeF: return SDL_SCANCODE_F;
        case GCKeyCodeT: return SDL_SCANCODE_T;
        case GCKeyCodeG: return SDL_SCANCODE_G;
        case GCKeyCodeY: return SDL_SCANCODE_Y;
        case GCKeyCodeH: return SDL_SCANCODE_H;
        case GCKeyCodeU: return SDL_SCANCODE_U;
        case GCKeyCodeI: return SDL_SCANCODE_I;
        case GCKeyCodeO: return SDL_SCANCODE_O;
        case GCKeyCodeP: return SDL_SCANCODE_P;
        case GCKeyCodeL: return SDL_SCANCODE_L;
        case GCKeyCode0: return SDL_SCANCODE_0;
        case GCKeyCode1: return SDL_SCANCODE_1;
        case GCKeyCode2: return SDL_SCANCODE_2;
        case GCKeyCode3: return SDL_SCANCODE_3;
        case GCKeyCode4: return SDL_SCANCODE_4;
        case GCKeyCode5: return SDL_SCANCODE_5;
        case GCKeyCode6: return SDL_SCANCODE_6;
        case GCKeyCode7: return SDL_SCANCODE_7;
        case GCKeyCode8: return SDL_SCANCODE_8;
        case GCKeyCode9: return SDL_SCANCODE_9;
        case GCKeyCodeF1: return SDL_SCANCODE_F1;
        case GCKeyCodeF2: return SDL_SCANCODE_F2;
        case GCKeyCodeF3: return SDL_SCANCODE_F3;
        case GCKeyCodeF4: return SDL_SCANCODE_F4;
        case GCKeyCodeF5: return SDL_SCANCODE_F5;
        case GCKeyCodeF6: return SDL_SCANCODE_F6;
        case GCKeyCodeF7: return SDL_SCANCODE_F7;
        case GCKeyCodeF8: return SDL_SCANCODE_F8;
        case GCKeyCodeF9: return SDL_SCANCODE_F9;
        case GCKeyCodeF10: return SDL_SCANCODE_F10;
        case GCKeyCodeF11: return SDL_SCANCODE_F11;
        case GCKeyCodeF12: return SDL_SCANCODE_F12;
        default: return SDL_SCANCODE_UNKNOWN;
    }
}

static void setupKeyboardInput(void) {
    if (@available(iOS 13.4, *)) {
        // Listen for keyboard connect/disconnect notifications
        [[NSNotificationCenter defaultCenter] addObserverForName:GCKeyboardDidConnectNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            GCKeyboard *keyboard = [GCKeyboard coalescedKeyboard];
            if (keyboard) {
                s_keyboard = keyboard;

                // Setup keyboard input handler
                keyboard.keyboardInput.keyChangedHandler = ^(GCKeyboardInput *keyboardInput, GCControllerButtonInput *button, GCKeyCode keyCode, BOOL pressed) {
                    SDL_Scancode scancode = GCKeyCodeToSDLScancode(keyCode);
                    if (scancode != SDL_SCANCODE_UNKNOWN) {
                        SDL_Event event;
                        SDL_zero(event);
                        event.type = pressed ? SDL_KEYDOWN : SDL_KEYUP;
                        event.key.keysym.scancode = scancode;
                        event.key.keysym.sym = SDL_GetKeyFromScancode(scancode);
                        event.key.keysym.mod = KMOD_NONE;
                        event.key.repeat = 0;
                        SDL_PushEvent(&event);
                    }
                };
            }
        }];

        [[NSNotificationCenter defaultCenter] addObserverForName:GCKeyboardDidDisconnectNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            s_keyboard = nil;
        }];

        // Check if keyboard is already connected
        GCKeyboard *keyboard = [GCKeyboard coalescedKeyboard];
        if (keyboard) {
            s_keyboard = keyboard;

            keyboard.keyboardInput.keyChangedHandler = ^(GCKeyboardInput *keyboardInput, GCControllerButtonInput *button, GCKeyCode keyCode, BOOL pressed) {
                SDL_Scancode scancode = GCKeyCodeToSDLScancode(keyCode);
                if (scancode != SDL_SCANCODE_UNKNOWN) {
                    SDL_Event event;
                    SDL_zero(event);
                    event.type = pressed ? SDL_KEYDOWN : SDL_KEYUP;
                    event.key.keysym.scancode = scancode;
                    event.key.keysym.sym = SDL_GetKeyFromScancode(scancode);
                    event.key.keysym.mod = KMOD_NONE;
                    event.key.repeat = 0;
                    SDL_PushEvent(&event);
                }
            };
        }
    }
}

@implementation SDL_uikitmetalview

/* Returns a Metal-compatible layer. */
+ (Class)layerClass
{
    return [CAMetalLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
                        scale:(CGFloat)scale
{
    if ((self = [super initWithFrame:frame])) {
        self.tag = SDL_METALVIEW_TAG;
        self.layer.contentsScale = scale;
        [self updateDrawableSize];
    }

    // Setup keyboard input
    setupKeyboardInput();

    return self;
}

/* Set the size of the metal drawables when the view is resized. */
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateDrawableSize];
}

- (void)updateDrawableSize
{
    CGSize size = self.bounds.size;
    size.width *= self.layer.contentsScale;
    size.height *= self.layer.contentsScale;
    ((CAMetalLayer *)self.layer).drawableSize = size;
}

@end

SDL_MetalView
UIKit_Metal_CreateView(_THIS, SDL_Window * window)
{ @autoreleasepool {
    SDL_WindowData *data = (__bridge SDL_WindowData *)window->driverdata;
    CGFloat scale = 1.0;
    SDL_uikitmetalview *metalview;

    if (window->flags & SDL_WINDOW_ALLOW_HIGHDPI) {
        /* Set the scale to the natural scale factor of the screen - then
         * the backing dimensions of the Metal view will match the pixel
         * dimensions of the screen rather than the dimensions in points
         * yielding high resolution on retine displays.
         */
        if ([data.uiwindow.screen respondsToSelector:@selector(nativeScale)]) {
            scale = data.uiwindow.screen.nativeScale;
        } else {
            scale = data.uiwindow.screen.scale;
        }
    }

    metalview = [[SDL_uikitmetalview alloc] initWithFrame:data.uiwindow.bounds
                                                    scale:scale];
    [metalview setSDLWindow:window];

    return (void*)CFBridgingRetain(metalview);
}}

void
UIKit_Metal_DestroyView(_THIS, SDL_MetalView view)
{ @autoreleasepool {
    SDL_uikitmetalview *metalview = CFBridgingRelease(view);

    if ([metalview isKindOfClass:[SDL_uikitmetalview class]]) {
        [metalview setSDLWindow:NULL];
    }
}}

void *
UIKit_Metal_GetLayer(_THIS, SDL_MetalView view)
{ @autoreleasepool {
    SDL_uikitview *uiview = (__bridge SDL_uikitview *)view;
    return (__bridge void *)uiview.layer;
}}

void
UIKit_Metal_GetDrawableSize(_THIS, SDL_Window * window, int * w, int * h)
{
    @autoreleasepool {
        SDL_WindowData *data = (__bridge SDL_WindowData *)window->driverdata;
        SDL_uikitview *view = (SDL_uikitview*)data.uiwindow.rootViewController.view;
        SDL_uikitmetalview* metalview = [view viewWithTag:SDL_METALVIEW_TAG];
        if (metalview) {
            CAMetalLayer *layer = (CAMetalLayer*)metalview.layer;
            assert(layer != NULL);
            if (w) {
                *w = layer.drawableSize.width;
            }
            if (h) {
                *h = layer.drawableSize.height;
            }
        } else {
            SDL_GetWindowSize(window, w, h);
        }
    }
}

#endif /* SDL_VIDEO_DRIVER_UIKIT && (SDL_VIDEO_VULKAN || SDL_VIDEO_METAL) */
