#!/usr/bin/env python3
import hcl2
import json
import glob
import re
from pathlib import Path
from collections import ChainMap, defaultdict
from itertools import chain

import sys, os

from leverage import conf
from leverage import task
from leverage import path

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
def layer_dependency(summary='False',quiet='False'):
    """
    Check layer dependency from the current layers
    """

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
        if quiet == 'False': print("Note layer dependency is calculated using remote states.\nNevertheless, other sort of dependencies could exist without this kind of resources,\ne.g. if you rely on some resource created in a different layer and not referenced here.")
        if len(remote_states) > 0:
            print(json.dumps(remote_states, indent=1))
        else:
            if quiet == 'False': print('No dependency detected.')
    except Exception as e:
        print('Error processing deps:',e)
        sys.exit(0)

def _layer_dependency(directory):
    """
    Resolve layer dependencies
    """

    # #########################################
    # configuration vars
    # #########################################
    remote_state_usage_regex = 'data\.terraform_remote_state\.([a-z_\-0-9]+)'
    locals_regex = '(\$\{|)local\.([a-zA-Z_\-0-9]+)(\s+.*|)(\}|\s+.*|)'
    var_regex = '(\$\{|)var\.([a-zA-Z_\-0-9]+)(\s+.*|)(\}|)'
    each_regex = '(\$\{|)each\.value\.([a-zA-Z_\-0-9]+)(\}|)'
    lookup_regex = '(\$\{|)lookup\(each\.value,\s*(\\"|\'|)([a-zA-Z_\-0-9]+)(\\"|\'|)\)(\}|)'
    remote_state_resource_name = 'terraform_remote_state'

    # #########################################
    # other vars
    # #########################################
    remote_states = {}

    # #########################################
    # get the config values
    # #########################################
    config_tfvars = _load_tfvars()
    config_locals = _load_locals()

    # #########################################
    # config files settings
    # #########################################
    tf_file_contents = []

    # #########################################
    # get the .tf file contents
    # #########################################
    tf_files = glob.glob(f"./*tf")

    #return _load_hclfile(files,_load_locals_aux)
    try:
      for tf_file in tf_files:
          with open(tf_file, 'r') as f:
              tf_file_contents.append(hcl2.load(f))
    except Exception as e:
        raise Exception(f"Can not open config files: {e}")
    # #########################################
    # get the remote states
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
    # get data elements from the tf files
    files_with_datasources = (config for config in tf_file_contents if 'data' in config)
    all_datasources = (config['data'] for config in files_with_datasources)
    all_remote_state_resources = (datasource[remote_state_resource_name]
                                  for datasource in chain(*all_datasources)
                                  if remote_state_resource_name in datasource)
    files_with_variable_definitions = (config for config in tf_file_contents if 'variable' in config)
    all_variable_definitions = (config['variable'] for config in files_with_variable_definitions)
    all_variable_definitions_resources = (v
                                  for v in chain(*all_variable_definitions)
                                  )
    all_variable_definitions_dict = {a: b for f in all_variable_definitions_resources for (a, b) in f.items()}


    # #########################################
    # if no data return
    # #########################################
    if len(tf_file_contents)==0:
        return remote_states

    # #########################################
    # Where "data" elements are used
    # #########################################
    files = glob.glob(f"{directory}/*tf")
    remote_state_lines = defaultdict(list)
    for this_file in files:
        with open(this_file, 'r') as f:
            this_file_data = f.readlines()
            for line in this_file_data:
                if match_object := re.search(remote_state_usage_regex, line):
                    if not this_file in remote_state_lines[match_object.group(1)]:
                        remote_state_lines[match_object.group(1)].append(this_file)


    # #########################################
    # process data
    # #########################################
    for remote_state_resourse in all_remote_state_resources:
        [(this_name, this_data)] = remote_state_resourse.items()

        if not 'config' in this_data or not 'key' in this_data['config']:
            continue

        if 'for_each' in this_data:
            for_each_object = None
            if match_object := re.search(var_regex, this_data['for_each']):
                if match_object.group(2) in config_tfvars:
                    for_each_object = config_tfvars[match_object.group(2)]
            elif match_object := re.search(locals_regex, this_data['for_each']):
                if match_object.group(2) in config_locals:
                    for_each_object = config_locals[match_object.group(2)]
            else:
                # for each not recognized
                pass
            if for_each_object is None:
                remote_states[this_name] = _extract_data_from_remote_state(this_data, this_name, config_tfvars, config_locals)
                if this_name in remote_state_lines.keys():
                    remote_states[this_name]['usage']['files'] = remote_state_lines[this_name]
                    remote_states[this_name]['usage']['used'] = True
            else:
                if type(for_each_object) == dict:
                    for for_each_key in for_each_object:
                        key_override = None
                        if match_key := re.search(each_regex,this_data['config']['key']):
                            if match_key.group(2) in for_each_object[for_each_key]:
                                key_override = for_each_object[for_each_key][match_key.group(2)]
                        elif match_key := re.search(lookup_regex,this_data['config']['key']):
                            if match_key.group(3) in for_each_object[for_each_key]:
                                key_override = for_each_object[for_each_key][match_key.group(3)]

                        remote_states[f"{this_name}[{for_each_key}]"] = _extract_data_from_remote_state(this_data, this_name, config_tfvars, config_locals, name_suffix=f"[{for_each_key}]", key_override=key_override)
                        if this_name in remote_state_lines.keys():
                            remote_states[f"{this_name}[{for_each_key}]"]['usage']['files'] = remote_state_lines[this_name]
                            remote_states[f"{this_name}[{for_each_key}]"]['usage']['used'] = True
                else:
                    # is it possible to have a type other than dict?
                    # if yes the case thas to be covered here
                    pass
        else:
            # not a for_each
            if 'count' in this_data:
                if match_object := re.search(var_regex, this_data['count']):
                    if match_object.group(2) in config_tfvars:
                        this_data['count'] = config_tfvars[match_object.group(2)]
                    else:
                        if match_object.group(2) in all_variable_definitions_dict and 'default' in all_variable_definitions_dict[match_object.group(2)]:
                            this_data['count'] = all_variable_definitions_dict[match_object.group(2)]['default']
                elif match_object := re.search(locals_regex, this_data['count']):
                    if match_object.group(2) in config_locals:
                        this_data['count'] = config_locals[match_object.group(2)]
                else:
                    # count not recognized
                    pass
                if not this_data['count']:
                    continue
            remote_states[this_name] = _extract_data_from_remote_state(this_data, this_name, config_tfvars, config_locals)
            if this_name in remote_state_lines.keys():
                remote_states[this_name]['usage']['files'] = remote_state_lines[this_name]
                remote_states[this_name]['usage']['used'] = True

    return remote_states

