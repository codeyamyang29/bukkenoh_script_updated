#!/usr/bin/env bash
#script dir
_SCRIPT_DIR=$(pwd)
#global file
_CONFIG_DIR=$_SCRIPT_DIR'/configs'
_CFG=$_SCRIPT_DIR'/configs/cfg.txt'
_HTACCESS=$_SCRIPT_DIR'/configs/htaccess.txt'
_ENV=$_SCRIPT_DIR'/configs/env.txt'
_TMP_ENV=$_SCRIPT_DIR'/configs/tmp.txt'
#inputs 
_REPO_HTTP='-'
_ENV_U_ID='0'
_ENV_S_ID='0'
#global init
_ROOT_LARAGON='-'
_ROOT_WEB_SERVE='-'
_ROOT_PHP_BIN='-'
_REPO_NAME='-'
_SAVE_LOC='-'
_COMPOSER_LOC='-'
_SRC_LOC='-'
function alertSeperator() {
    echo ""
    echo "****************************************************************"
    echo "*" $1 "$2"
    echo "****************************************************************"
    return 0
}
function promptInput(){
    echo $1
    read $2
}
function checkRequirements(){
    php -v > /dev/null 2>&1
    PHP_IS_INSTALLED=$?
    composer -v > /dev/null 2>&1
    COMPOSER_IS_INSTALLED=$?
    yarn -v > /dev/null 2>&1
    YARN_IS_INSTALLED=$?
    perl -v > /dev/null 2>&1
    PERL_IS_INSTALLED=$?

    [[ $COMPOSER_IS_INSTALLED -ne 0 && $PHP_IS_INSTALLED -ne 0 && $YARN_IS_INSTALLED -ne 0 && $PERL_IS_INSTALLED -ne 0 ]] && { printf "\nPlease check if php, composer, yarn and perl is installed. Try running ex. php -v \nScript aborted!!!!!!!!!!!!!!! \n"; exit 0; }

    local CURRENT_PHP_VERSION=$?
    local CURRENT_PHP_VERSION_SUB=$?
    CURRENT_PHP_VERSION=$(php -v | head -n 1 | cut -d " " -f 2 | cut -d "." -f1)
    CURRENT_PHP_VERSION_SUB=$(php -v | head -n 1 | cut -d " " -f 2 | cut -d "." -f2)
    if [[ $CURRENT_PHP_VERSION -eq 8 && $CURRENT_PHP_VERSION_SUB -ge 0 && $CURRENT_PHP_VERSION_SUB -le 2 ]]; then
        printf "\nPHP Version is correct! \ncontinuing.....\n"
    else
        printf "PHP required: 8.0 ~ 8.2 \n";
        exit 0;
    fi
    local CURRENT_NODE_VERSION=$?
    CURRENT_NODE_VERSION=$(node -v)
    if [ $CURRENT_NODE_VERSION = "v8.15.0" ]; then
        printf "\nNode Version is correct! \ncontinuing.....\n"
    else
        printf "Node required: v8.15.0 \n";
        exit 0;
    fi
}
function readConfig() {
    _ROOT_LARAGON=$(grep -E -i 'laragon=' $1 | cut -d '=' -f2)
    _ROOT_WEB_SERVE=$(grep -E -i 'webdocs=' $1 | cut -d '=' -f2)
    _ROOT_PHP_BIN=$(grep -E -i 'php=' $1 | cut -d '=' -f2)
    return 0
}
function extractRepoName(){
    _REPO_NAME=$(echo $1 | cut -d'/' -f6) # get repo name
    _REPO_NAME=${_REPO_NAME/.git/} #remove .git
    generateLink $_REPO_NAME # call generatelink()
    return 0
}
function generateLink(){
    _SAVE_LOC=$_ROOT_WEB_SERVE'\'$1 
    _COMPOSER_LOC=$_SAVE_LOC'\laravel'
    _SRC_LOC=$_SAVE_LOC'\src'
    return 0
}
function gitClone(){
    alertSeperator "Cloning Git to" $_ROOT_WEB_SERVE
    if [ ! -d $_SAVE_LOC ]; then
        $(cd $_ROOT_WEB_SERVE && git clone $_REPO_HTTP)
    else
        printf "Repository exists:  $_SAVE_LOC \n\n" 
    fi
    return 0
}
function runComposerUpdate(){
    alertSeperator "Run Composer update to:" $_COMPOSER_LOC
    if [ -d $_COMPOSER_LOC ]; then
        cd $_COMPOSER_LOC && composer update -v
    else
        echo "laravel folder could not be found:" $_COMPOSER_LOC
    fi
    return 0
}
function runComposer(){
    alertSeperator "Run Composer install to:" $_COMPOSER_LOC
    if [ -d $_COMPOSER_LOC ]; then
        cd $_COMPOSER_LOC && composer install -v
    else
        echo "laravel folder could not be found:" $_COMPOSER_LOC
    fi
    return 0
}
function yarnInstall(){
    alertSeperator "Run Yarn install to:" $_SRC_LOC
    if [ -d $_SRC_LOC ]; then
        cd $_SRC_LOC && yarn install --silent
    else
        echo "src folder could not be found:" $_SRC_LOC
    fi
    return 0
}
function copyHtaccess(){
    alertSeperator "Copy htaccess to:" $_SAVE_LOC
    if [ -d $_SAVE_LOC ]; then
        cd $_SAVE_LOC && cp $_HTACCESS .htaccess
    else
        echo 'Repository is missing.'
    fi
    return 0
}
function setupEnv(){
    alertSeperator "Setup Env to:" $_COMPOSER_LOC
    if [ -d $_COMPOSER_LOC ]; then
        promptInput "User ID:" _ENV_U_ID
        promptInput "Store ID:" _ENV_S_ID
        #create new temp file
        cd $_SCRIPT_DIR'/configs' && cp $_ENV 'tmp.txt'
        perl -pi -e "s/USER_ID=\d+/USER_ID=$_ENV_U_ID/g" $_TMP_ENV 
        perl -pi -e "s/STORE_ID=\d+/STORE_ID=$_ENV_S_ID/g" $_TMP_ENV
        cd $_COMPOSER_LOC && cp $_TMP_ENV '.env'
        #delete temp after copying to project file
        [ ! -f $_TMP_ENV ] || rm $_TMP_ENV
    else
        echo "laravel folder could not be found:" $_COMPOSER_LOC
    fi
    return 0
}
function restartLaragon(){
    alertSeperator "Restarting:" "Laragon Service"
    taskkill //IM "laragon.exe" //T //F
    echo ""
    cd $_ROOT_LARAGON && start "laragon.exe"
    return 0   
}
function openToWeb(){
    alertSeperator "Opening in URL:" "http://$_REPO_NAME.test/cmd/makecache"
    start "http://$_REPO_NAME.test/cmd/makecache"
    return 0
}
function execute(){
    checkRequirements #check if php and composer are installed
    readConfig $_CFG
    alertSeperator "Please Enter Neccessary Value"
    promptInput "Git Http link:" _REPO_HTTP
    extractRepoName $_REPO_HTTP #strip and extract repo name from link
    gitClone
    runComposer
    runComposerUpdate
    yarnInstall
    copyHtaccess
    setupEnv
    restartLaragon
    # openToWeb
    return 0
}
#execute all command
execute
# displayVariables
#ending
# read -p "Press enter to continue"
# read -p "Are you sure to exit? " -n 1 -r
# echo    # (optional) move to a new line
# if [[ ! $REPLY =~ ^[Yy]$ ]]
# then
#     [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
# fi