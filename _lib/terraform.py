import subprocess
import os
from leverage import path
from leverage import conf

# Get build config variables
env = conf.load()

# Set project name
project = env.get("PROJECT", "")
if project == "": raise Exception("Project is not set")

# Enable MFA support?
mfa_enabled = True if env.get("MFA_ENABLED", "false") else False

# Set default entrypoint, use the mfa entrypoint if mfa is enabled
docker_entrypoint = env.get("TERRAFORM_ENTRYPOINT", "/bin/terraform")
if mfa_enabled:
    docker_entrypoint = env.get("TERRAFORM_MFA_ENTRYPOINT", docker_entrypoint)

# Set docker image, workdir, and other default arguments
docker_image = "%s:%s" % (env.get("TERRAFORM_IMAGE_NAME"), env.get("TERRAFORM_IMAGE_TAG"))
docker_workdir = "/go/src/project"
docker_cmd = ["docker", "run", "--rm", "--workdir=%s" % docker_workdir, "-it"]

# Set docker volumes -- MFA uses additional volumes
docker_volumes = [
    "--volume=%s:%s:rw" % (path.get_working_path(), docker_workdir),
    "--volume=%s:/config" % path.get_account_config_path(),
    "--volume=%s:/common-config" % path.get_global_config_path(),
    "--volume=%s/.ssh:/root/.ssh" % path.get_home_path(),
    "--volume=%s/.gitconfig:/etc/gitconfig" % path.get_home_path(),
]
if mfa_enabled:
    docker_volumes.append("--volume=%s/@bin/scripts:/root/scripts" % (path.get_root_path()))
    docker_volumes.append("--volume=%s/.aws/%s:/root/tmp/%s" % (path.get_home_path(), project, project))
else:
    docker_volumes.append("--volume=%s/.aws/%s:/root/.aws/%s" % (path.get_home_path(), project, project))

# Set docker environment variables -- MFA uses additional environment variables
docker_envs = [
    "--env=AWS_SHARED_CREDENTIALS_FILE=/root/.aws/%s/credentials" % (project),
    "--env=AWS_CONFIG_FILE=/root/.aws/%s/config" % (project),
]
if mfa_enabled:
    docker_envs.append("--env=BACKEND_CONFIG_FILE=/config/backend.config")
    docker_envs.append("--env=COMMON_CONFIG_FILE=/common-config/common.config")
    docker_envs.append("--env=SRC_AWS_CONFIG_FILE=/root/tmp/%s/config" % (project))
    docker_envs.append("--env=SRC_AWS_SHARED_CREDENTIALS_FILE=/root/tmp/%s/credentials" % (project))
    docker_envs.append("--env=AWS_CACHE_DIR=/root/tmp/%s/cache" % (project))

# Set Terraform default arguments -- normally used for plan, apply, destroy, and others
terraform_default_args = [
    "-var-file=/config/backend.config",
    "-var-file=/common-config/common.config",
    "-var-file=/config/account.config"
]

# -------------------------------------------------------------------

#
# Helper to build the docker commands.
#
def _build_cmd(command="", args=[], entrypoint=docker_entrypoint):
    cmd = docker_cmd + docker_volumes + docker_envs
    cmd.append("--entrypoint=%s" % entrypoint)
    cmd.append(docker_image)
    if command != "":
        cmd.append("--")
        if mfa_enabled:
            cmd.append(env.get("TERRAFORM_ENTRYPOINT"))
        
        cmd.append(command)
    
    cmd = cmd + args
    print("[DEBUG] %s" % (" ".join(cmd)))
    return cmd

def init():
    cmd = _build_cmd(command="init", args=["-backend-config=/config/backend.config"])
    return subprocess.call(cmd)

def plan():
    cmd = _build_cmd(command="plan", args=terraform_default_args)
    return subprocess.call(cmd)

def apply():
    cmd = _build_cmd(command="apply", args=terraform_default_args)
    return subprocess.call(cmd)

def output():
    cmd = _build_cmd(command="output")
    return subprocess.call(cmd)

def destroy():
    cmd = _build_cmd(command="destroy", args=terraform_default_args)
    return subprocess.call(cmd)

def version():
    cmd = _build_cmd(command="version")
    return subprocess.call(cmd)

def shell():
    cmd = _build_cmd(command="", entrypoint="/bin/sh")
    return subprocess.call(cmd)

def format_check():
    cmd = _build_cmd(command="fmt", args=["-recursive", "-check", docker_workdir])
    return subprocess.call(cmd)

def format():
    cmd = _build_cmd(command="fmt", args=["-recursive"])
    return subprocess.call(cmd)

def decrypt():
    cmd = "ansible-vault decrypt --output secrets.dec.tf secrets.enc"
    return os.system(cmd)

def encrypt():
    cmd = "ansible-vault encrypt --output secrets.enc secrets.dec.tf && rm -rf secrets.dec.tf"
    return os.system(cmd)

def validate_tf_layout():
    return os.system("../../@bin/scripts/validate-terraform-layout.sh")
