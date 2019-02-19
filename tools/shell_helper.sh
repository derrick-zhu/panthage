LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

function do_check_env() {

    if ! type "carthage" &>/dev/null; then
        echo "Detected that you have not installed carthage"
        echo "Please install carthage manually"
        echo "Using brew install carthage"
        exit 1
    fi

    if ! type "xcodeproj" &>/dev/null; then
        echo "Detected that you have not install xcodeproj"
        echo "Please install xcodeproj manually"
        echo "Using sudo gem install xcodeproj"
        exit 1
    fi
}

function do_check_workspace() {
    echo "Checking workspace...."
}

function showUsage() {
    echo "WHAT?! Need help!?"
}

# Takes a path argument and returns it as an absolute path.
# No-op if the path is already absolute.
function to_abs_path() {
    local target="$1"

    if [ "$target" == "." ]; then
        echo "$(pwd)"
    elif [ "$target" == ".." ]; then
        echo "$(dirname "$(pwd)")"
    else
        echo "$(
            cd "$(dirname "$1")"
            pwd
        )/$(basename "$1")"
    fi
}
