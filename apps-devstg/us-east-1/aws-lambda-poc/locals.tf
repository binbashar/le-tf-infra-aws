locals {
    tags = {

        application    = "bb-lambda-test"
        environment    = "test"
        owner          = "juan.delacamara@binbash.com.ar"
        terraform      = "true"

    }

    lamba_environment_variables = {

        DUMMY_VAR = "dummy value from Binbash"

    }
}
