# TOTP capable openstack client for mcloud
## A public repository for us to share a boilerplate openrc.sh which works with TOTP enabled users.
This script is based off the Openstack OpenRC files, and is designed for users who have multifactor authentication configured to be able to use the CLI without too much pain.

This has been tested on Ubuntu 22 and Ubuntu 24, but should work on any system with a running docker engine

At this stage, there is limited error handling; use with care, and pay attention to output during the setup.

### Use and Attributions
This script is completely open use. Feel free to fork or copy. No attributions are required, however, if you make improvements, feel free to make suggestions.

# Prerequisites
- Familiarity with `docker` and editing scripts to fill in your own configuration.
- An internet connection.
- Your project name and project-id from mcloud, as well as a working user.
  - You can check this information by logging in at https://mcloud.micron21.com and clicking the "API Access" link, under "Project".
  - Click "Download Openstack RC File" or copy the ID from on screen.

# Setup
* Clone this repository: `git clone https://github.com/micron21/totp-capable-openstack-client-for-mcloud`
* CD into the directory; ensure you can see the Dockerfile
* Optionally, to have a persistent history create the file: `touch .mcloud_history` 
* Edit the openrc.sh to have your project ID and project Name. Optionally, set the username.
* Save the openrc.sh file with your settings.
* Create the openstack-client image using docker: `docker build -t openstack-client .`
  * **Note:** if you make any changes to the dockerfile or openrc.sh, you will need to repeat this step.
  * **Note:** the first time you run this, it might take a few minutes to download all the prerequisites used by the container.
* When it is ready, launch the image with the below command:

# Launch the Openstack Client
Once you have run the setup for the first time, you can proceed from here every time, unless you want to make changes to the setup.
* With History:
`docker run --rm --net=host -v ./.mcloud_history:/root/.bash_history -ti openstack-client bash`
* Without History:
`docker run --rm --net=host -ti openstack-client bash`

# Using the Client
From within the container, load the profile with the command:
`source openrc.sh`

It will prompt you for your username (unless you altered the configuration earlier), password, and then your TOTP.

If the authentication is successful, it will collect an OpenStack TOKEN which will remain valid for 1 hour. The token is only saved in memory; if you exit the client, the token cannot be retrieved.

Once you have run the openrc.sh and successfully authenticated, you can use all commands available to your user in the openstack client; such as:
```
openstack server list
openstack quota show --usage "$OS_PROJECT_NAME"
```
Other openstack client commands can be found by running
```
openstack help
# or
openstack {command} help
# or
openstack {command} {subcommand} help
```
or using search engines looking for documentation at openstack.org.

# Cleaning up when you're done
Running `exit` from the container will exit the container, and it will delete itself. The only persistent thing is the history, if you are using the history file.

If you do not want the container to clean itself up, you can drop the `--rm` flag; and then get back into the container with `docker exec -it {container-name} bash`. You can also optionally name your container.

# Security considerations
On a docker enabled host, any user with docker privileges can exec into your container, and may be able to access your session.

Additionally, because of the way this client uses the host network, this docker container is fairly privileged; it is recommended that appropriate measures are taken to ensure these containers aren't run in shared spaces, as other privileged users of the host may be able to access your data in transit.

A docker container is only used because it is a reliable way to lock the openstack version number, python version, and a few other key requirements; you can use the openrc.sh script outside of a docker container if you are willing to set up the OpenStack client to the same specifications; you can see what exactly is required by reviewing the Dockerfile.

# Feedback and Support
Please direct all feedback and support enquiries to support@micron21.com
