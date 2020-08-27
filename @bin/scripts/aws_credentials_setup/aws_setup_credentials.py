from __future__ import print_function, unicode_literals
from PyInquirer import style_from_dict, Token, prompt, Separator
import subprocess, os, git, sys
from pathlib import Path


# ---------------------------------------------------------
# 0. Helpers
# ---------------------------------------------------------

def log(message):
    if debug: print('[DEBUG] ' + message)

def get_config_path():
    cur_path = Path(__file__).absolute()
    git_repo = git.Repo(cur_path, search_parent_directories=True)
    git_root = git_repo.git.rev_parse('--show-toplevel')
    return '{}/{}'.format(git_root, 'config/common.config')

def get_config():
    # Load config file
    config_file = open(get_config_path(), 'r')
    file_contents = config_file.readlines()
    config_file.close()

    # Parse file contents
    key_value_pairs = {}
    for line in file_contents:
        if line.strip() == '' or line.startswith('#'): continue

        key_value = line.split('=')
        key = key_value[0].strip().replace('"', '').replace('"', '')
        value = key_value[1].strip().replace('"', '').replace('"', '')
        key_value_pairs[key] = value
    
    return key_value_pairs

def find_account(config_entries, search_account):
    search_account = search_account.replace('-', '')
    for key, value in config_entries.items():
        if key.endswith('_account_id') and key.find(search_account) != -1:
            return value

    return default_account_id

def exit_if_empty(value, message):
    if len(value) == 0:
        print(message)
        sys.exit(0)

def build_accounts_choices():
    accounts_choices = []
    for account in accounts_list:
        accounts_choices.append({
            'name': account
        })
    return accounts_choices

def build_roles_choices():
    roles_choices = []
    for role in roles_dict:
        roles_choices.append({ 'name': role['name'] })
    
    return roles_choices

def find_role(target_role):
    for role in roles_dict:
        if role['name'] == target_role:
            return role
    return {}

def configure_profile(key, value, profile=''):
    # Append custom AWS env vars to current env vars
    current_env_vars = os.environ.copy()
    current_env_vars['AWS_CONFIG_FILE'] = aws_config_file
    current_env_vars['AWS_SHARED_CREDENTIALS_FILE'] = aws_shared_credentials_file

    # Execute AWS CLI to configure profiles
    cmd = ['aws', 'configure', 'set', key, value]
    if profile:
        cmd.append('--profile')
        cmd.append(profile)

    log(' '.join(cmd))
    subprocess.run(cmd, env=current_env_vars)


# ---------------------------------------------------------
# 1. Init
# ---------------------------------------------------------

# General
debug = True
config = get_config()

# Default choices
default_region_name = 'us-east-1'
default_output_name = 'json'
default_account_id = '000000000000'

# Guess the project name
default_project_name = config['project']

# Define all accounts available
accounts_list = ['security', 'shared', 'apps-devstg', 'apps-prd', 'legacy']

# Define roles properties
roles_dict = [
    {
        'name': 'OrganizationAccountAccessRole',
        'short_name': 'oaar',
        'source_profile': '{}-root',
    },
    {
        'name': 'DevOps',
        'short_name': 'devops',
        'source_profile': '{}-security',
    }
]


# ---------------------------------------------------------
# 2. Prompt for user input
# ---------------------------------------------------------
#
# Prompt user to input a project name
#
project_options = [{
    'type': 'input',
    'name': 'project',
    'message': '''
Input the project name
>> This will define the subfolder where the AWS credentials files will be written.
>> E.g. ~/.aws/[PROJECT_NAME]/config and ~/.aws/[PROJECT_NAME]/credentials )
''',
    'default': default_project_name,
    'validate': lambda answer: 'You must type a project name.' \
        if len(answer) == 0 else True
}]
selected_project = prompt(project_options)

#
# Define AWS credentials files
#
aws_config_file = "~/.aws/{}/config".format(selected_project['project'])
aws_shared_credentials_file = "~/.aws/{}/credentials".format(selected_project['project'])
print('------------------------------------------------------------')
print('-- The following files will be created/updated:')
print('-- >> AWS config file: {}'.format(aws_config_file))
print('-- >> AWS credentials file: {}'.format(aws_shared_credentials_file))
print('------------------------------------------------------------')
print('')

