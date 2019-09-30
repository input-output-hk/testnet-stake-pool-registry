error() {
        echo "ERROR: $*" >&2
        exit 1
}

show() {
        eval "printf \"%35s:  %s\n\" \"$1\" \"\$$1\""
}

validate() {
        if ! eval "test \"\${$1}\" = \"$2\""
        then error "$1 != '$2'"
        fi
}
