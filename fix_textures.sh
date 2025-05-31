#!/usr/bin/env bash

echo "Sleeping 20 seconds for map download..."
sleep 20

declare path_script="$(dirname "$(realpath "$0")")"
cd "$path_script"

declare path_bsp="$PWD/bsp"
declare path_data="$PWD/.data"
declare path_manual="$PWD/fix"
declare path_log="$PWD/log"
declare path_hash="$PWD/hash"
declare path_config="$PWD/cfg"
declare vpkeditcli="$PWD/vpkeditcli"
declare steampath="$PWD/../cstrike/download"

mkdir -p "$path_bsp"
mkdir -p "$path_data"
mkdir -p "$path_manual"
mkdir -p "$path_log"
mkdir -p "$path_hash"
mkdir -p "$path_config"

color_msg() {
    local color="$1"
    local text="$2"
    local style="${3:-normal}"

    local style_code=""
    case "$style" in
        bold)      style_code="\033[1m" ;;
        underline) style_code="\033[4m" ;;
        *)         style_code="" ;;
    esac

    local color_code=""
    case "$color" in
        red)          color_code="\033[31m" ;;
        green)        color_code="\033[32m" ;;
        yellow)       color_code="\033[33m" ;;
        blue)         color_code="\033[34m" ;;
        magenta)      color_code="\033[35m" ;;
        cyan)         color_code="\033[36m" ;;
        white)        color_code="\033[37m" ;;
        black)        color_code="\033[30m" ;;
        bred)         color_code="\033[91m" ;;
        bgreen)       color_code="\033[92m" ;;
        byellow)      color_code="\033[93m" ;;
        bblue)        color_code="\033[94m" ;;
        bmagenta)     color_code="\033[95m" ;;
        bcyan)        color_code="\033[96m" ;;
        bwhite)       color_code="\033[97m" ;;
        "red bg")     color_code="\033[41m" ;;
        "green bg")   color_code="\033[42m" ;;
        "yellow bg")  color_code="\033[43m" ;;
        "blue bg")    color_code="\033[44m" ;;
        *)            color_code="" ;;
    esac

    printf "$style_code$color_code$text\033[0m"
}
checkdeps() {
    local missing=0

    for app in "${dependencies[@]}"; do
        if ! command -v "$app" &>/dev/null; then
            color_msg "red" "=> dependency '$app' is required, but not installed.\n" "bold"
            missing=1
        fi
    done
    if [ "$missing" -eq 1 ]; then
        echo "Please check your distribution's documentation for further instructions."
        exit 1
    fi
}
checkvpk() {
    local repo_url="https://api.github.com/repos/craftablescience/VPKEdit/releases/latest"
    local vpkedit_file="vpkedit"
    local timestamp_file=".vpkedit"
    local download_needed=1
    local current_time=$(date +%s)

    if [ -f "$vpkedit_file" ] && [ -f "$timestamp_file" ]; then
        local last_modified=$(cat "$timestamp_file" 2>/dev/null)
        if [ -n "$last_modified" ]; then
            local time_diff=$((current_time - last_modified))
            if [ "$time_diff" -lt 604800 ]; then
                download_needed=0
                return 0
            fi
        fi
    fi

    if [ "$download_needed" -eq 1 ]; then
        color_msg "white" "Updating 'vpkedit' to latest release\n(https://github.com/craftablescience/VPKEdit)..."
        printf "\n"
        local latest_url=$(curl -s $repo_url \
            | grep "browser_download_url.*.zip" \
            | grep "Linux-Binaries" \
            | cut -d '"' -f 4)
        if [ -z "$latest_url" ]; then
            color_msg "red" "Error: Failed to fetch latest VPKEdit release URL\n" "bold"
            exit 1
        fi
        local filename=$(basename "$latest_url")
        curl -s -L -o "$filename" "$latest_url" || { color_msg "red" "Error: Failed to download VPKEdit\n" "bold"; exit 1; }

        if ! unzip -t "$filename" &>>test.log; then
            color_msg "red" "Error: Downloaded VPKEdit archive is corrupt\n" "bold"
            exit 1
        fi

        unzip -o "$filename" &>/dev/null || { color_msg "red" "Error: Failed to unzip VPKEdit\n" "bold"; exit 1; }
        rm -f "$filename"

        echo "$current_time" > "$timestamp_file"
    fi

    if [ ! -f "$vpkeditcli" ] || [ ! -x "$vpkeditcli" ]; then
        color_msg "red" "Error: '$vpkeditcli' not found or not executable. Please check the path and permissions.\n" "bold"
        exit 1
    fi
}
hash_check() {
    local -n hashes=$1
    local filename="$2"

    [[ -z "$filename" || ! -f "$filename" ]] && return 1

    local hash=$(hash_create "$filename")

    if [[ ${hashes["$hash"]} -eq 1 ]]; then
        echo "$hash"
        return 0
    fi

    return 1
}
hash_create() {
    stat --format="%d %s %Y %Z %n" "$1" | sha1sum | awk '{print $1}'
}
process_bsp() {
    local -i cursor_index=0
    local -i max_jobs=$(( $(nproc) / 2 ))
    local -a cursors=("/" "-" "\\" "|")
    local -a map_hash
    local -A hash_seen
    local hash_parallel=""

    export vpkeditcli="$vpkeditcli"
    export path_data="$path_data"
    export steampath="$steampath"
    export path_log="$path_log"

    local fifo=$(mktemp -u)
    mkfifo "$fifo"
    trap 'rm -f "$fifo"' EXIT

    path_hash="$path_hash/hash.dat"


    if [ -f "$path_hash" ]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && map_hash+=("$line") && hash_seen["$line"]=1
        done < "$path_hash" 2>/dev/null
    fi

    [ "$(ulimit -n)" -lt 8192 ] && ulimit -n 8192

    [ "$max_jobs" -lt 4 ] && max_jobs=4
    [ "$max_jobs" -gt 12 ] && max_jobs=12

    color_msg "blue" "Initializing..." "bold"

    hash_parallel=$(declare -p hash_seen)

    export hash_parallel
    export -f hash_check
    export -f hash_create

    parallel --tmpdir "$path_data/tmp" --jobs $max_jobs --line-buffer --keep-order --quote bash -c '
        bsp="$1"
        bsp_name=$(basename "$bsp")

        eval "$hash_parallel"

        if matched_hash=$(hash_check hash_seen "$bsp"); then
            echo "SKIPPED: $bsp"
        elif "$vpkeditcli" --no-progress --output "$path_data" --extract / "$bsp" 2> "$path_log/${bsp_name}.log"; then
            echo "Extraction succeeded for $bsp_name" >&2
            materials="$path_data/${bsp_name%.*}/materials"
            models="$path_data/${bsp_name%.*}/models"
            sound="$path_data/${bsp_name%.*}/sound"
            [ -d "$materials" ] && rsync -aAHX "$materials" "$steampath"
            [ -d "$models" ] && rsync -aAHX "$models" "$steampath"
            [ -d "$sound" ] && rsync -aAHX "$sound" "$steampath"
            echo "Successfully synchronized extracted data for $bsp_name" >&2
            echo "Completed processing for $bsp_name" >&2
            rm -f "$path_log/${bsp_name}.log"
            echo "SUCCESS: $bsp"
        else
            echo "FAILED: $bsp"
        fi
    ' bash ::: "${bsp_files[@]}" > "$fifo" 2> "$path_log/process.log" &

    local parallel_pid=$!

    map_hash=()
    while IFS= read -r result || [ -n "$result" ]; do
        state=0
        if [[ "$result" =~ ^SUCCESS:\ (.+)$ ]]; then
            state=0
        elif [[ "$result" =~ ^SKIPPED:\ (.+)$ ]]; then
            state=1
        elif [[ "$result" =~ ^FAILED:\ (.+)$ ]]; then
            state=2
        else
            continue
        fi

        bsp="${BASH_REMATCH[1]}"
        local cursor="${cursors[cursor_index]}"
        local bsp_name=$(basename "$bsp")
        ((cursor_index = (cursor_index + 1) % 4))
        ((bsp_processed++))

        if [ "$state" -eq 0 ]; then
            color_msg "blue" "\r\033[K [$cursor] Processing \033[36m${bsp_name%.*}..." "bold"
            map_hash+=("$(hash_create "$bsp")")
        elif [ "$state" -eq 1 ]; then
            color_msg "blue" "\r\033[K [$cursor] Processing \033[35mSkipping ${bsp_name%.*} (already processed)..." "bold"
        elif [ "$state" -eq 2 ]; then
            color_msg "yellow" "Warning: Failed to extract '$bsp_name', skipping. Check error log at $path_log/${bsp_name}.log"
            sleep 1
        fi
    done < "$fifo"

    wait "$parallel_pid"
    printf "\n"

    rm -rf "$fifo"

    for hash in "${map_hash[@]}"; do
        [[ -z "${hash_seen[$hash]}" ]] && echo "$hash" >> "$path_hash"
    done
}

checkdeps
checkvpk

# Preparation
[ -z "$TERM" ] && export TERM="xterm"
mkdir -p "$path_hash"
mkdir -p "$steampath/maps"
rm -rf "$path_data"/* || { color_msg "red" "Error: Failed to prepare $path_data\n" "bold"; exit 1; }
rm -rf "$path_log"/* || { color_msg "red" "Error: Failed to prepare $path_log\n" "bold"; exit 1; }
mkdir -p "$path_data/tmp"
path_bsp="$steampath/maps"

# Process maps
mapfile -t bsp_files < <(find -L "$path_bsp" -maxdepth 1 -type f -iname "*.bsp" | sort)
process_bsp

# Cleanup
color_msg "white" "\nCleaning up...\n\n"
rm -rf "$path_data"/* || { color_msg "red" "Error: Failed to cleanup $path_data\n" "bold"; exit 1; }
