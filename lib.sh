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

        case "${delta_type_e}${delta_type_s}" in
                AA | MM ) true;;
                * ) error "Delta:  submissions must either add or modify entries/signatures";; esac

        test "${delta_dir_e}/${delta_dir_s}" = "registry/registry" ||
                error "Delta:  submissions must only affect files in 'registry' subdirectory"

        case "${entry}" in
             registry/*.json ) true;;
             * ) error "Delta:  malformed registry entry path:  ${entry}";; esac
        case "${delta_path_s}" in
             registry/*.sig ) true;;
             * ) error "Delta:  malformed signature file path:  ${delta_path_s}";; esac

        test "$(echo -n ${delta_file_e} | wc -c)" = 69 ||
                error "Delta:  malformed registry entry path:  ${entry}"
        test "$(echo -n ${delta_file_s} | wc -c)" = 68 ||
                error "Delta:  malformed signature file path:  ${delta_path_s}"

        banner "Validating entry content.."

        test   "$(jq --slurp 'map(.ticker) | unique | length' registry/*)" \
             = "$(jq --slurp                         'length' registry/*)" ||
                error "Invariant:  Tickers not unique"

        id=$(jq '.id' ${entry} | xargs echo)
        test $(echo -n ${id} | wc -c) = 64 ||
                error "Invariant:  .id length:  not 64:  $(echo -n ${id} | wc -c)"
        test "${id}.json" = "${delta_file_e}" ||
                error "Invariant:  Id/entry file mismatch"
        test "${id}.sig"  = "${delta_file_s}" ||
                error "Invariant:  Id/sig file mismatch"

        case $(jq 'keys | length' ${entry}) in
                5 ) jq --exit-status 'keys == ["cost", "homepage", "id", "margin", "ticker"]' ${entry} ||
                    error "Invariant:  entry must contain 5 or 6 fields: cost, homepage, id, margin, ticker, and optionally pledge_address";;
                6 ) jq --exit-status 'keys == ["cost", "homepage", "id", "margin", "pledge_address", "ticker"]' ${entry} ||
                    error "Invariant:  entry must contain 5 or 6 fields: cost, homepage, id, margin, ticker, and optionally pledge_address";;
                * ) error "Invariant:  entry must contain 5 or 6 fields";; esac

        jq --exit-status '[(.cost|type=="number"), (.homepage|type=="string"), (.id|type=="string"), (.margin|type=="number"), (.ticker|type=="string")] | all' ${entry} >/dev/null ||
                error "Invariant:  some mandatory fields either missing or have wrong type"
        jq --exit-status '.pledge_address as $pledge | (if $pledge == null then true else ($pledge|type=="string") end)' ${entry} >/dev/null ||
                error "Invariant:  .pledge_address: not a string"
        
        ticker=$(jq '.ticker' ${entry} | xargs echo)
        ticker_length=$(echo -n ${ticker} | wc -c)
        case "${ticker_length}" in
                3 | 4 ) true;;
                * ) error "Invariant:  .ticker length:  not 3 or 4, but is ${ticker_length}";; esac
        case "${delta_type_e}${delta_type_s}" in
                AA ) expected_commit_message="${ticker}:  new";;
                MM ) expected_commit_message="${ticker}:  update";;
                * ) error "Delta:  submissions must either add or modify entries/signatures";; esac
        test "${BUILDKITE_MESSAGE}" = "${expected_commit_message}" ||
                error "Message:  commit message must be:  ${expected_commit_message}"
}
