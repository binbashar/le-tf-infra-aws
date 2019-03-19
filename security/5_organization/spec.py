import yaml

def load(config_file):
    stream = file(config_file, 'r')
    config = yaml.load(stream)
    return config

def find_policy_by_name(policy_name, policies):
    for policy in policies:
        if policy['name'] == policy_name:
            return policy
    
    return None
