{-# LANGUAGE OverloadedStrings #-}

-- load in Tidal boot file

module VisualMacros where

import Sound.Tidal.Context hiding(rand4)

import Data.String (fromString)

randomRects = (# rect rand rand2 rand3 rand4)

rain = (# ellipse (fast 16 rand) (slow 4 $ saw) 0.1 0.1)
blackhole = (# ellipse 0.5 0.5 (scale 0.5 1 rand) (scale 0.5 1 rand2))

red::(Pattern Double, Pattern Double, Pattern Double)
red = ("1","0","0")
green = ("0","1","0")::(Pattern Double, Pattern Double, Pattern Double)
blue = ("0","0","1")::(Pattern Double, Pattern Double, Pattern Double)
black = ("0","0","0")::(Pattern Double, Pattern Double, Pattern Double)
white = ("1","1","1")::(Pattern Double, Pattern Double, Pattern Double)

rand2 = fast 2 rand
rand3 = fast 3 rand
rand4 = fast 4 rand
rand5 = fast 5 rand
rand6 = fast 6 rand
rand7 = fast 7 rand

-- Visuals
(rectX,rectX_p) = pF "rectX" Nothing
(rectY,rectY_p) = pF "rectY" Nothing
(rectW,rectW_p) = pF "rectW" Nothing
(rectH,rectH_p) = pF "rectH" Nothing

rect x y w h = rectX x # rectY y # rectW w # rectH h

(ellipseX,ellipseX_p) = pF "ellipseX" Nothing
(ellipseY,ellipseY_p) = pF "ellipseY" Nothing
(ellipseW,ellipseW_p) = pF "ellipseW" Nothing
(ellipseH,ellipseH_p) = pF "ellipseH" Nothing

ellipse x y w h = ellipseX x # ellipseY y # ellipseW w # ellipseH h

(arcX,arcX_p) = pF "arcX" Nothing
(arcY,arcY_p) = pF "arcY" Nothing
(arcW,arcW_p) = pF "arcW" Nothing
(arcH,arcH_p) = pF "arcH" Nothing
(arcStart,artStart_p) = pF "arcStart" Nothing
(arcStop,artStop_p) = pF "arcStop" Nothing

arc x y w h start stop = arcX x # arcY y # arcW w # arcH h # arcStart start # arcStop stop



setOrbitColorR orbit = fst $ pF ("colorR" ++ show orbit) Nothing
setOrbitColorG orbit = fst $ pF ("colorG" ++ show orbit) Nothing
setOrbitColorB orbit = fst $ pF ("colorB" ++ show orbit) Nothing
setOrbitColor orbit (r,g,b) = setOrbitColorR orbit r # setOrbitColorG orbit g # setOrbitColorB orbit b

brighten p (r,g,b) = (p+r, p+g, p+b)
darken p (r,g,b) = (r-p, g-p, b-p)

diagonalRects = (# rect (slow 4 $ saw) (slow 5 $ saw) (0.1) (0.1))

setOrbitRotate orbit = fst $ pF ("rotate" ++ show orbit) Nothing

setOrbitTranslateX orbit = fst $ pF ("translateX" ++ show orbit) Nothing
setOrbitTranslateY orbit = fst $ pF ("translateY" ++ show orbit) Nothing
setOrbitTranslate orbit x y= setOrbitTranslateX orbit x # setOrbitTranslateY orbit y

setOrbitSustain orbit = fst $ pF ("drawSustain"++show orbit) Nothing

(drawOrbit, drawOrbit_p) = pI "drawOrbit" Nothing



shuffleX orbit amt = (|+| setOrbitTranslateX orbit (fast 4 $ scale (-1*amt/2) (amt/2) rand))
tealish = (scale 0 0 sine, scale 0.5 1 rand, scale 0.5 1 rand2)
redish = (scale 0.65 1 rand, scale 0 0.25 rand, scale 0 0.25 rand2)

distributeRects x y w h = rect ((fromString $ (\x-> x++"*8") $ show $ fmap (\a-> a/x - (1/x/2)) [1..x])::Pattern Double) ((fromString $ show $ fmap (\a-> a/y - (1/y/2)) [1..y])::Pattern Double) w h

distributeEllipse x y w h = ellipse ((fromString $ (\x-> x++"*8") $ show $ fmap (\a-> a/x - (1/x/2)) [1..x])::Pattern Double) ((fromString $ show $ fmap (\a-> a/y - (1/y/2)) [1..y])::Pattern Double) w h


rect_1 t = rect ("0.5*8") 0.5 (slow t $ sine) (slow t $ sine)

ellipse_1 t = ellipse ("0.5*8") 0.5 (slow t $ sine) (slow t $ sine)

shuffleRectX amt= (|+| rectX (scale (-1*amt/2) (amt/2) rand))
