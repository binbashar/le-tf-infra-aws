import subprocess
from leverage import path
from leverage import conf

# Get build config variables
env = conf.load()

# Init variables
project = env["PROJECT"]
docker_entrypoint = env['TERRAFORM_ENTRYPOINT']
docker_image = "%s:%s" % (env['TERRAFORM_IMAGE_NAME'], env['TERRAFORM_IMAGE_TAG'])
docker_cmd = ["docker", "run", "--rm", "--workdir=/go/src/project/", "-it"]
docker_volumes = [
    "--volume=%s:/go/src/project:rw" % path.get_working_path(),
    "--volume=%s:/config" % path.get_account_config_path(),
    "--volume=%s:/common-config" % path.get_global_config_path(),
    "--volume=%s/.ssh:/root/.ssh" % path.get_home_path(),
    "--volume=%s/.gitconfig:/etc/gitconfig" % path.get_home_path(),
    "--volume=%s/.aws/%s:/root/.aws/%s" % (path.get_home_path(), project, project),
]
docker_envs = [
    "--env=AWS_SHARED_CREDENTIALS_FILE=/root/.aws/%s/credentials" % (project),
    "--env=AWS_CONFIG_FILE=/root/.aws/%s/config" % (project),
]
terraform_default_args = [
    "-var-file=/config/backend.config",
    "-var-file=/common-config/common.config",
    "-var-file=/config/account.config"
]

#
# Helper to build the docker commands.
#
def _build_cmd(command="", args=[], entrypoint=docker_entrypoint):
    cmd = docker_cmd + docker_volumes + docker_envs
    cmd.append("--entrypoint=%s" % entrypoint)
    cmd.append(docker_image)
    if command != "":
        cmd.append(command)
    cmd = cmd + args
    print("[DEBUG] %s" % (" ".join(cmd)))
    return cmd

def init():
    cmd = _build_cmd(command="init", args=["-backend-config=/config/backend.config"])
    return subprocess.call(cmd)

def plan():
    cmd = _build_cmd(
        command="plan",
        args=terraform_default_args
    )
    return subprocess.call(cmd)

def apply():
    cmd = _build_cmd(
        command="apply",
        args=terraform_default_args
    )
    return subprocess.call(cmd)

def output():
    cmd = _build_cmd(command="output")
    return subprocess.call(cmd)

def version():
    cmd = _build_cmd(command="version")
    return subprocess.call(cmd)

def shell():
    cmd = _build_cmd(command="", entrypoint="/bin/sh")
    return subprocess.call(cmd)
