FROM registry.suse.com/bci/bci-base:latest

RUN zypper in -y jq docker && zypper clean

COPY run-scan.sh /usr/bin

ENTRYPOINT ["/usr/bin/run-scan.sh"]
