# Hack to be able to import local modules
import sys, os
sys.path.append(os.path.dirname(os.path.realpath(__file__)))
# Import leverage libraries
from leverage import task
from leverage import path
# Import local libraries
from _lib import terraform

@task()
def _checkdir():
    '''Check if current directory can execute certain tasks'''
    if path.get_working_path() == path.get_root_path():
        print("This task cannot be run from root path")
        sys.exit(0)
    elif path.get_working_path() == path.get_account_path():
        print("This task cannot be run from account path")
        sys.exit(0)

@task(_checkdir)
def init(*args):
    '''
    Initialize Terraform in this layer. For instance:
                                        > leverage init
                                        > leverage init["-reconfigure"]
    '''
    terraform.init(list(args))
    terraform.change_terraform_dir_ownership()

@task(_checkdir)
def plan(*args):
    '''Generate a Terraform execution plan for this layer.'''
    terraform.plan(list(args))

@task(_checkdir)
def apply(*args):
    '''
    Build or change the Terraform infrastructre in this layer. For instance:
                                        > leverage apply
                                        > leverage apply["-auto-approve"]
    '''
    terraform.apply(list(args))

@task(_checkdir)
def output(*args):
    '''
    Show all terraform output variables of this layer. For instance:
                                        > leverage output
                                        > leverage output["-json"]
    '''
    terraform.output(list(args))

@task(_checkdir)
def destroy(*args):
    '''Destroy terraform infrastructure in this layer.'''
    terraform.destroy(list(args))

@task()
def shell(*args):
    '''Open a shell into the Terraform container in this layer.'''
    terraform.shell(list(args))

@task(_checkdir)
def version():
    '''Print terraform version.'''
    terraform.version()

@task()
def format():
    '''Rewrite all Terraform files to meet the canonical format.'''
    terraform.format()

@task()
def format_check():
    '''Check if Terraform files do not meet the canonical format.'''
    terraform.format_check()

@task(_checkdir)
def decrypt():
    '''Decrypt secrets.tf file.'''
    os.system("ansible-vault decrypt --output secrets.dec.tf secrets.enc")

@task(_checkdir)
def encrypt():
    '''Encrypt secrets.dec.tf file.'''
    os.system("ansible-vault encrypt --output secrets.enc secrets.dec.tf && rm -rf secrets.dec.tf")

@task(_checkdir)
def state():
    '''Perform Terraform state operations.'''
    print('''
===============================================================================
- IMPORTANT:
===============================================================================
- Leverage CLI does not yet support Terraform state operations. However this
- task provides a small helper to make it a bit easier.
- This task will present you with a shell that is ready to run Terraform state
- commands such as `terraform state list` and more.
===============================================================================
''')
    terraform.state()

@task(_checkdir)
def validate_layout():
    '''Validate the layout convention of this Terraform layer.'''
    return os.system("../../@bin/scripts/validate-terraform-layout.sh")

