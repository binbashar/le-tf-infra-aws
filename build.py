import hcl2
import json
import glob
import re
from pathlib import Path
from collections import ChainMap
# Hack to be able to import local modules
import sys, os
sys.path.append(os.path.dirname(os.path.realpath(__file__)))
# Import leverage libraries
from leverage import task
from leverage import path
from leverage import conf


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
        sys.exit(0)

    if summary.lower() == 'true':
        deps = {'this': []}
        for rs in remote_states:
            deps['this'].append(remote_states[rs]['key'])
        remote_states = deps

    try:
        if quiet == 'False': print("Note layer dependency is calculated using remote states.\nNevertheless, other sort of dependencies could exist without this kind of resources,\ne.g. if you relay on some resource created in a different layer and not referenced here.")
        if len(remote_states) > 0:
            print(json.dumps(remote_states, indent=1))
        else:
            if quiet == 'False': print('No dependency detected.')
    except Exception as e:
        print('Error processing deps:',e)
        sys.exit(0)

def _layer_dependency(directory):

    config_tfvars = _load_tfvars()
    config_locals = _load_locals()

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
        # Where data is being used
        # #########################################
        remote_state_usage_regex = 'data\.terraform_remote_state\.([a-z_\-0-9]+)'
        files = glob.glob(f"{directory}/*tf")
        remote_state_lines = {}
        for this_file in files:
            with open(this_file, 'r') as f:
                this_file_data = f.readlines()
                for line in this_file_data:
                    if match_object := re.search(remote_state_usage_regex, line):
                        if not match_object.group(1) in remote_state_lines.keys():
                            remote_state_lines[match_object.group(1)] = [this_file]
                        else:
                            if not this_file in remote_state_lines[match_object.group(1)]:
                                remote_state_lines[match_object.group(1)].append(this_file)

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
        locals_regex = '(\$\{|)local\.([a-zA-Z_\-0-9]+)(\}|)'
        var_regex = '(\$\{|)var\.([a-zA-Z_\-0-9]+)(\}|)'
        each_regex = '(\$\{|)each\.value\.([a-zA-Z_\-0-9]+)(\}|)'
        lookup_regex = '(\$\{|)lookup\(each\.value,\s*(\\"|\'|)([a-zA-Z_\-0-9]+)(\\"|\'|)\)(\}|)'
        remote_state_resource_name = 'terraform_remote_state'
        for data in config_file_contents:
              if not 'data' in data.keys():
                  continue
              for d in data['data']:
                  this_key = list(d.keys())[0]
                  if not this_key == remote_state_resource_name:
                      continue
                  this_name = list(d[this_key].keys())[0]
                  if not 'config' in d[this_key][this_name] or not 'key' in d[this_key][this_name]['config']:
                      continue
                  if 'for_each' in d[this_key][this_name]:

                      for_each_object = None
                      if match_object := re.search(var_regex, d[this_key][this_name]['for_each']):
                          if match_object.group(2) in config_tfvars:
                              for_each_object = config_tfvars[match_object.group(2)]
                      elif match_object := re.search(locals_regex, d[this_key][this_name]['for_each']):
                          if match_object.group(2) in config_locals:
                              for_each_object = config_locals[match_object.group(2)]
                      else:
                          # for each not recognized
                          pass
                      if for_each_object is None:
                          remote_states[this_name] = _extract_data_from_remote_state(d, this_key, this_name, config_tfvars, config_locals)
                          if this_name in remote_state_lines.keys():
                              remote_states[this_name]['usage']['files'] = remote_state_lines[this_name]
                              remote_states[this_name]['usage']['used'] = True
                      else:
                          if type(for_each_object) == dict:
                              for for_each_key in for_each_object:
                                  key_override = None
                                  if match_key := re.search(each_regex,d[this_key][this_name]['config']['key']):
                                      if match_key.group(2) in for_each_object[for_each_key]:
                                          key_override = for_each_object[for_each_key][match_key.group(2)]
                                  elif match_key := re.search(lookup_regex,d[this_key][this_name]['config']['key']):
                                      if match_key.group(3) in for_each_object[for_each_key]:
                                          key_override = for_each_object[for_each_key][match_key.group(3)]

                                  remote_states[f"{this_name}[{for_each_key}]"] = _extract_data_from_remote_state(d, this_key, this_name, config_tfvars, config_locals, name_suffix=f"[{for_each_key}]", key_override=key_override)
                                  if this_name in remote_state_lines.keys():
                                      remote_states[f"{this_name}[{for_each_key}]"]['usage']['files'] = remote_state_lines[this_name]
                                      remote_states[f"{this_name}[{for_each_key}]"]['usage']['used'] = True

                  else:
                      remote_states[this_name] = _extract_data_from_remote_state(d, this_key, this_name, config_tfvars, config_locals)
                      if this_name in remote_state_lines.keys():
                          remote_states[this_name]['usage']['files'] = remote_state_lines[this_name]
                          remote_states[this_name]['usage']['used'] = True

    return remote_states

def _extract_data_from_remote_state(d, this_key, this_name, config_tfvars, config_locals, name_suffix="",key_override=None):
    if key_override is None:
        key_to_show = d[this_key][this_name]['config']['key']
    else:
        key_to_show = key_override

    var_regex = '(\$\{|)var\.([a-zA-Z_\-0-9]+)(\}|)'
    if match_object := re.search(var_regex, key_to_show):
        if match_object.group(2) in config_tfvars:
            key_to_show = re.sub(var_regex, config_tfvars[match_object.group(2)], key_to_show)
    this_tfstate = key_to_show.split('/')
    layer = '/'.join(this_tfstate[1:-1])
    account = this_tfstate[0]
    return {'remote_state_name': f"{this_name}{name_suffix}", 'account': account, 'layer': layer, 'key': key_to_show, 'key_raw': d[this_key][this_name]['config']['key'], 'usage': {'used': False, 'files': []}}

def _load_tfvars():
    cur_dir = Path(path.get_working_path())
    acc_congig_dir = Path(path.get_account_config_path())
    rel_acc_config_dir = os.path.relpath(acc_congig_dir, start=cur_dir)
    config = conf.load(config_filename=f"{rel_acc_config_dir}/account.tfvars") | conf.load(config_filename=f"{rel_acc_config_dir}/backend.tfvars")

    return config

def _load_locals():

    locals_file_contents = {}

    files = glob.glob(f"./*tf")
    for this_file in files:
        with open(this_file, 'r') as f:
            raw_values = hcl2.load(f)
            if 'locals' in raw_values:
                values = dict(ChainMap(*raw_values['locals']))
            locals_file_contents = dict(ChainMap(*[locals_file_contents,values]))

    return locals_file_contents
