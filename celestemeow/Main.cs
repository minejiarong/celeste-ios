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
                        // Some Xamarin bindings expose code as nint
                        var sc = GCKeyCodeToSDLScancode((nint)code);
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

        static SDL.SDL_Scancode GCKeyCodeToSDLScancode(nint code)
        {
            if (!UIDevice.CurrentDevice.CheckSystemVersion(14, 0))
                return SDL.SDL_Scancode.SDL_SCANCODE_UNKNOWN;

            // arrows and controls
            if (code == (nint)GCKeyCode.LeftArrow)          return SDL.SDL_Scancode.SDL_SCANCODE_LEFT;
            if (code == (nint)GCKeyCode.RightArrow)         return SDL.SDL_Scancode.SDL_SCANCODE_RIGHT;
            if (code == (nint)GCKeyCode.UpArrow)            return SDL.SDL_Scancode.SDL_SCANCODE_UP;
            if (code == (nint)GCKeyCode.DownArrow)          return SDL.SDL_Scancode.SDL_SCANCODE_DOWN;
            if (code == (nint)GCKeyCode.Escape)             return SDL.SDL_Scancode.SDL_SCANCODE_ESCAPE;
            if (code == (nint)GCKeyCode.ReturnOrEnter)      return SDL.SDL_Scancode.SDL_SCANCODE_RETURN;
            if (code == (nint)GCKeyCode.Tab)                return SDL.SDL_Scancode.SDL_SCANCODE_TAB;
            if (code == (nint)GCKeyCode.Spacebar)           return SDL.SDL_Scancode.SDL_SCANCODE_SPACE;
            if (code == (nint)GCKeyCode.LeftShift)          return SDL.SDL_Scancode.SDL_SCANCODE_LSHIFT;
            if (code == (nint)GCKeyCode.RightShift)         return SDL.SDL_Scancode.SDL_SCANCODE_RSHIFT;
            if (code == (nint)GCKeyCode.LeftControl)        return SDL.SDL_Scancode.SDL_SCANCODE_LCTRL;
            if (code == (nint)GCKeyCode.RightControl)       return SDL.SDL_Scancode.SDL_SCANCODE_RCTRL;
			if (code == (nint)GCKeyCode.LeftAlt)            return SDL.SDL_Scancode.SDL_SCANCODE_LALT;
			if (code == (nint)GCKeyCode.RightAlt)           return SDL.SDL_Scancode.SDL_SCANCODE_RALT;
            if (code == (nint)GCKeyCode.LeftCommand)        return SDL.SDL_Scancode.SDL_SCANCODE_LGUI;
            if (code == (nint)GCKeyCode.RightCommand)       return SDL.SDL_Scancode.SDL_SCANCODE_RGUI;

			// letters (HID usage 0x04-0x1D => A-Z)
			if (code >= (nint)0x04 && code <= (nint)0x1D)
				return (SDL.SDL_Scancode)((int)SDL.SDL_Scancode.SDL_SCANCODE_A + (int)(code - (nint)0x04));

			// number row (HID usage 0x1E-0x27 => 1..0)
			if (code >= (nint)0x1E && code <= (nint)0x27)
				return (SDL.SDL_Scancode)((int)SDL.SDL_Scancode.SDL_SCANCODE_1 + (int)(code - (nint)0x1E));

            // function keys
            if (code == (nint)GCKeyCode.F1)  return SDL.SDL_Scancode.SDL_SCANCODE_F1;
            if (code == (nint)GCKeyCode.F2)  return SDL.SDL_Scancode.SDL_SCANCODE_F2;
            if (code == (nint)GCKeyCode.F3)  return SDL.SDL_Scancode.SDL_SCANCODE_F3;
            if (code == (nint)GCKeyCode.F4)  return SDL.SDL_Scancode.SDL_SCANCODE_F4;
            if (code == (nint)GCKeyCode.F5)  return SDL.SDL_Scancode.SDL_SCANCODE_F5;
            if (code == (nint)GCKeyCode.F6)  return SDL.SDL_Scancode.SDL_SCANCODE_F6;
            if (code == (nint)GCKeyCode.F7)  return SDL.SDL_Scancode.SDL_SCANCODE_F7;
            if (code == (nint)GCKeyCode.F8)  return SDL.SDL_Scancode.SDL_SCANCODE_F8;
            if (code == (nint)GCKeyCode.F9)  return SDL.SDL_Scancode.SDL_SCANCODE_F9;
            if (code == (nint)GCKeyCode.F10) return SDL.SDL_Scancode.SDL_SCANCODE_F10;
            if (code == (nint)GCKeyCode.F11) return SDL.SDL_Scancode.SDL_SCANCODE_F11;
            if (code == (nint)GCKeyCode.F12) return SDL.SDL_Scancode.SDL_SCANCODE_F12;

            return SDL.SDL_Scancode.SDL_SCANCODE_UNKNOWN;
        }
	#endif
	}
}
