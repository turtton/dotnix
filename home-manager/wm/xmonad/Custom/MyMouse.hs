module Custom.MyMouse where

import qualified Data.Map                      as M
import           XMonad
import qualified XMonad.Actions.FlexibleResize as Flex
import qualified XMonad.StackSet               as W

myMouseBindings :: XConfig l -> M.Map (KeyMask, Button) (Window -> X ())
myMouseBindings XConfig {XMonad.modMask = modm} =
  M.fromList
    [ ( (modm, button1),
        \w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster
      ),
      ((modm, button2), \w -> focus w >> windows W.shiftMaster),
      ( (modm .|. shiftMask, button3),
        \w -> focus w >> Flex.mouseResizeWindow w >> windows W.shiftMaster
      ),
      ((modm, button3), const (spawn "~/.config/jgmenu/randomiser.sh; jgmenu_run"))
    ]