def _extract_data_from_remote_state(this_data, this_name, config_tfvars, config_locals, name_suffix="",key_override=None):
    """
    Extract specific data from remote_state objects
    """

    var_regex = '(\$\{|)var\.([a-zA-Z_\-0-9]+)(\}|)'

    if key_override is None:
        key_to_show = this_data['config']['key']
    else:
        key_to_show = key_override

    if match_object := re.search(var_regex, key_to_show):
        if match_object.group(2) in config_tfvars:
            key_to_show = re.sub(var_regex, config_tfvars[match_object.group(2)], key_to_show)
    this_tfstate = key_to_show.split('/')
    layer = '/'.join(this_tfstate[1:-1])
    account = this_tfstate[0]
    return {'remote_state_name': f"{this_name}{name_suffix}", 'account': account, 'layer': layer, 'key': key_to_show, 'key_raw': this_data['config']['key'], 'usage': {'used': False, 'files': []}}

def _load_tfvars():
    """
    Load values from defined tfvars
    """
    cur_dir = Path(path.get_working_path())
    acc_config_dir = Path(path.get_account_config_path())
    tfvars_files = [
       f"{acc_config_dir}/account.tfvars",
       f"{acc_config_dir}/backend.tfvars",
    ]
    return _load_hclfile(tfvars_files)

def _load_locals():
    """
    Load local terraform values from all *tf files
    """

    locals_file_contents = {}

    files = glob.glob(f"./*tf")

    return _load_hclfile(files,_load_locals_aux)

def _load_locals_aux(data):
    """
    Load local terraform values from all *tf files - aux funct
    """
    if 'locals' in data:
        return dict(ChainMap(*data['locals']))
    else:
        return data

def _load_hclfile(hcl_files, hook_process_data=None):
    """
    Load values from defined hcl files
    """
    hcl_file_contents = {}

    for this_file in hcl_files:
        with open(this_file, 'r') as f:
            raw_values = hcl2.load(f)
            if not hook_process_data is None:
                raw_values = hook_process_data(raw_values)
            hcl_file_contents = dict(ChainMap(*[hcl_file_contents,raw_values]))

    return hcl_file_contents
