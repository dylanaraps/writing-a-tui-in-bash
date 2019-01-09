# Writing a TUI in BASH [WIP]

Through my travels I've discovered it's possible to write a fully functional Terminal User Interface in BASH. The object of this guide is to document and teach the concepts in a simple way. To my knowledge they aren't documented anywhere so this is essential.

The benefit of using BASH is the lack of needed dependencies. If the system has BASH available, the program will run. Now there are cases against using BASH and they're most of the time valid. However, there are cases where BASH is the only thing available and that's where this guide comes in.

This guide covers BASH `3.2+` which covers pretty much every OS you'll come across. One of the major reasons for covering this version is macOS which will be forever stuck on BASH `3`.

To date I have written 3 different programs using this method. The best example of a TUI that covers most vital features is [**fff**](https://github.com/dylanaraps/fff) which is a Terminal File manager. Another good example is [**pxltrm**](https://github.com/dylanaraps/pxltrm) which is a pixel art editor in the terminal.

## Table of Contents

<!-- vim-markdown-toc GFM -->

* [Getting Started - The main loop](#getting-started---the-main-loop)
* [Clearing the screen](#clearing-the-screen)

<!-- vim-markdown-toc -->

## Getting Started - The main loop

First off we need a main function and a main loop. The loop is infinite and in this example waits for the user to press a key before it loops. It's pretty useless at this stage as its the foundation for what's to come.

```sh
#!/usr/bin/env bash
#
# program

main() {
    # Main loop.
    for ((;;)); {
        # Wait for user to press a key.
        # Value is stored in '$REPLY'
        read -rsn 1
    }
}

main "$@"
```


## Clearing the screen

The next step is to clear the screen, hide the cursor and disable line-wrapping. There are cases where the cursor should be shown throughout or line-wrapping should be enabled but for the purposes of this tutorial we'll disable them.


```sh
#!/usr/bin/env bash
#
# program

clear_screen() {
    # Clear the screen.
    # '\e[?7l':  Disable line wrapping.
    # '\e[?25l': Hide the cursor.
    # '\e[2J':   Clear the screen.
    # '\e[H':    Move the cursor to '0,0' (home).
    printf '\e[?7l\e[?25l\e[2J\e[H'
}

main() {
    clear_screen

    # Trap 'EXIT'.
    # This is required to reset the terminal to a useable
    # state on Ctrl+C, exit etc.
    # '\e[?7h':  Re-enable line wrapping.
    # '\e[?25h': Re-enable the cursor.
    trap 'printf "\e[?7h\e[?25h"' EXIT

    # Main loop.
    for ((;;)); {
        # Wait for user to press a key.
        # Value is stored in '$REPLY'
        read -rsn 1
    }
}

main "$@"
```
