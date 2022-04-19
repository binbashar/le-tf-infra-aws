locals {
  # The duration needs to be specified in ISO 8601. The minimum session duration
  # is 1 hour, and can be set to a maximum of 12 hours.
  # Ref: https://docs.aws.amazon.com/singlesignon/latest/userguide/howtosessionduration.html
  #
  # You can find some examples below:
  #  - PT12H    Twelve hours
  #  - PT2H30M  Two hours and thirty minutes
  #  - PT90M    Ninety minutes
  #
  session_duration = "PT1H"

  tags = {
    Terraform = "true"
  }
}
