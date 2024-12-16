#!/usr/bin/env lua
--[===========================================================================[

  Prints Provisioning (POSIX shell) script for "paisa-workhorse" to stdout.

  Intended to be used with "http://devuan.org/".

  ]===========================================================================]
-- Customize your install here ------------------------------------------------
-- TODO Make sure to insert your roles, etc here BEFORE use.

local awsRole = "arn:aws:iam::_TODO______56:role/Z-AWS-_TODO___01-DE"
-- UNUSED local awsNamespace = "_TODO_-snapshot"
local samlUser = "_TODO_max_._TODO_muster_@post.ch" -- WARN: saml deprecated!
local samlMultiFactorAuthType = "RSA"  -- TODO no idea which other options we have here.
local yourPhysicalHostname = "w00o2z"
local proxy_url = "http://10.0.2.2:3128/"
local proxy_no  = "localhost,pnet.ch,post.ch,tools.post.ch,gitit.post.ch,pnetcloud.ch,eu-central-1.eks.amazonaws.com,"..assert(yourPhysicalHostname)

-- Values from here onwards usually are ok as-is.
local cmdSudo = "sudo"
local samlProfile = "default" -- WARN: saml deprecated!
local awsRegion = "eu-central-1"
local idProvider = "ADFS2"
local samlVersion = "2.36.16"
local argocdVersion = "2.11.7"
local getaddrinfoVersion = "0.0.2"
local cacheDir = "/var/tmp"

-- EndOf Customization --------------------------------------------------------

local main


