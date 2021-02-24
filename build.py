# Hack to be able to import local modules
import sys, os
sys.path.append(os.path.dirname(os.path.realpath(__file__)))
# Import leverage libraries
from leverage import task
from leverage import path
# Import local libraries
from _lib import terraform

@task()
def checkdir():
    '''Check if current directory can execute certain tasks'''
    if path.get_working_path() == path.get_root_path():
        print("This task cannot be run from root path")
        sys.exit(0)
    elif path.get_working_path() == path.get_account_path():
        print("This task cannot be run from account path")
        sys.exit(0)

@task(checkdir)
def init(*args):
    '''Initialize Terraform in this layer.'''
    terraform.init(list(args))
    terraform.change_terraform_dir_ownership()

@task(checkdir)
def plan(*args):
    '''Generate a Terraform execution plan for this layer.'''
    terraform.plan(list(args))

@task(checkdir)
def apply(*args):
    '''Build or change the Terraform infrastructre in this layer.'''
    terraform.apply(list(args))
    terraform.change_terraform_dir_ownership()

@task()
def output(checkdir):
    '''Show all terraform output variables of this layer.'''
    terraform.output()

@task(checkdir)
def destroy(*args):
    '''Destroy terraform infrastructure in this layer.'''
    terraform.destroy(list(args))

@task()
def shell():
    '''Open a shell into the Terraform container in this layer.'''
    terraform.shell()

@task(checkdir)
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

@task(checkdir)
def decrypt():
    '''Decrypt secrets.tf file.'''
    os.system("ansible-vault decrypt --output secrets.dec.tf secrets.enc")

@task(checkdir)
def encrypt():
    '''Encrypt secrets.dec.tf file.'''
    os.system("ansible-vault encrypt --output secrets.enc secrets.dec.tf && rm -rf secrets.dec.tf")

@task(checkdir)
def validate_layout():
    '''Validate the layout convention of this Terraform layer.'''
    return os.system("../../@bin/scripts/validate-terraform-layout.sh")
