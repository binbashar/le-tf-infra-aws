# Amazon Guarduty

## Notes about removing Guarduty
Before removing it you need to disassociate all accounts via the AWS CLI or the AWS Console.

But even after that, you won't be able to remove it from this layer, instead you'll have to remove the administrator delegation that is set up in the management account.
