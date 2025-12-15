FROM ubuntu:24.04

# Set non-interactive mode for timezone selection
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone (Australia/Melbourne)
RUN apt-get update --fix-missing && \
    apt-get install -y tzdata && \
    echo "Australia/Melbourne" > /etc/timezone && \
    ln -fs /usr/share/zoneinfo/Australia/Melbourne /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Install OpenStack CLI tools
RUN apt-get install -y python3-openstackclient

# Install openstack modules as needed
RUN apt-get install -y python3-neutronclient
RUN apt-get install -y python3-octaviaclient
RUN apt-get install -y python3-barbicanclient
RUN apt-get install -y python3-osc-placement
RUN apt-get install -y python3-designateclient

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update
# Get required tools
RUN apt-get install curl jq bash-completion -y
RUN touch /root/.bash_history
RUN echo '[[ $- == *i* ]] && source /usr/share/bash-completion/bash_completion' >> /root/.bashrc
RUN echo 'source /usr/share/bash-completion/completions/openstack' >> /root/.bashrc
RUN echo 'echo ""' >> /root/.bashrc
RUN echo 'echo "#################################################################################"' >> /root/.bashrc
RUN echo 'echo "#                     run "source openrc.sh" to get started                     #"' >> /root/.bashrc
RUN echo 'echo "#################################################################################"' >> /root/.bashrc
# Set working directory
WORKDIR /root

# Copy openrcfiles
COPY ./openrc.sh /root/openrc.sh

# Start with an interactive shell
CMD ["/bin/bash"]
