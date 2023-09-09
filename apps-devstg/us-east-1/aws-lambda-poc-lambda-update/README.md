# Steps for updating lambda

## Import function

``` shell
leverate tf import aws_lambda_function.func "bb-lambda-test-test"
```

## Apply the changes

``` shell
leverate tf apply
```

## Change with CLI from inside Leverage

```shell
PROFILE=bb-apps-devstg-devops ./update-function-leverage-shell.sh 
```


