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
#include "SDL_keyboard.h"
#include "SDL_scancode.h"

#import "SDL_uikitwindow.h"
#import "SDL_uikitmetalview.h"
#import <GameController/GameController.h>

static GCKeyboard *s_keyboard = nil;

static SDL_Scancode GCKeyCodeToSDLScancode(GCKeyCode keyCode) {
    // iOS 14.0+ GCKeyCode constants; use runtime comparisons
    if (@available(iOS 14.0, *)) {
        if (keyCode == GCKeyCodeSpacebar)           return SDL_SCANCODE_SPACE;
        if (keyCode == GCKeyCodeLeftArrow)          return SDL_SCANCODE_LEFT;
        if (keyCode == GCKeyCodeRightArrow)         return SDL_SCANCODE_RIGHT;
        if (keyCode == GCKeyCodeUpArrow)            return SDL_SCANCODE_UP;
        if (keyCode == GCKeyCodeDownArrow)          return SDL_SCANCODE_DOWN;
        if (keyCode == GCKeyCodeEscape)             return SDL_SCANCODE_ESCAPE;
        if (keyCode == GCKeyCodeReturnOrEnter)      return SDL_SCANCODE_RETURN;
        if (keyCode == GCKeyCodeTab)                return SDL_SCANCODE_TAB;

        if (keyCode == GCKeyCodeLeftShift)          return SDL_SCANCODE_LSHIFT;
        if (keyCode == GCKeyCodeRightShift)         return SDL_SCANCODE_RSHIFT;
        if (keyCode == GCKeyCodeLeftControl)        return SDL_SCANCODE_LCTRL;
        if (keyCode == GCKeyCodeRightControl)       return SDL_SCANCODE_RCTRL;
        if (keyCode == GCKeyCodeLeftOption)         return SDL_SCANCODE_LALT;
        if (keyCode == GCKeyCodeRightOption)        return SDL_SCANCODE_RALT;
        if (keyCode == GCKeyCodeLeftCommand)        return SDL_SCANCODE_LGUI;
        if (keyCode == GCKeyCodeRightCommand)       return SDL_SCANCODE_RGUI;

        // letters
        if (keyCode == GCKeyCodeA) return SDL_SCANCODE_A;
        if (keyCode == GCKeyCodeB) return SDL_SCANCODE_B;
        if (keyCode == GCKeyCodeC) return SDL_SCANCODE_C;
        if (keyCode == GCKeyCodeD) return SDL_SCANCODE_D;
        if (keyCode == GCKeyCodeE) return SDL_SCANCODE_E;
        if (keyCode == GCKeyCodeF) return SDL_SCANCODE_F;
        if (keyCode == GCKeyCodeG) return SDL_SCANCODE_G;
        if (keyCode == GCKeyCodeH) return SDL_SCANCODE_H;
        if (keyCode == GCKeyCodeI) return SDL_SCANCODE_I;
        if (keyCode == GCKeyCodeJ) return SDL_SCANCODE_J;
        if (keyCode == GCKeyCodeK) return SDL_SCANCODE_K;
        if (keyCode == GCKeyCodeL) return SDL_SCANCODE_L;
        if (keyCode == GCKeyCodeM) return SDL_SCANCODE_M;
        if (keyCode == GCKeyCodeN) return SDL_SCANCODE_N;
        if (keyCode == GCKeyCodeO) return SDL_SCANCODE_O;
        if (keyCode == GCKeyCodeP) return SDL_SCANCODE_P;
        if (keyCode == GCKeyCodeQ) return SDL_SCANCODE_Q;
        if (keyCode == GCKeyCodeR) return SDL_SCANCODE_R;
        if (keyCode == GCKeyCodeS) return SDL_SCANCODE_S;
        if (keyCode == GCKeyCodeT) return SDL_SCANCODE_T;
        if (keyCode == GCKeyCodeU) return SDL_SCANCODE_U;
        if (keyCode == GCKeyCodeV) return SDL_SCANCODE_V;
        if (keyCode == GCKeyCodeW) return SDL_SCANCODE_W;
        if (keyCode == GCKeyCodeX) return SDL_SCANCODE_X;
        if (keyCode == GCKeyCodeY) return SDL_SCANCODE_Y;
        if (keyCode == GCKeyCodeZ) return SDL_SCANCODE_Z;

        // numbers
        if (keyCode == GCKeyCode0) return SDL_SCANCODE_0;
        if (keyCode == GCKeyCode1) return SDL_SCANCODE_1;
        if (keyCode == GCKeyCode2) return SDL_SCANCODE_2;
        if (keyCode == GCKeyCode3) return SDL_SCANCODE_3;
        if (keyCode == GCKeyCode4) return SDL_SCANCODE_4;
        if (keyCode == GCKeyCode5) return SDL_SCANCODE_5;
        if (keyCode == GCKeyCode6) return SDL_SCANCODE_6;
        if (keyCode == GCKeyCode7) return SDL_SCANCODE_7;
        if (keyCode == GCKeyCode8) return SDL_SCANCODE_8;
        if (keyCode == GCKeyCode9) return SDL_SCANCODE_9;

        // function keys
        if (keyCode == GCKeyCodeF1)  return SDL_SCANCODE_F1;
        if (keyCode == GCKeyCodeF2)  return SDL_SCANCODE_F2;
        if (keyCode == GCKeyCodeF3)  return SDL_SCANCODE_F3;
        if (keyCode == GCKeyCodeF4)  return SDL_SCANCODE_F4;
        if (keyCode == GCKeyCodeF5)  return SDL_SCANCODE_F5;
        if (keyCode == GCKeyCodeF6)  return SDL_SCANCODE_F6;
        if (keyCode == GCKeyCodeF7)  return SDL_SCANCODE_F7;
        if (keyCode == GCKeyCodeF8)  return SDL_SCANCODE_F8;
        if (keyCode == GCKeyCodeF9)  return SDL_SCANCODE_F9;
        if (keyCode == GCKeyCodeF10) return SDL_SCANCODE_F10;
        if (keyCode == GCKeyCodeF11) return SDL_SCANCODE_F11;
        if (keyCode == GCKeyCodeF12) return SDL_SCANCODE_F12;
    }
    return SDL_SCANCODE_UNKNOWN;
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
