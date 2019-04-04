#!/bin/bash

#
# Reference article:
# https://www.bennadel.com/blog/3420-obtaining-a-wildcard-ssl-certificate-from-letsencrypt-using-the-dns-challenge.htm
#

#
# 1st manual round exec
#
DOMAIN='*.aws.binbash.com.ar'
EMAIL='info@binbash.com.ar'

jenkins@bb-jenkins-vault:~$ docker run -it --rm --name letsencrypt \
-v "/etc/letsencrypt:/etc/letsencrypt" \
-v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
quay.io/letsencrypt/letsencrypt:latest \
certonly \
-d $DOMAIN \
--manual \
--preferred-challenges dns \
--server https://acme-v02.api.letsencrypt.org/directory \
--email $EMAIL \
--keep-until-expiring \
--agree-tos

#=================================================================================================#
# Afterwards in Ansible binbash_inc.letsencrypt-wildcard-to-s3 Role we'll have the --non-intereactive flag #
#=================================================================================================#
#- name: letsencrypt-wilcard-refresh container start
#  docker_container:
#    name: letsencrypt-wilcard-cert-refresh
#    image: "{{ letsencrypt_docker_cont_name }}"
#    state: started
#    restart_policy: always
#    command: |
#      certonly -d '{{ letsencrypt_wilcard_domain }}' \
#      --manual --preferred-challenges dns \
#      --server https://acme-v02.api.letsencrypt.org/directory \
#      --email {{ letsencrypt_notif_email }} \
#      --keep-until-expiring \
#      --agree-tos \
#      --non-interactive
#    volumes:
#    - "{{ letsencrypt_backup_dir }}:{{ letsencrypt_backup_dir }}"
#    - "{{ letsencrypt_files_dir }}:{{ letsencrypt_files_dir }}"


#=================================================================================================#
# EG OF EXECUTION                                                                                 #
#=================================================================================================#
#jenkins@bb-jenkins-vault:~$ docker run -it --rm --name letsencrypt \
#> -v "/etc/letsencrypt:/etc/letsencrypt" \
#> -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
#> quay.io/letsencrypt/letsencrypt:latest \
#> certonly \
#> -d '*.aws.binbash.com.ar' \
#> --manual \
#> --preferred-challenges dns \
#> --server https://acme-v02.api.letsencrypt.org/directory \
#> --email info@binbash.com.ar \
#> --keep-until-expiring \
#> --agree-tos
#Warning: This Docker image will soon be switching to Alpine Linux.
#You can switch now using the certbot/certbot repo on Docker Hub.
#/opt/certbot/venv/local/lib/python2.7/site-packages/cryptography/hazmat/primitives/constant_time.py:26: CryptographyDeprecationWarning: Support for your Python version is deprecated. The next version of cryptography will remove support. Please upgrade to a 2.7.x release that supports hmac.compare_digest as soon as possible.
#  utils.PersistentlyDeprecated2018,
#Saving debug log to /var/log/letsencrypt/letsencrypt.log
#Plugins selected: Authenticator manual, Installer None
#
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Would you be willing to share your email address with the Electronic Frontier
#Foundation, a founding partner of the Let's Encrypt project and the non-profit
#organization that develops Certbot? We'd like to send you email about our work
#encrypting the web, EFF news, campaigns, and ways to support digital freedom.
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#(Y)es/(N)o: Y
#Obtaining a new certificate
#Performing the following challenges:
#dns-01 challenge for aws.binbash.com.ar
#
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#NOTE: The IP of this machine will be publicly logged as having requested this
#certificate. If you're running certbot in manual mode on a machine that is not
#your server, please ensure you're okay with that.
#
#Are you OK with your IP being logged?
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#(Y)es/(N)o: Y
#
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Please deploy a DNS TXT record under the name
#_acme-challenge.aws.binbash.com.ar with the following value:
#
#80qTudlm4iGgkVSAjCzYKw1YScPXYLlQPwxnNI6l0YE
#
#Before continuing, verify the record is deployed.
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Press Enter to Continue
#Waiting for verification...
#Cleaning up challenges
#
#IMPORTANT NOTES:
# - Congratulations! Your certificate and chain have been saved at:
#   /etc/letsencrypt/live/aws.binbash.com.ar/fullchain.pem
#   Your key file has been saved at:
#   /etc/letsencrypt/live/aws.binbash.com.ar/privkey.pem
#   Your cert will expire on 2019-06-26. To obtain a new or tweaked
#   version of this certificate in the future, simply run certbot
#   again. To non-interactively renew *all* of your certificates, run
#   "certbot renew"
# - Your account credentials have been saved in your Certbot
#   configuration directory at /etc/letsencrypt. You should make a
#   secure backup of this folder now. This configuration directory will
#   also contain certificates and private keys obtained by Certbot so
#   making regular backups of this folder is ideal.
# - If you like Certbot, please consider supporting our work by:
#
#   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
#   Donating to EFF:                    https://eff.org/donate-le

