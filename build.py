# Hack to be able to import local modules
import sys, os
sys.path.append(os.path.dirname(os.path.realpath(__file__)))
# Import leverage libraries
from leverage import task
from leverage import path

import hcl2
import json
import glob
import re

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
def decrypt():
    '''Decrypt secrets.tf file.'''
    os.system("ansible-vault decrypt --output secrets.dec.tf secrets.enc")

@task(_checkdir)
def encrypt():
    '''Encrypt secrets.dec.tf file.'''
    os.system("ansible-vault encrypt --output secrets.enc secrets.dec.tf && rm -rf secrets.dec.tf")

@task(_checkdir)
def layer_dependency(summary='False',quiet='False'):
    """Check layer dependency from the current layers"""
    try:
        remote_states = _layer_dependency(path.get_working_path())
    except Exception as e:
        print('Error getting deps:',e)

    if summary.lower() == 'true':
        deps = {'this': []}
        for rs in remote_states:
            deps['this'].append(remote_states[rs]['key'])
        remote_states = deps

    try:
        if quiet == 'False': print("Note layer dependency is calculated using remote states.\nNevertheless, other sort of dependencies could exist without this kind of resources,\ne.g. if you relay on some resource created in a different layer and not referenced here.")
        if len(remote_states) > 1:
          if len(remote_states) > 2:
            if quiet == 'False': print('Found these remote states:')
          else:
            if quiet == 'False': print('Found this remote state:')
          print(json.dumps(remote_states, indent=1))
        elif type(remote_states) == dict:
          print(json.dumps(remote_states, indent=1))
        else:
          if quiet == 'False': print('No dependency detected.')
    except Exception as e:
        print('Error processing deps:',e)

def _layer_dependency(directory):

    config_files = ['config.tf']
    config_file_contents = []

    # #########################################
    # get the config file contents
    # #########################################
    try:
      for config_file in config_files:
          with open(f"{directory}/{config_file}", 'r') as f:
              config_file_contents.append(hcl2.load(f))
    except Exception as e:
        raise Exception(f"Can not open config files: {e}")

    remote_states = {}

    if len(config_file_contents)>0:
      # #########################################
      # remote states
      # #########################################
      # they have this shape
      # data "terraform_remote_state" "eks-vpc" {
      #   backend = "s3"
      #   config = {
      #     region  = var.region
      #     profile = var.profile
      #     bucket  = var.bucket
      #     key     = "apps-prd/k8s-eks/network/terraform.tfstate"
      #   }
      # }
      remote_state_resource_name = 'terraform_remote_state'
      for data in config_file_contents:
              if 'data' in data.keys():
                  for d in data['data']:
                      #print('--#',d)
                      this_key = list(d.keys())[0]
                      if this_key == remote_state_resource_name:
                          #print('-->',d[this_key])
                          this_name = list(d[this_key].keys())[0]
                          #print('name',this_name)
                          if 'config' in d[this_key][this_name] and 'key' in d[this_key][this_name]['config']:
                              #print('   ---= dep:', d[this_key][this_name]['config']['key'])
                              this_tfstate = d[this_key][this_name]['config']['key'].split('/')
                              account = this_tfstate[0]
                              layer = '/'.join(this_tfstate[1:-1])
                              remote_states[this_name] = {'remote_state_name': this_name, 'account': account, 'layer': layer, 'key': d[this_key][this_name]['config']['key'], 'usage': {'used': False, 'files': []}}

      # #########################################
      # Where data is being used
      # #########################################
      remote_state_usage_regex = 'data\.terraform_remote_state\.([a-z_\-0-9]+)\..+'
      files = glob.glob(f"{directory}/*tf")
      for this_file in files:
          with open(this_file, 'r') as f:
              this_file_data = f.readlines()
              for line in this_file_data:
                  match_object = re.search(remote_state_usage_regex, line)
                  if match_object:
                      remote_states[match_object.group(1)]['usage']['used'] = True
                      if not this_file in remote_states[match_object.group(1)]['usage']['files']:
                          remote_states[match_object.group(1)]['usage']['files'].append(this_file)

    return remote_states
