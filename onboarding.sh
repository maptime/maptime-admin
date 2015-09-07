#!/bin/sh -e
# ------------------------------------------------------------------------------------------------------ 
# onboarding - Maptime onboarding tool
# 
# Bash script to assist in the Maptime onboarding process on Github.
# Before running, user must have a Github personal access token
# saved in an environment variable named GH_TOKEN
# Requires jq for json parsing.  See: http://stedolan.github.io/jq/download/ 

abort()
{
    echo >&2 '
***************
*** ABORTED ***
***************
'
    echo "An error occurred. Exiting..." >&2
    exit 1
}

trap 'abort' 0

set -e

echo "Repo name. Enter the Maptime chapter repo name (e.g. portland). Make sure it doesn't conflict with existing repos and is all lowercase:"
read chapter

echo "Admin team. Enter the abbreviations for country and/or state/province (e.g. us-ny for USA, New York): "
read team

echo "Enter the admin GitHub username: "
read admin

curl -H "Content-Type: application/json" \
	-u ${GH_TOKEN}:x-oauth-basic https://api.github.com/orgs/maptime/repos \
	-X POST -d "{\"name\":\"$chapter\",\"description\":\"Repo for Maptime $chapter\"}"

tempdir=$(mktemp -dt "starter.XXXXXXXXXX")
git clone git@github.com:maptime/starter.git $tempdir
cd $tempdir
git remote add local git@github.com:maptime/${chapter}.git
git push local gh-pages

id=$(curl -H "Content-Type: application/json" \
	-u ${GH_TOKEN}:x-oauth-basic https://api.github.com/orgs/maptime/teams \
	-d "{\"name\":\"${team}\",\"permission\":\"push\",\"repo_names\":[\"maptime/${chapter}\"]}" \
	| jq -r '.id')

curl -u ${GH_TOKEN}:x-oauth-basic -X PUT https://api.github.com/teams/${id}/memberships/${admin}

trap : 0

echo >&2