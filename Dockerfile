FROM alpine/git:v2.26.2

ENV TERRAFORM_VERSION=0.13.5

RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/ \
    && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

WORKDIR /terraform

ENTRYPOINT ["/bin/sh","-c"]
