module "lambdas" {
  source = "../modules/download-lambda"
  lambdas = [
    {
      name = "webhook"
      tag  = "v1.18.2"
    },
    {
      name = "runners"
      tag  = "v1.18.2"
    },
    {
      name = "runner-binaries-syncer"
      tag  = "v1.18.2"
    }
  ]
}
