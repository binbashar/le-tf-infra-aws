# Hack to be able to import local modules
import sys, os
sys.path.append(os.path.dirname(os.path.realpath(__file__)))
# Import leverage libraries
from leverage import task
# Import local libraries
from _lib import terraform

@task()
def init(*args):
    '''Initialize Terraform in this layer.'''
    terraform.init(list(args))
    # terraform.change_terraform_dir_ownership()

@task()
def plan(*args):
    '''Generate a Terraform execution plan for this layer.'''
    terraform.plan(list(args))

@task()
def apply(*args):
    '''Build or change the Terraform infrastructre in this layer.'''
    terraform.apply(list(args))
    terraform.change_terraform_dir_ownership()

@task()
def output():
    '''Show all terraform output variables of this layer.'''
    terraform.output()

@task()
def destroy(*args):
    '''Destroy terraform infrastructure in this layer.'''
    terraform.destroy(list(args))

@task()
def shell():
    '''Open a shell into the Terraform container in this layer.'''
    terraform.shell()

@task()
def version():
    '''Print terraform version.'''
    terraform.version()

@task()
def decrypt():
    '''Decrypt secrets.tf file.'''
    os.system("ansible-vault decrypt --output secrets.dec.tf secrets.enc")

@task()
def encrypt():
    '''Encrypt secrets.dec.tf file.'''
    os.system("ansible-vault encrypt --output secrets.enc secrets.dec.tf && rm -rf secrets.dec.tf")

@task()
def validate_layout():
    '''Validate the layout convention of this Terraform layer.'''
    return os.system("../../@bin/scripts/validate-terraform-layout.sh")
