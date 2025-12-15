#!/usr/bin/env bash
# To use an OpenStack cloud you need to authenticate against the Identity
# service named keystone, which returns a **Token** and **Service Catalog**.
# The catalog contains the endpoints for all services the user/tenant has
# access to - such as Compute, Image Service, Identity, Object Storage, Block
# Storage, and Networking (code-named nova, glance, keystone, swift,
# cinder, and neutron).
#

###############################
## Project Specific Settings ##
## Alter this to use your    ##
## project's ID and Name.    ##
## Domain Name should not    ##
## need to be altered        ##
###############################

export OS_PROJECT_ID=1234567890abcdefghijklmnopqrstuv
export OS_PROJECT_NAME="your-project-name"

# Leave these alone, unless you're sure you need to change them
export OS_USER_DOMAIN_NAME="mcloud"
if [ -z "$OS_USER_DOMAIN_NAME" ]; then unset OS_USER_DOMAIN_NAME; fi
export OS_PROJECT_DOMAIN_ID="3fa55313870f4d928a52820d52c289b3" # mcloud domain ID is 3fa55313870f4d928a52820d52c289b3
if [ -z "$OS_PROJECT_DOMAIN_ID" ]; then unset OS_PROJECT_DOMAIN_ID; fi

###############################
## Pre Run Checks            ##
###############################

if ! command -v jq >/dev/null 2>&1
then
    echo "jq could not be found, is required for this script to function. Please install jq, or make jq available in the \$PATH"
    exit 1
else
    echo "jq found. Proceeding..."
fi

if echo "$OS_TOKEN_ISSUE" | jq -e 'has("expires")' >/dev/null; then
    # We already have a token in memory, lets see if it's still valid
    EXPIRES=$(echo "$OS_TOKEN_ISSUE" | jq -r '.expires')
    EXPIRES_EPOCH=$(date -d "$EXPIRES" +%s)
    NOW_EPOCH=$(date +%s)
    MIN_LEFT=$((10 * 60))  # 10 minutes in seconds
    
    if (( EXPIRES_EPOCH - NOW_EPOCH > MIN_LEFT )); then
        echo "Token is valid until $EXPIRES. Not generating a new one."
        echo "If you are experiencing issues with this token, run `unset OS_TOKEN_ISSUE`"
        exit 1
    else
        echo "Token will expire in less than 10 minutes or already expired, generating a new token..."
    fi
else
    echo "A new token is required..." >&2
fi

###############################
## Application Settings      ##
###############################
## Note: you may alter the   ##
## username to be fixed      ##
###############################

export OS_AUTH_URL=https://mcloud.micron21.com:5000
export AUTH_URL=https://mcloud.micron21.com:5000
export OS_AUTH_TYPE="v3multifactor"
export OS_AUTH_METHODS="v3password,v3totp"
export OS_REGION_NAME="RegionOne"
if [ -z "$OS_REGION_NAME" ]; then unset OS_REGION_NAME; fi
export OS_INTERFACE=public
export OS_IDENTITY_API_VERSION=3

# OS_USERNAME="" # Uncomment this field and enter the username, if that would be more convenient.
if [ -z "$OS_USERNAME" ]; then
        echo "Enter the Users Username:"
        read -rp OS_USERNAME_INPUT
        export OS_USERNAME=$OS_USERNAME_INPUT
else
        echo "Username already set - $OS_USERNAME"
fi

# OS_PASSWORD="" # Uncomment this field and enter the password. Note that this is very insecure.
if [ -z "$OS_PASSWORD" ]; then
        echo "Enter the Users Password (input will not be shown):"
        read -srp OS_PASSWORD_INPUT
        export OS_PASSWORD=$OS_PASSWORD_INPUT
else
        echo "Password already set..."
fi

# TOTP Passcode. This can't be baked in because it changes, although if you're brave you could use a 3rd party library and enter your secret here and have that generated for you. Note that this would be incredibly insecure.
echo "Enter the MFA TOTP 6 digit passcode:"
read -rp OS_PASSCODE_INPUT
export OS_PASSCODE=$OS_PASSCODE_INPUT

# Using the information provided, we get the Openstack Token using the client
OS_TOKEN_ISSUE=$(openstack token issue -f json 2>&1) || {
    echo "Error: Failed to get token:" >&2
    echo "$OS_TOKEN_ISSUE" >&2
    exit 1
}
# check for a token, and save the token to variable if it exists
if echo "$OS_TOKEN_ISSUE" | jq -e 'has("id")' >/dev/null; then
    OS_TOKEN_ID=$(echo "$OS_TOKEN_ISSUE" | jq -r '.id')
else
    echo "Error: OS_TOKEN_ISSUE has no id field, authentication probably failed." >&2
    echo "Output was:" >&2
    echo "$OS_TOKEN_ISSUE" >&2
    exit 1
fi

# update the auth method to token
export OS_TOKEN=$OS_TOKEN_ID
export OS_AUTH_TYPE="v3token"
# unset the other variables not required for Token Auth
unset OS_AUTH_METHODS
unset OS_PASSCODE
unset OS_USER_DOMAIN_NAME
unset OS_PASSWORD # This doesn't have to be removed, but no point keeping an unecrypted password in memory. You can comment this line if you leave the client open for hours, and want your session to retain the password in memory.
#unset OS_USERNAME

# If we got this far, it probably worked, let the user know
echo "Authentication complete with token:"
echo "$OS_TOKEN"
echo ""
echo "If that token doesn't look right, or openstack commands don't work, review your authentication information, and check the README for any missed steps."
echo "Happy OpenStacking!"
