FROM ubuntu:22.04
LABEL maintainer="Vito Sabella <vito@axon.com>"

ARG UBUNTU="22.04"
ARG terraform_version="1.2.1"
ARG terraform_transform_version="0.2.2"
ARG terragrunt_version="v0.38.6"
ARG kubectl_version="v1.23.6"
ARG helm3_version="v3.9.0"
ARG istioctl_version="1.13.4"
ARG argocd_version="v2.3.4"
ARG tflint_version="v0.36.2"
ARG sops_version="v3.7.3"
ARG kustomize_version="v4.5.5"
ARG yq_version="v4.27.2"
ARG ruamel_yaml_version="0.17.21"
ARG ghcli_version="2.14.3"

#######################
# Axon Minimal Kubernetes Tools
# Managed by #ptps squad
#######################

####################
# APT UPDATE (Ubuntu)
####################
# https://ubuntu.com/blog/we-reduced-our-docker-images-by-60-with-no-install-recommends

RUN apt-get update -qq \
    && DEBIAN_FRONTEND="noninteractive" TZ=America/Seattle \
    apt-get install --no-install-recommends -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    direnv \
    dnsutils \
    jq \
    less \
    netcat \
    openssl \
    gnutls-bin \
    passwd \
    pwgen \
    ssh \
    unzip \
    wget \
    zsh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

####################
# Terraform
####################
RUN git clone https://github.com/tfutils/tfenv.git /opt/tfenv \
    && ln -s /opt/tfenv/bin/* /usr/local/bin

RUN tfenv install ${terraform_version} \
    && tfenv use ${terraform_version} \
    && chmod -R 0777 /opt/tfenv

# instead of building a filesystem mirror in /usr/local/share/terraform/plugins using terraform-provider-sets as a set of
# valid terraform files with set of terraform { required_providers { .. } block, we instead pre-seed the TF_PLUGIN_CACHE_DIR
# this avoids us having to pre-seed all versions we'll ever need (filesystem mirrors are designed for air-gapped installs)
ENV TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
COPY terraform-provider-sets /tmp/terraform-provider-sets
RUN mkdir -p $TF_PLUGIN_CACHE_DIR
RUN for p in $(ls /tmp/terraform-provider-sets/); do cd /tmp/terraform-provider-sets/$p ; terraform init ; cd - ; done ; rm -rf /tmp/terraform-provider-sets/


####################
# Terragrunt
####################
ENV TERRAGRUNT_PARALLELISM=1
RUN wget -nv https://github.com/gruntwork-io/terragrunt/releases/download/${terragrunt_version}/terragrunt_linux_amd64 -O /usr/local/bin/terragrunt \
    && chmod +x /usr/local/bin/terragrunt

# Use the Real YQ (kislyuk/yq is not correct YQ)
####################
RUN wget -nv https://github.com/mikefarah/yq/releases/download/${yq_version}/yq_linux_amd64 -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

ENTRYPOINT ["/bin/zsh"]