#
# Prompt user to choose the accounts to be configured
#
accounts_options = [{
    'type': 'checkbox',
    'name': 'accounts',
    'message': 'Select all the accounts you would like to configure',
    'choices': build_accounts_choices(),
    'validate': lambda answer: 'You must choose at least one account.' \
        if len(answer) == 0 else True
}]
accounts_selected = prompt(accounts_options)
exit_if_empty(accounts_selected['accounts'], 'No accounts were selected')

#
# Prompt user to input an account id for each selected account
#
account_ids_map = {}
for account in accounts_selected['accounts']:
    account_options = [{
        'type': 'input',
        'name': account,
        'message': 'Input the account id of "{}" account'.format(account),
        'default': find_account(config, account),
        'validate': lambda answer: 'You must choose at least one account.' \
            if len(answer) == 0 else True
    }]
    account_choice = prompt(account_options)
    account_ids_map[account] = account_choice[account]

#
# Prompt user to choose the roles to be configured
#
roles_options = [{
    'type': 'checkbox',
    'name': 'roles',
    'message': 'Check all the roles you would like to configure',
    'choices': build_roles_choices(),
    'validate': lambda answer: 'You must choose at least one role.' \
        if len(answer) == 0 else True
}]
roles_selected = prompt(roles_options)
exit_if_empty(roles_selected['roles'], 'No roles were selected')

#
# Prompt user to choose a default region
#
region_options = [{
    'type': 'input',
    'name': 'region',
    'message': 'Input the region name',
    'default': default_region_name,
    'validate': lambda answer: 'You must choose at least one account.' \
        if len(answer) == 0 else True
}]
region_selected = prompt(region_options)

#
# Prompt user to choose a default output
#
output_options = [{
    'type': 'input',
    'name': 'output',
    'message': 'Input the region name',
    'default': default_output_name,
    'validate': lambda answer: 'You must choose at least one account.' \
        if len(answer) == 0 else True
}]
output_selected = prompt(output_options)


# ---------------------------------------------------------
# 3. Configure Profiles
# ---------------------------------------------------------

#
# Create every Named Profile in the AWS config file
#
print('')
print('------------------------------------------------------------')
print('-- Generating named profiles...')
print('------------------------------------------------------------')
for role in roles_selected['roles']:
    role_props = find_role(role)
    
    for account in accounts_selected['accounts']:
        profile_name = "{}-{}-{}".format(selected_project['project'], account, role_props['short_name'])
        role_arn = "arn:aws:iam::{}:role/{}".format(account_ids_map.get(account), role)
        source_profile = role_props['source_profile'].format(selected_project['project'])

        # Each named profile needs to set output, region, role_arn and source_profile
        configure_profile("profile." + profile_name + ".output", output_selected['output'])
        configure_profile("profile." + profile_name + ".region", region_selected['region'])
        configure_profile("profile." + profile_name + ".role_arn", role_arn)
        configure_profile("profile." + profile_name + ".source_profile", source_profile)
print('------------------------------------------------------------')
print('-- All named profiles were written to: "{}"'.format(aws_config_file))
print('------------------------------------------------------------')
print('')

#
# Create every Source Profile in the AWS credentials file
#
print('------------------------------------------------------------')
print('-- Generating source profiles... ')
print('------------------------------------------------------------')
for role in roles_selected['roles']:
    role_props = find_role(role)
    source_profile = role_props['source_profile'].format(selected_project['project'])
    
    access_key_id_options = [{
        'type': 'password',
        'name': 'access_key_id',
        'message': 'Type in the Access Key ID for "{}" profile'.format(source_profile),
        'validate': lambda answer: 'You must type an access key id.' \
            if len(answer) == 0 else True
    }]
    selected_access_key_id = prompt(access_key_id_options)

    secret_access_key_options = [{
        'type': 'password',
        'name': 'secret_access_key',
        'message': 'Type in the Secret Access Key for "{}" profile'.format(source_profile),
        'validate': lambda answer: 'You must type an access key id.' \
            if len(answer) == 0 else True
    }]
    selected_secret_access_key = prompt(secret_access_key_options)

    # Each source profile needs to set access keys, secret access key, region and output
    configure_profile("aws_access_key_id", selected_access_key_id['access_key_id'], source_profile)
    configure_profile("aws_secret_access_key", selected_secret_access_key['secret_access_key'], source_profile)
print('------------------------------------------------------------')
print('-- All source profiles written to: "{}"'.format(aws_shared_credentials_file))
print('------------------------------------------------------------')
