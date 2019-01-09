#!/usr/bin/env bash
#
# less written in bash.

clear_screen() {
    # Clear the screen.
    #
    # '\e[?7l':  Disable line wrapping.
    # '\e[?25l': Hide the cursor.
    # '\e[2J':   Clear the screen.
    # '\e[H':    Move the cursor to '0,0' (home).
    printf '\e[?7l\e[?25l\e[2J\e[H'
}

get_term_size() {
    # Get the terminal lines and columns.
    # This can't reliably be done in pure bash.
    # 'stty' is used as it's POSIX and always available.
    read -r LINES COLUMNS < <(stty size)
}

status_bar() {
    # Print the status bar on the bottom of the window.
    # We do this by using the '$LINES' variable which stores
    # the total number of lines in the window. We substract
    # this number by '2' to leave room for the status-bar.
    #
    # '\e[%sB':  Move the cursor N lines down.
    #            This has the added side-effect of moving
    #            the cursor to the bottom.
    # '\e[30m:'  Set text color to color '0'.
    # '\e[41m:'  Set text background color to color '1'.
    # '\e[K':    Clear to end of line.
    #            This has the added side-effect of coloring
    #            the entire line.
    # '\e[m':    Reset text colors.
    # '\e[H':    Move the cursor back to '0,0' (home).
    printf '\e[%sB\e[30m\e[41m\e[K%s\e[m\e[H' "$((LINES-2))" "$file_name"
}

read_file() {
    # Error handling for null file or non-existent file.
    if [[ ! -f "$1" ]]; then
        # '>&2':        Print the error string to 'stderr'.
        # '${1:-null}': If '$1' is empty, display 'null'.
        printf '%s\n' "${1:-null}: No such file." >&2
        exit 1
    fi

    # Store the file name for use later.
    file_name="$1"

    # Read the file into an array line by line.
    # bash 4+: Use 'readarray'/'mapfile'.
    while IFS= read -r line; do
        file_contents+=("$line")
    done < "$1"
}

print_file() {
    # Print the portions of the file that fit on the screen.
    #
    # '-2':              Leave some room for the status-bar.
    # '${scroll:=0}':  Set default value of '$scroll' to '0'.
    #
    # Print lines in file from '$scroll' to '$LINES + $scroll - 2'.
    # '$LINES' acts as the max number of lines we can print.
    # We subtract '2' from this var to leave room for the status-bar.
    for ((i=${scroll:=0};i<LINES+scroll-2;i++)); {
        # '\e[K': Clear line after line content.
        printf '%s\e[K\n' "${file_contents[i]}"
    }
}

get_key() {
    # Handle user input.
    case "$1" in
        # 'B' is what bash sees when you press 'Down Arrow'.
        # It's a portion of the escape sequence '\e[B' (cursor down).
        #
        # Make sure we don't scroll down past the end of the file and
        # increment scroll variable by 1 on scroll down.
        B|j) ((scroll < ${#file_contents[@]} - LINES + 2)) && ((scroll+=1)) ;;

        # 'A' is what bash sees when you press 'Up Arrow'.
        # It's a portion of the escape sequence '\e[A' (cursor up).
        #
        # Make sure we don't scroll up past the start of the file and
        # deincrement scroll variable by 1 on scroll up.
        A|k) ((scroll > 0)) && ((scroll-=1)) ;;

        # Exit the program on press of 'q'.
        q) exit ;;
    esac
}

main() {
    # Read the file.
    # Error handling is done in the function.
    read_file "$1"

    get_term_size
    clear_screen

    # Trap 'EXIT'.
    # This is required to reset the terminal to a useable
    # state on Ctrl+C, 'exit' etc.
    # '\e[?7h':  Re-enable line wrapping.
    # '\e[?25h': Re-enable the cursor.
    trap 'clear_screen; printf "\e[?7h\e[?25h"' EXIT

    # Trap 'SIGWINCH'
    # This signal allows us to react to a window size change.
    # Whenever the window is resized, we re-fetch the terminal size.
    trap 'get_term_size; clear_screen; print_file; status_bar' WINCH

    # Main loop.
    for ((;;)); {
        print_file
        status_bar

        # Wait for user to press a key.
        # Value is stored in '$REPLY'
        read -rsn 1 && get_key "$REPLY"
    }
}

main "$@"
