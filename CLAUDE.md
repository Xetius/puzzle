# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Android puzzle application built with Flutter. Primary target devices are Google Pixel 9a and Pixel 10.

## Build & Run Commands

- `flutter run` — run the app (debug mode)
- `flutter run --release` — run in release mode
- `flutter build apk` — build release APK
- `flutter build appbundle` — build Android App Bundle for Play Store
- `flutter test` — run all tests
- `flutter test test/path_to_test.dart` — run a single test file
- `flutter analyze` — run static analysis (linter)
- `flutter pub get` — install dependencies

## Architecture

- **Target platform:** Android only (Pixel 9a, Pixel 10)
- **Framework:** Flutter (Dart)
- **Min SDK:** Target API levels appropriate for Pixel 9a/10 (Android 14+)

## How the game works

These are the main screens:
- Title screen.
- Level select screen
- Play level screen

### Title screen

This consists of a play game button currently.

This page will display their current highest level

pressing the play game button will take the user to their latest level select screen.

More functionality will be added later


### Level select screen

The level select screen consists of a grid of cells, similar to the main game.

This will be a 5 x 6 grid again. Each cell has a graphic with the level number on it.

Completing a level reveals the section of an image underneath the level numbers.

Completing all 30 levels will reveal the whole image, and the user can then select a 'next level' button, which will take them to a further 30 levels, revealing a different image.

The game will remember the last level played and when they select play from the title screen it will take them to their current page.

Page one of the level select will be levels 1 to 30
Page two will be levels 31-60

levels need to be completed sequentially

at the start, the user will only be able to select level 1
the screen will display locks on levels 2 - 30

when the user completes level 1 the lock will be removed from the next level (level 2)

### Play level screen

This is where you actually play the game.

Every level is an image which is displayed in a grid. The grid consists of a number of cells.  If the grid is 5 x 6 then there are 30 cells. These are arranged with 6 rows and 5 columns. The size of the grid is dependent on the difficulty of the level

You can think of this as follows:

|----|----|----|----|----|
| 01 | 02 | 03 | 04 | 05 |
|----|----|----|----|----|
| 06 | 07 | 08 | 09 | 10 |
|----|----|----|----|----|
| 11 | 12 | 13 | 14 | 15 |
|----|----|----|----|----|
| 16 | 17 | 18 | 19 | 20 |
|----|----|----|----|----|
| 21 | 22 | 23 | 24 | 25 |
|----|----|----|----|----|
| 26 | 27 | 28 | 29 | 30 |
|----|----|----|----|----|

Before the level is shown to the user, the cells are randomised. Randomising the cell means taking the section of the image displayed in that cell and displaying it in a different cell.  This will make the image all mixed up.

The aim of the game is to swap cells to rearrange them back to there initial order which will mean the picture will then be no longer mixed up. 

To "unscramble" the image the user will touch a cell and drag it to a different cell. This will swap those two cells.

When the user puts 2 correct cells next to each other, those cells become joined together. The two joined pieces them move as one piece.

The user builds bigger and bigger pieces until the whole image is correct.

The user should be able to reposition and move the joined pieces as a single piece. If you have 3 pieces connected, when you drop the piece, and other pieces that it covers should move.  If there are a number of larger pieces and the user moves the pieces as one, and the overlayed piece cannot be moved into the remaining spaces then it should put the original piece back in its original position.


### Game difficulty

The game will have 4 difficulty levels

- easy: 4 x 5 grid
- medium: 5 x 6 grid
- hard: 6 x 7 grid
- expert: 7 x 8 grid

The difficulty of each level will be controlled by a single file, which will have the image and the difficulty level.  Use the most relevant file type for storing this information.  It should be easily editable to change it and add more levels
as the developer I should be able to add any configuration of columns x rows as the game may need some tuning to get it to work properly, and the game should automatically calculate the cells based on the information in this file.

