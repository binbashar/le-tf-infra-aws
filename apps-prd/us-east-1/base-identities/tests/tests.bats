setup_file(){
    VARIABLES_FILE="variables.tfvars"
    [[ -e "./tests/$VARIABLES_FILE" ]] && cp "./tests/$VARIABLES_FILE" "$VARIABLES_FILE"
}

teardown_file(){
    [[ -e "$VARIABLES_FILE" ]] && rm "$VARIABLES_FILE"
}

setup(){
    # Bats modules are installed globally
    load "/usr/lib/node_modules/bats-support/load.bash"
    load "/usr/lib/node_modules/bats-assert/load.bash"

    # Import utils
    load "../../../@bin/bats/utils"
}

@test "User access key id length is correct" {
    run_layer

    output=$(echo $output | jq '.user_auditor_ci_iam_access_key_id.value')
    assert_output --regex "[A-Z0-9]{20}"
}