function main()
    local dst = io.stdout
    dst:write("#!/bin/sh\nset -e\n")
    dst:write([=[true \
  && samlUser=']=].. samlUser ..[=[' \
  && samlMfa=']=].. samlMultiFactorAuthType ..[=[' \
  && samlProfile:=']=].. samlProfile ..[=[ \'
  && samlVersion=']=].. samlVersion ..[=[' \
  && awsRole=']=].. awsRole ..[=[' \
  && awsRegion=']=].. awsRegion ..[=[' \
  && IDPPROVIDER=]=].. idProvider ..[=[ \
  && yourPhysicalHostname=']=].. yourPhysicalHostname ..[=[' \
  && proxy_url=']=].. proxy_url ..[=[ \'
  && proxy_no=']=].. proxy_no ..[=[ \'
  && argocdVersion=']=].. argocdVersion ..[=[' \
  && getaddrinfoVersion=']=].. getaddrinfoVersion ..[=[' \
  && cacheDir=']=].. cacheDir ..[=[' \
  && SUDO=']=].. cmdSudo ..[=[ \'
  && `# 20240715: Removed: gcc-mingw-w64-x86-64-win32 gcc libc6-dev` \
  && printf %s\\n \
        "no_proxy=${proxy_no?}" \
        "https_proxy=${proxy_url:?}" \
        "http_proxy=${http_proxy:?}" \
        "NO_PROXY=${proxy_no?}" \
        "HTTPS_PROXY=${proxy_url:?}" \
        "HTTP_PROXY=${proxy_url:?}" \
     | $SUDO tee >/dev/null -a /etc/environment \
  && if test ! -e /etc/apt/apt.conf.d/80proxy ;then true \
      && printf %s\\n \
            'Acquire::http::proxy "'"${http_proxy:?}"'";' \
            'Acquire::https::proxy "'"${proxy_url:?}"'";' \
         | $SUDO tee >/dev/null -a /etc/apt/apt.conf.d/80proxy \
    ;fi \
  && `# Add some swap ` \
  && SWAP_MIB=$((12*1024)) \
  && $SUDO dd if=/dev/zero of=/swapfile1 bs=$((1024*1024)) count="${SWAP_MIB:?}" \
  && $SUDO chmod 0600 /swapfile1 \
  && $SUDO mkswap /swapfile1 \
  && printf '/swapfile1  none  swap  sw,pri=10  0  0\n' | $SUDO tee > /dev/null -a /etc/fstab \
  && `# Install packages ` \
  && $SUDO apt update \
  && $SUDO RUNLEVEL=1 apt install -y --no-install-recommends \
         net-tools vim curl nfs-common htop ncat git ca-certificates tmux \
         kubernetes-client awscli openjdk-17-jre-headless maven podman \
  && (cd "${cacheDir:?}" && curl -Lo "getaddrinfo-${getaddrinfoVersion:?}+x86_64-linux-gnu.tgz" "https://github.com/hiddenalpha/getaddrinfo-cli/releases/download/v${getaddrinfoVersion:?}/getaddrinfo-${getaddrinfoVersion:?}+x86_64-linux-gnu.tgz") \
  && (cd "${cacheDir:?}" && curl -o saml2aws_${samlVersion:?}_linux_amd64.tgz "https://artifactory.tools.post.ch/artifactory/generic-github-remote/Versent/saml2aws/releases/download/v${samlVersion:?}/saml2aws_${samlVersion:?}_linux_amd64.tar.gz") \
  && (cd "${cacheDir:?}" && curl -Lo "argocd-${argocdVersion:?}+linux-amd64" "https://github.com/argoproj/argo-cd/releases/download/v${argocdVersion:?}/argocd-linux-amd64") \
  && mkdir -p ~/.local/bin \
  && $SUDO mkdir -p "/opt/getaddrinfo-${getaddrinfoVersion:?}" "/opt/argocd-${argocdVersion:?}/bin" \
  && (cd /opt/getaddrinfo-${getaddrinfoVersion:?} && $SUDO tar xf "${cacheDir:?}/getaddrinfo-${getaddrinfoVersion:?}+x86_64-linux-gnu.tgz") \
  && (cd ~/.local/bin && ln -s "/opt/getaddrinfo-${getaddrinfoVersion:?}/bin/getaddrinfo") \
  && $SUDO mkdir "/opt/saml2aws_${samlVersion:?}" "/opt/saml2aws_${samlVersion:?}/bin" \
  && (cd /opt/saml2aws_${samlVersion:?}/bin && $SUDO tar xf "${cacheDir:?}"/saml2aws_${samlVersion:?}_linux_amd64.tgz -- saml2aws) \
  && (cd /opt/argocd-${argocdVersion:?}/bin && $SUDO cp "${cacheDir:?}/argocd-${argocdVersion:?}+linux-amd64" .) \
  && $SUDO chmod 0655 "/opt/argocd-${argocdVersion:?}/bin/argocd-${argocdVersion:?}+linux-amd64" \
  && (cd ~/.local/bin && ln -s /opt/saml2aws_${samlVersion:?}/bin/saml2aws) \
  && (cd ~/.local/bin && ln -s /opt/argocd-${argocdVersion:?}/bin/argocd-${argocdVersion:?}+linux-amd64 argocd) \
  && (printf 'export PATH="%s/.local/bin:$PATH"\n' ~) >> ~/.bashrc \
  && export PATH="/home/${USER?}/.local/bin:$PATH" \
  && $SUDO mkdir -p /c && $SUDO ln -s /mnt/cdrive/work /c/work \
  && $SUDO mkdir /mnt/cdrive \
  && (printf '/mnt/cdrive/work  /c/work  none  noauto,bind,user  0  0\n') | $SUDO tee -a /etc/fstab >/dev/null \
  && (printf '10.0.2.2:/c  /mnt/cdrive  nfs  noauto,vers=3,user  0  0\n') | $SUDO tee -a /etc/fstab >/dev/null \
  && saml2aws configure --skip-prompt -p "${samlProfile:?}" --role="${awsRole?}" --region "${awsRegion?}" --url https://adfs.post.ch --username "${samlUser?}" --idp-provider="${IDPPROVIDER?}" --mfa="${samlMfa?}" \
  && printf 'MAVEN_OPTS="--add-opens jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-opens jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-opens jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED --add-opens jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-opens jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.base/java.text=ALL-UNNAMED --add-opens java.desktop/java.awt.font=ALL-UNNAMED"' | $SUDO tee >/dev/null -a /etc/environment \
  && `# kubectl (https://wikit.post.ch/x/w52aS#ISAK8sSetup-K8s/ArgoCDconfiguration) ` \
  && mkdir "/home/${USER:?}/.aws" \
  && `# Minimal pseudo README with in VM ` \
  && printf %s\\n \
       '' \
       '  PaISA Workhorse Notes' \
       '  =====================' \
       '' \
       '  sudo podman pull docker.tools.post.ch/paisa/r-service-base:03.06.42.00' \
       '  sudo podman pull docker.tools.post.ch/library/amazonlinux:2023.6.20241121.0' \
       '' \
       '  TODO: Remove "saml2aws" because DEPRECATED. See:' \
       '  - [saml is dead](https://wikit.post.ch/x/0Fu4Vg)' \
       '  - [Maybe saml2aws becomes obsolete](https://wikit.post.ch/display/CDAF/How+to%3A+Setup-Guide+saml2aws?focusedCommentId=1741722098&src=mail&src.mail.product=confluence-server&src.mail.timestamp=1721914205401&src.mail.notification=com.atlassian.confluence.plugins.confluence-notifications-batch-plugin%3Abatching-notification&src.mail.recipient=8a81e4a6427b972601427b98b9262c20&src.mail.action=view#comment-1741722098)' \
       '' \
       '  TODO: Fix broken AWS/kubectl/argocd Döns' \
       '' \
     | tee /home/${USER:?}/README.txt \
  && printf '\n  DONE. Setup completed.\n\n' \
]=])
end


main()

