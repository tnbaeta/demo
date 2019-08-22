
#!/bin/bash
set -e


#################BEGIN VARIABLES NEEDED IN GIT SCRIPT########################


####EXAMPLE VARIABLES PLEASE REPLACE
ad_user='[ad_user]'
ad_password='[ad_password]'
export ad_user
export ad_password

#################END VARIABLES NEEDED IN GIT SCRIPT##########################


#######################BEGIN GIT BOILERPLATE SCRIPT##########################

git clone http://'[git_user]':'[git_password]'@'[git_server]'/vcac-services/'[git_repo]'.git scripts
cd scripts
if ! git checkout tags/'[git_repo_tag_version]' &>/dev/null; then
  echo "ERROR: The requested tag name was not found."
  if [ $(git tag -l | wc -l) -eq 0 ]; then
    echo "ERROR: The git repository does not have any tags defined"
  else
    echo ""
    echo "The following valid tags are defined for this repository:"
    git tag -l
    echo ""
  fi
fi
git checkout tags/'[git_repo_tag_version]'
cd ..
. scripts/'[git_script]'
rm -rfv scripts

##########################END GIT BOILERPLATE SCRIPT##########################