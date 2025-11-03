using System;
using System.Reflection;
using SDL2;
#if __IOS__ || __TVOS__
using Foundation;
using UIKit;
using GameController;
#endif

namespace celestemeow
{
    public class Application
    {

        static void Main(string[] args)
#if __IOS__ || __TVOS__
        {
            /*
            Console.WriteLine("adding silly exception listener");
            AppDomain.CurrentDomain.FirstChanceException += (sender, eventArgs) => {
                Console.WriteLine("EXCEPTION: " + eventArgs.Exception.ToString());
            };
            */

            Console.WriteLine("running from ios - enabling workarounds!");
            // Enable high DPI "Retina" support. Trust us, you'll want this.
            Environment.SetEnvironmentVariable("FNA_GRAPHICS_ENABLE_HIGHDPI", "1");

            // Keep mouse and touch input separate.
            SDL2.SDL.SDL_SetHint(SDL.SDL_HINT_MOUSE_TOUCH_EVENTS, "0");
            SDL2.SDL.SDL_SetHint(SDL.SDL_HINT_TOUCH_MOUSE_EVENTS, "0");

            Console.WriteLine("setting SDL hint FNA3D_FORCE_DRIVER to Metal");
            SDL2.SDL.SDL_SetHint("FNA3D_FORCE_DRIVER", "Metal");

            realArgs = args;
            // Bridge external keyboard events from GameController to SDL before starting the app loop
            SetupKeyboardBridge();
            SDL2.SDL.SDL_UIKitRunApp(0, IntPtr.Zero, FakeMain);
        }

        static string[] realArgs;

        [ObjCRuntime.MonoPInvokeCallback(typeof(SDL2.SDL.SDL_main_func))]
        static int FakeMain(int argc, IntPtr argv)
        {
            RealMain(realArgs);
            return 0;
        }

        static void RealMain(string[] args)
#endif
        {
            Console.WriteLine("hello hi :3");

            // thanks to pixel#0772 on the celeste discord server for this <3
            //Type MeWhenIStealCodeFromAScreenshotInTheCelesteDiscordServer = typeof(UIWindow).GetType();
            MethodInfo method = typeof(Celeste.Celeste).GetMethod("Main", BindingFlags.NonPublic | BindingFlags.Static);
            method.Invoke(null, new object[] { args });
        }
    }

#if __IOS__ || __TVOS__
    // Setup a non-invasive keyboard bridge using GameController (iOS 14+)
    static void SetupKeyboardBridge()
    {
        try
        {
            if (!UIDevice.CurrentDevice.CheckSystemVersion(14, 0))
                return;

            void Attach(GCKeyboard kb)
            {
                if (kb == null || kb.KeyboardInput == null) return;
                kb.KeyboardInput.KeyChangedHandler = (input, button, code, pressed) =>
                {
                    var sc = GCKeyCodeToSDLScancode(code);
                    if (sc == SDL.SDL_Scancode.SDL_SCANCODE_UNKNOWN) return;

                    SDL.SDL_Event ev = new SDL.SDL_Event();
                    ev.type = pressed ? SDL.SDL_EventType.SDL_KEYDOWN : SDL.SDL_EventType.SDL_KEYUP;
                    ev.key.keysym.scancode = sc;
                    ev.key.keysym.sym = SDL.SDL_GetKeyFromScancode(sc);
                    ev.key.keysym.mod = SDL.SDL_Keymod.KMOD_NONE;
                    ev.key.repeat = 0;
                    SDL.SDL_PushEvent(ref ev);
                };
            }

            NSNotificationCenter.DefaultCenter.AddObserver(GCKeyboard.DidConnectNotification, _ =>
            {
                Attach(GCKeyboard.CoalescedKeyboard);
            });
            NSNotificationCenter.DefaultCenter.AddObserver(GCKeyboard.DidDisconnectNotification, _ =>
            {
                // optional cleanup
            });

            Attach(GCKeyboard.CoalescedKeyboard);
        }
        catch (Exception)
        {
            // Fail-safe: don't crash if GCKeyboard API not available at runtime
        }
    }

