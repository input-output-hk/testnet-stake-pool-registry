entry=
sig=
error() {
        echo "ERROR: $*" >&2
        test -f "${entry}" &&
                cat >&2 <<EOF
sig ${sig}
entry ${entry}:
$(cat ${entry})

EOF
        exit 1
}

show() {
        eval "printf \"%35s:  %s\n\" \"$1\" \"\$$1\""
}

banner() {
        cat <<EOF

--( $*

EOF
}

validateEnv() {
        eval "test \"\${$1}\" = \"$2\"" ||
                error "Unexpected environment:  $1 != '$2'"
}

validateGitHistory() {
        export PAGER=cat

        local delta="origin/master..HEAD"

        git log --oneline origin/master..HEAD
        local history_length=$(git log --oneline ${delta} | wc -l)
        test "${history_length}" = 1 ||
                error "Git history:  submissions must contain exactly a single commit (this one has ${history_length})."

        banner "Validating file structure.."

        local delta_files=$(git diff --compact-summary ${delta} --name-status | wc -l)
        test "${delta_files}" = 2 ||
                error "Git history:  submissions must affect exactly two files (entry & signature), this one has ${delta_files}"

        local delta_type_e=$(git diff --compact-summary ${delta} --name-status | sort | head -n1 | cut -f1)
        local delta_type_s=$(git diff --compact-summary ${delta} --name-status | sort | tail -n1 | cut -f1)
        local delta_path_e=$(git diff --compact-summary ${delta} --name-status | sort | head -n1 | cut -f2)
        local delta_path_s=$(git diff --compact-summary ${delta} --name-status | sort | tail -n1 | cut -f2)
        local delta_dir_e=$(dirname ${delta_path_e})
        local delta_dir_s=$(dirname ${delta_path_s})
        local delta_file_e=$(basename ${delta_path_e})
        local delta_file_s=$(basename ${delta_path_s})

        show delta_type_e
        show delta_type_s
        show delta_dir_e
        show delta_dir_s
        show delta_file_e
        show delta_file_s

        entry=${delta_path_e}
        sig=${delta_path_s}
        ticker=$(jq '.ticker' ${entry} | xargs echo)

        case "${delta_type_e}${delta_type_s}" in
                AA ) expected_commit_message="${ticker}:  new";;
                MM ) expected_commit_message="${ticker}:  update";;
                * ) error "Delta:  submissions must either add or modify entries/signatures";; esac

        test "${delta_dir_e}/${delta_dir_s}" = "registry/registry" ||
                error "Delta:  submissions must only affect files in 'registry' subdirectory"
}

validateCommitMessage() {
        test "${BUILDKITE_MESSAGE}" = "${expected_commit_message}" ||
                error "Message:  commit message must be:  ${expected_commit_message}"
       
}
