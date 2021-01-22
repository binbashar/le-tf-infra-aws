# Hack to be able to import local modules
import sys, os
sys.path.append(os.path.dirname(os.path.realpath(__file__)))
# Import leverage libraries
from leverage import task
# Import local libraries
from _lib import terraform

@task()
def version():
    '''Show terraform version.'''
    terraform.version()

@task()
def init():
    '''Initialize Terraform.'''
    terraform.init()

@task()
def plan():
    '''Plan Terraform.'''
    terraform.plan()

@task()
def apply():
    '''Apply Terraform.'''
    terraform.apply()

@task()
def shell():
    '''Run a shell Terraform container.'''
    terraform.shell()