    static SDL.SDL_Scancode GCKeyCodeToSDLScancode(GCKeyCode code)
    {
        if (!UIDevice.CurrentDevice.CheckSystemVersion(14, 0))
            return SDL.SDL_Scancode.SDL_SCANCODE_UNKNOWN;

        // arrows and controls
        if (code == GCKeyCode.LeftArrow)          return SDL.SDL_Scancode.SDL_SCANCODE_LEFT;
        if (code == GCKeyCode.RightArrow)         return SDL.SDL_Scancode.SDL_SCANCODE_RIGHT;
        if (code == GCKeyCode.UpArrow)            return SDL.SDL_Scancode.SDL_SCANCODE_UP;
        if (code == GCKeyCode.DownArrow)          return SDL.SDL_Scancode.SDL_SCANCODE_DOWN;
        if (code == GCKeyCode.Escape)             return SDL.SDL_Scancode.SDL_SCANCODE_ESCAPE;
        if (code == GCKeyCode.ReturnOrEnter)      return SDL.SDL_Scancode.SDL_SCANCODE_RETURN;
        if (code == GCKeyCode.Tab)                return SDL.SDL_Scancode.SDL_SCANCODE_TAB;
        if (code == GCKeyCode.Spacebar)           return SDL.SDL_Scancode.SDL_SCANCODE_SPACE;
        if (code == GCKeyCode.LeftShift)          return SDL.SDL_Scancode.SDL_SCANCODE_LSHIFT;
        if (code == GCKeyCode.RightShift)         return SDL.SDL_Scancode.SDL_SCANCODE_RSHIFT;
        if (code == GCKeyCode.LeftControl)        return SDL.SDL_Scancode.SDL_SCANCODE_LCTRL;
        if (code == GCKeyCode.RightControl)       return SDL.SDL_Scancode.SDL_SCANCODE_RCTRL;
        if (code == GCKeyCode.LeftOption)         return SDL.SDL_Scancode.SDL_SCANCODE_LALT;
        if (code == GCKeyCode.RightOption)        return SDL.SDL_Scancode.SDL_SCANCODE_RALT;
        if (code == GCKeyCode.LeftCommand)        return SDL.SDL_Scancode.SDL_SCANCODE_LGUI;
        if (code == GCKeyCode.RightCommand)       return SDL.SDL_Scancode.SDL_SCANCODE_RGUI;

        // letters
        if (code == GCKeyCode.A) return SDL.SDL_Scancode.SDL_SCANCODE_A;
        if (code == GCKeyCode.B) return SDL.SDL_Scancode.SDL_SCANCODE_B;
        if (code == GCKeyCode.C) return SDL.SDL_Scancode.SDL_SCANCODE_C;
        if (code == GCKeyCode.D) return SDL.SDL_Scancode.SDL_SCANCODE_D;
        if (code == GCKeyCode.E) return SDL.SDL_Scancode.SDL_SCANCODE_E;
        if (code == GCKeyCode.F) return SDL.SDL_Scancode.SDL_SCANCODE_F;
        if (code == GCKeyCode.G) return SDL.SDL_Scancode.SDL_SCANCODE_G;
        if (code == GCKeyCode.H) return SDL.SDL_Scancode.SDL_SCANCODE_H;
        if (code == GCKeyCode.I) return SDL.SDL_Scancode.SDL_SCANCODE_I;
        if (code == GCKeyCode.J) return SDL.SDL_Scancode.SDL_SCANCODE_J;
        if (code == GCKeyCode.K) return SDL.SDL_Scancode.SDL_SCANCODE_K;
        if (code == GCKeyCode.L) return SDL.SDL_Scancode.SDL_SCANCODE_L;
        if (code == GCKeyCode.M) return SDL.SDL_Scancode.SDL_SCANCODE_M;
        if (code == GCKeyCode.N) return SDL.SDL_Scancode.SDL_SCANCODE_N;
        if (code == GCKeyCode.O) return SDL.SDL_Scancode.SDL_SCANCODE_O;
        if (code == GCKeyCode.P) return SDL.SDL_Scancode.SDL_SCANCODE_P;
        if (code == GCKeyCode.Q) return SDL.SDL_Scancode.SDL_SCANCODE_Q;
        if (code == GCKeyCode.R) return SDL.SDL_Scancode.SDL_SCANCODE_R;
        if (code == GCKeyCode.S) return SDL.SDL_Scancode.SDL_SCANCODE_S;
        if (code == GCKeyCode.T) return SDL.SDL_Scancode.SDL_SCANCODE_T;
        if (code == GCKeyCode.U) return SDL.SDL_Scancode.SDL_SCANCODE_U;
        if (code == GCKeyCode.V) return SDL.SDL_Scancode.SDL_SCANCODE_V;
        if (code == GCKeyCode.W) return SDL.SDL_Scancode.SDL_SCANCODE_W;
        if (code == GCKeyCode.X) return SDL.SDL_Scancode.SDL_SCANCODE_X;
        if (code == GCKeyCode.Y) return SDL.SDL_Scancode.SDL_SCANCODE_Y;
        if (code == GCKeyCode.Z) return SDL.SDL_Scancode.SDL_SCANCODE_Z;

        // numbers (binding names may be _0.._9)
        if (code == GCKeyCode._0) return SDL.SDL_Scancode.SDL_SCANCODE_0;
        if (code == GCKeyCode._1) return SDL.SDL_Scancode.SDL_SCANCODE_1;
        if (code == GCKeyCode._2) return SDL.SDL_Scancode.SDL_SCANCODE_2;
        if (code == GCKeyCode._3) return SDL.SDL_Scancode.SDL_SCANCODE_3;
        if (code == GCKeyCode._4) return SDL.SDL_Scancode.SDL_SCANCODE_4;
        if (code == GCKeyCode._5) return SDL.SDL_Scancode.SDL_SCANCODE_5;
        if (code == GCKeyCode._6) return SDL.SDL_Scancode.SDL_SCANCODE_6;
        if (code == GCKeyCode._7) return SDL.SDL_Scancode.SDL_SCANCODE_7;
        if (code == GCKeyCode._8) return SDL.SDL_Scancode.SDL_SCANCODE_8;
        if (code == GCKeyCode._9) return SDL.SDL_Scancode.SDL_SCANCODE_9;

        // function keys
        if (code == GCKeyCode.F1)  return SDL.SDL_Scancode.SDL_SCANCODE_F1;
        if (code == GCKeyCode.F2)  return SDL.SDL_Scancode.SDL_SCANCODE_F2;
        if (code == GCKeyCode.F3)  return SDL.SDL_Scancode.SDL_SCANCODE_F3;
        if (code == GCKeyCode.F4)  return SDL.SDL_Scancode.SDL_SCANCODE_F4;
        if (code == GCKeyCode.F5)  return SDL.SDL_Scancode.SDL_SCANCODE_F5;
        if (code == GCKeyCode.F6)  return SDL.SDL_Scancode.SDL_SCANCODE_F6;
        if (code == GCKeyCode.F7)  return SDL.SDL_Scancode.SDL_SCANCODE_F7;
        if (code == GCKeyCode.F8)  return SDL.SDL_Scancode.SDL_SCANCODE_F8;
        if (code == GCKeyCode.F9)  return SDL.SDL_Scancode.SDL_SCANCODE_F9;
        if (code == GCKeyCode.F10) return SDL.SDL_Scancode.SDL_SCANCODE_F10;
        if (code == GCKeyCode.F11) return SDL.SDL_Scancode.SDL_SCANCODE_F11;
        if (code == GCKeyCode.F12) return SDL.SDL_Scancode.SDL_SCANCODE_F12;

        return SDL.SDL_Scancode.SDL_SCANCODE_UNKNOWN;
    }
#endif
}
