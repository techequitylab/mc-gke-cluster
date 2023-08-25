#!/bin/bash
# 
# Copyright 2019-2021 Shiyghan Navti. Email shiyghan@techequity.company
#
#################################################################################
##############        Explore GKE Multicloud Cluster CI/CD       ################
#################################################################################

function ask_yes_or_no() {
    read -p "$ $1 ([y]yes to preview, [n]o to create, [d]del to delete): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        n|no)  echo "no" ;;
        d|del) echo "del" ;;
        *)     echo "yes" ;;
    esac
}

function ask_yes_or_no_proj() {
    read -p "$ $1 ([y]es to change, or any key to skip): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}

clear
MODE=1
export TRAINING_ORG_ID=$(gcloud organizations list --format 'value(ID)' --filter="displayName:techequity.training" 2>/dev/null)
export ORG_ID=$(gcloud projects get-ancestors $GCP_PROJECT --format 'value(ID)' 2>/dev/null | tail -1 )
export GCP_PROJECT=$(gcloud config list --format 'value(core.project)' 2>/dev/null)  

echo
echo
echo -e "                        👋  Welcome to Cloud Sandbox! 💻"
echo 
echo -e "              *** PLEASE WAIT WHILE LAB UTILITIES ARE INSTALLED ***"
sudo apt-get -qq install pv > /dev/null 2>&1
echo 
export SCRIPTPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "Enter the cloud platform (GCP | AZURE | AWS)" | pv -qL 100
read PLATFORM
while [[ "${PLATFORM^^}" != "AWS" ]] && [[ "${PLATFORM^^}" != "AZURE" ]] && [[ "${PLATFORM^^}" != "GCP" ]]; do 
    echo "Enter the cloud platform. Valid options are AWS, AZURE or GCP" | pv -qL 100
    read PLATFORM
done

mkdir -p $HOME/mc-gke-cluster/${PLATFORM^^} > /dev/null 2>&1
export PROJDIR=$HOME/mc-gke-cluster/${PLATFORM^^}
export ENVDIR=$HOME/mc-gke-cluster
export SCRIPTNAME=mc-gke-cluster.sh

if [[ "${PLATFORM^^}" == "AWS" ]] ; then 
    if command -v $PROJDIR/aws/aws >/dev/null 2>&1; then
        echo
        echo "*** AWS CLI available ***"
    else
        echo
        echo "*** AWS CLI has not been installed ***"
    fi
elif [[ "${PLATFORM^^}" == "AZURE" ]] ; then 
    if command -v /usr/bin/az >/dev/null 2>&1; then
        echo
        echo "*** Azure CLI available ***"
    else
        echo
        echo "*** Azure CLI has not been installed ***"
    fi
elif [[ "${PLATFORM^^}" == "GCP" ]] ; then 
    if command -v gcloud >/dev/null 2>&1; then
        echo
        echo "*** gcloud SDK available ***"
    else
        echo
        echo "*** gcloud SDK has not been installed ***"
    fi
fi

if [ -f "$ENVDIR/.env" ]; then
    source $ENVDIR/.env
else
cat <<EOF > $ENVDIR/.env
export GCP_PROJECT=$GCP_PROJECT
export GCP_REGION=europe-west1
export GCP_ZONE=europe-west1-b
export CLUSTER_VERSION=1.25.5-gke.1500
export AWS_LOCATION=us-east4 
export AWS_REGION=us-east-1
export AWS_NODE_TYPE=t3.xlarge
export AZURE_LOCATION=eastus
export AZURE_NODE_TYPE=Standard_DS3_v2
export SERVICEMESH_VERSION=1.16.2-asm.2
export APPLICATION_NAME=hello-app
EOF
source $ENVDIR/.env
fi

while :
do
clear
case ${PLATFORM^^} in
    AWS)
        cat<<EOF
==============================================
Configure GKE on AWS
----------------------------------------------
Please enter number to select your choice:
 (1) Set cloud platform
 (2) Download SDK
 (3) Authenticate to cloud
 (4) Configure environment
 (5) Create GKE cluster on AWS
 (6) Configure IAM policies
 (7) Configure service mesh
 (8) Configure application
 (9) Configure application artifacts
(10) Configure CI/CD artifacts
 (G) Launch user guide
 (Q) Quit
----------------------------------------------
EOF
    ;;
    AZURE)
        cat<<EOF
==============================================
Configure GKE on Azure
----------------------------------------------
Please enter number to select your choice:
 (1) Set cloud platform
 (2) Download SDK
 (3) Authenticate to cloud
 (4) Configure environment
 (5) Create GKE cluster on Azure
 (6) Configure IAM policies
 (7) Configure service mesh
 (8) Configure application
 (9) Configure application artifacts
(10) Configure CI/CD artifacts
 (G) Launch user guide
 (Q) Quit
----------------------------------------------
EOF
    ;;
    GCP)
        cat<<EOF
==============================================
Configure GKE on GCP
----------------------------------------------
Please enter number to select your choice:
 (1) Set cloud platform
 (2) Download SDK
 (3) Authenticate
 (4) Configure environment
 (5) Create GKE cluster on GCP
 (6) Configure IAM policies
 (7) Configure service mesh
 (8) Configure application
 (9) Configure application artifacts
(10) Configure CI/CD artifacts
 (G) Launch user guide
 (Q) Quit
----------------------------------------------
EOF
    ;;
esac
echo "Steps performed${STEP}"
echo
echo "What additional step do you want to perform, e.g. enter 0 to select the execution mode?"
read
clear
case "${REPLY^^}" in

"0")
start=`date +%s`
source $ENVDIR/.env
echo
echo "Do you want to run script in preview mode?"
export ANSWER=$(ask_yes_or_no "Are you sure?")
cd $HOME
if [[ ! -z "$TRAINING_ORG_ID" ]]  &&  [[ $ORG_ID == "$TRAINING_ORG_ID" ]]; then
    export STEP="${STEP},0"
    MODE=1
    if [[ "yes" == $ANSWER ]]; then
        export STEP="${STEP},0i"
        MODE=1
        echo
        echo "*** Command preview mode is active ***" | pv -qL 100
    else 
        if [[ -f $ENVDIR/.${GCP_PROJECT}.json ]]; then
            echo 
            echo "*** Authenticating using service account key $ENVDIR/.${GCP_PROJECT}.json ***" | pv -qL 100
            echo "*** To use a different GCP project, delete the service account key ***" | pv -qL 100
        else
            while [[ -z "$PROJECT_ID" ]] || [[ "$GCP_PROJECT" != "$PROJECT_ID" ]]; do
                echo 
                echo "$ gcloud auth login --brief --quiet # to authenticate as project owner or editor" | pv -qL 100
                gcloud auth login  --brief --quiet
                export ACCOUNT=$(gcloud config list account --format "value(core.account)")
                if [[ $ACCOUNT != "" ]]; then
                    echo
                    echo "Copy and paste a valid Google Cloud project ID below to confirm your choice:" | pv -qL 100
                    read GCP_PROJECT
                    gcloud config set project $GCP_PROJECT --quiet 2>/dev/null
                    sleep 3
                    export PROJECT_ID=$(gcloud projects list --filter $GCP_PROJECT --format 'value(PROJECT_ID)' 2>/dev/null)
                fi
            done
            gcloud iam service-accounts delete ${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com --quiet 2>/dev/null
            sleep 2
            gcloud --project $GCP_PROJECT iam service-accounts create ${GCP_PROJECT} 2>/dev/null
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member serviceAccount:$GCP_PROJECT@$GCP_PROJECT.iam.gserviceaccount.com --role=roles/owner > /dev/null 2>&1
            gcloud --project $GCP_PROJECT iam service-accounts keys create $ENVDIR/.${GCP_PROJECT}.json --iam-account=${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com 2>/dev/null
            gcloud --project $GCP_PROJECT storage buckets create gs://$GCP_PROJECT > /dev/null 2>&1
        fi
        export GOOGLE_APPLICATION_CREDENTIALS=$ENVDIR/.${GCP_PROJECT}.json
        cat <<EOF > $ENVDIR/.env
export GCP_PROJECT=$GCP_PROJECT
export GCP_REGION=$GCP_REGION
export GCP_ZONE=$GCP_ZONE
export CLUSTER_VERSION=$CLUSTER_VERSION
export AWS_LOCATION=$AWS_LOCATION
export AWS_REGION=$AWS_REGION
export AWS_NODE_TYPE=$AWS_NODE_TYPE
export AZURE_LOCATION=$AZURE_LOCATION
export AZURE_NODE_TYPE=$AZURE_NODE_TYPE
export SERVICEMESH_VERSION=$SERVICEMESH_VERSION
export APPLICATION_NAME=$APPLICATION_NAME
EOF
        gsutil cp $ENVDIR/.env gs://${PROJECT_ID}/$ENVDIR.env > /dev/null 2>&1
        echo
        echo "*** Google Cloud project is $GCP_PROJECT ***" | pv -qL 100
        echo "*** Google Cloud region is $GCP_REGION ***" | pv -qL 100
        echo "*** Google Cloud zone is $GCP_ZONE ***" | pv -qL 100
        echo "*** Google Cloud GKE cluster version is $CLUSTER_VERSION ***" | pv -qL 100
        echo "*** AWS location is $AWS_LOCATION ***" | pv -qL 100
        echo "*** AWS region is $AWS_REGION ***" | pv -qL 100
        echo "*** AWS node type is $AWS_NODE_TYPE ***" | pv -qL 100
        echo "*** Azure location is $AZURE_LOCATION ***" | pv -qL 100
        echo "*** Azure node type is $AZURE_NODE_TYPE ***" | pv -qL 100
        echo "*** Istio version is $SERVICEMESH_VERSION ***" | pv -qL 100
        echo "*** Application name is $APPLICATION_NAME ***" | pv -qL 100
        echo
        echo "*** Update environment variables by modifying values in the file: ***" | pv -qL 100
        echo "*** $ENVDIR/.env ***" | pv -qL 100
        if [[ "no" == $ANSWER ]]; then
            MODE=2
            echo
            echo "*** Create mode is active ***" | pv -qL 100
        elif [[ "del" == $ANSWER ]]; then
            export STEP="${STEP},0"
            MODE=3
            echo
            echo "*** Resource delete mode is active ***" | pv -qL 100
        fi
    fi
else 
    if [[ "no" == $ANSWER ]] || [[ "del" == $ANSWER ]] ; then
        export STEP="${STEP},0"
        if [[ -f $SCRIPTPATH/.${SCRIPTNAME}.secret ]]; then
            echo
            unset password
            unset pass_var
            echo -n "Enter access code: " | pv -qL 100
            while IFS= read -p "$pass_var" -r -s -n 1 letter
            do
                if [[ $letter == $'\0' ]]
                then
                    break
                fi
                password=$password"$letter"
                pass_var="*"
            done
            while [[ -z "${password// }" ]]; do
                unset password
                unset pass_var
                echo
                echo -n "You must enter an access code to proceed: " | pv -qL 100
                while IFS= read -p "$pass_var" -r -s -n 1 letter
                do
                    if [[ $letter == $'\0' ]]
                    then
                        break
                    fi
                    password=$password"$letter"
                    pass_var="*"
                done
            done
            export PASSCODE=$(cat $SCRIPTPATH/.${SCRIPTNAME}.secret | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -salt -pass pass:$password 2> /dev/null)
            if [[ $PASSCODE == 'AccessVerified' ]]; then
                MODE=2
                echo && echo
                echo "*** Access code is valid ***" | pv -qL 100
                if [[ -f $ENVDIR/.${GCP_PROJECT}.json ]]; then
                    echo 
                    echo "*** Authenticating using service account key $ENVDIR/.${GCP_PROJECT}.json ***" | pv -qL 100
                    echo "*** To use a different GCP project, delete the service account key ***" | pv -qL 100
                else
                    while [[ -z "$PROJECT_ID" ]] || [[ "$GCP_PROJECT" != "$PROJECT_ID" ]]; do
                        echo 
                        echo "$ gcloud auth login --brief --quiet # to authenticate as project owner or editor" | pv -qL 100
                        gcloud auth login  --brief --quiet
                        export ACCOUNT=$(gcloud config list account --format "value(core.account)")
                        if [[ $ACCOUNT != "" ]]; then
                            echo
                            echo "Copy and paste a valid Google Cloud project ID below to confirm your choice:" | pv -qL 100
                            read GCP_PROJECT
                            gcloud config set project $GCP_PROJECT --quiet 2>/dev/null
                            sleep 3
                            export PROJECT_ID=$(gcloud projects list --filter $GCP_PROJECT --format 'value(PROJECT_ID)' 2>/dev/null)
                        fi
                    done
                    gcloud iam service-accounts delete ${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com --quiet 2>/dev/null
                    sleep 2
                    gcloud --project $GCP_PROJECT iam service-accounts create ${GCP_PROJECT} 2>/dev/null
                    gcloud projects add-iam-policy-binding $GCP_PROJECT --member serviceAccount:$GCP_PROJECT@$GCP_PROJECT.iam.gserviceaccount.com --role=roles/owner > /dev/null 2>&1
                    gcloud --project $GCP_PROJECT iam service-accounts keys create $ENVDIR/.${GCP_PROJECT}.json --iam-account=${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com 2>/dev/null
                    gcloud --project $GCP_PROJECT storage buckets create gs://$GCP_PROJECT > /dev/null 2>&1
                fi
                export GOOGLE_APPLICATION_CREDENTIALS=$ENVDIR/.${GCP_PROJECT}.json
                cat <<EOF > $ENVDIR/.env
export GCP_PROJECT=$GCP_PROJECT
export GCP_REGION=$GCP_REGION
export GCP_ZONE=$GCP_ZONE
export CLUSTER_VERSION=$CLUSTER_VERSION
export AWS_LOCATION=$AWS_LOCATION
export AWS_REGION=$AWS_REGION
export AWS_NODE_TYPE=$AWS_NODE_TYPE
export AZURE_LOCATION=$AZURE_LOCATION
export AZURE_NODE_TYPE=$AZURE_NODE_TYPE
export APPLICATION_NAME=$APPLICATION_NAME
EOF
                gsutil cp $ENVDIR/.env gs://${PROJECT_ID}/$ENVDIR.env > /dev/null 2>&1
                echo
                echo "*** Google Cloud project is $GCP_PROJECT ***" | pv -qL 100
                echo "*** Google Cloud region is $GCP_REGION ***" | pv -qL 100
                echo "*** Google Cloud zone is $GCP_ZONE ***" | pv -qL 100
                echo "*** Google Cloud GKE cluster version is $CLUSTER_VERSION ***" | pv -qL 100
                echo "*** AWS location is $AWS_LOCATION ***" | pv -qL 100
                echo "*** AWS region is $AWS_REGION ***" | pv -qL 100
                echo "*** AWS node type is $AWS_NODE_TYPE ***" | pv -qL 100
                echo "*** Azure location is $AZURE_LOCATION ***" | pv -qL 100
                echo "*** Azure node type is $AZURE_NODE_TYPE ***" | pv -qL 100
                echo "*** Istio version is $SERVICEMESH_VERSION ***" | pv -qL 100
                echo "*** Application name is $APPLICATION_NAME ***" | pv -qL 100
                echo
                echo "*** Update environment variables by modifying values in the file: ***" | pv -qL 100
                echo "*** $ENVDIR/.env ***" | pv -qL 100
                if [[ "no" == $ANSWER ]]; then
                    MODE=2
                    echo
                    echo "*** Create mode is active ***" | pv -qL 100
                elif [[ "del" == $ANSWER ]]; then
                    export STEP="${STEP},0"
                    MODE=3
                    echo
                    echo "*** Resource delete mode is active ***" | pv -qL 100
                fi
            else
                echo && echo
                echo "*** Access code is invalid ***" | pv -qL 100
                echo "*** You can use this script in our Google Cloud Sandbox without an access code ***" | pv -qL 100
                echo "*** Contact support@techequity.cloud for assistance ***" | pv -qL 100
                echo
                echo "*** Command preview mode is active ***" | pv -qL 100
            fi
        else
            echo
            echo "*** You can use this script in our Google Cloud Sandbox without an access code ***" | pv -qL 100
            echo "*** Contact support@techequity.cloud for assistance ***" | pv -qL 100
            echo
            echo "*** Command preview mode is active ***" | pv -qL 100
        fi
    else
        export STEP="${STEP},0i"
        MODE=1
        echo
        echo "*** Command preview mode is active ***" | pv -qL 100
    fi
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"1")
start=`date +%s`
source $ENVDIR/.env
export STEP="${STEP},1"
echo
echo "Set the cloud platform (GCP | AZURE | AWS)" | pv -qL 100
read PLATFORM
while [[ "${PLATFORM^^}" != "AWS" ]] && [[ "${PLATFORM^^}" != "AZURE" ]] && [[ "${PLATFORM^^}" != "GCP" ]]; do 
    echo 
    echo "Enter the cloud platform. Valid options are AWS, AZURE or GCP" | pv -qL 100
    read PLATFORM
done
echo
echo "*** Platform is set to ${PLATFORM^^} ***" | pv -qL 100
if [[ "${PLATFORM^^}" == "AWS" ]] ; then 
    if command -v $PROJDIR/aws/aws >/dev/null 2>&1; then
        echo
        echo "*** AWS CLI available ***"
    else
        echo
        echo "*** AWS CLI has not been installed ***"
    fi
elif [[ "${PLATFORM^^}" == "AZURE" ]] ; then 
    if command -v /usr/bin/az >/dev/null 2>&1; then
        echo
        echo "*** Azure CLI available ***"
    else
        echo
        echo "*** Azure CLI has not been installed ***"
    fi
elif [[ "${PLATFORM^^}" == "GCP" ]] ; then 
    if command -v gcloud >/dev/null 2>&1; then
        echo
        echo "*** gcloud SDK available ***"
    else
        echo
        echo "*** gcloud SDK has not been installed ***"
    fi
fi
mkdir -p $HOME/mc-gke-cluster/${PLATFORM^^} > /dev/null 2>&1
export PROJDIR=$HOME/mc-gke-cluster/${PLATFORM^^}
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"2")
start=`date +%s`
source $ENVDIR/.env
case ${PLATFORM^^} in
    AWS)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},2i"
            echo
            echo "$ curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" --output \$PROJDIR/awscliv2.zip # to download" | pv -qL 100
            echo
            echo "$ unzip -o \$PROJDIR/awscliv2.zip -d \$PROJDIR # to unzip" | pv -qL 100
            echo
            echo "$ sudo \$PROJDIR /install --bin-dir \$PROJDIR --install-dir \$PROJDIR --update # to install aws cli" | pv -qL 100
            echo
            echo "$ curl --silent --location \"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_\$(uname -s)_amd64.tar.gz\" | tar xz -C /tmp # to download eksctl" | pv -qL 100
            echo
            echo "$ sudo git clone https://github.com/ahmetb/kubectx /tmp/kubectx # to clone repo" | pv -qL 100
        elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},2"
            echo
            echo "$ curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" --output $PROJDIR/awscliv2.zip # to download" | pv -qL 100
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" --output $PROJDIR/awscliv2.zip
            echo
            echo "$ unzip -o $PROJDIR/awscliv2.zip -d $PROJDIR # to unzip" | pv -qL 100
            unzip -o $PROJDIR/awscliv2.zip -d $PROJDIR 
            echo
            echo "$ sudo $PROJDIR/aws/install --bin-dir $PROJDIR --install-dir \$PROJDIR --update # to install aws cli" | pv -qL 100
            sudo $PROJDIR/aws/install --bin-dir $PROJDIR --install-dir $PROJDIR --update
            echo
            echo "$ curl --silent --location \"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz\" | tar xz -C /tmp # to download eksctl" | pv -qL 100
            curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
            echo
            echo "$ grep -qxF \"export PATH=\$PATH:\$PROJDIR:\$PROJDIR/aws\" ~/.bashrc || echo \"export PATH=\$PATH:\$PROJDIR:\$PROJDIR/aws\" >> ~/.bashrc # to add path" | pv -qL 100
            grep -qxF "export PATH=$PATH:$PROJDIR:$PROJDIR/aws" ~/.bashrc || echo "export PATH=$PATH:$PROJDIR:$PROJDIR/aws" >> ~/.bashrc
            source ~/.bashrc
            echo
            sudo rm -rf /tmp/kubectx
            echo "$ sudo git clone https://github.com/ahmetb/kubectx /tmp/kubectx # to clone repo" | pv -qL 100
            sudo git clone https://github.com/ahmetb/kubectx /tmp/kubectx
            echo
            echo "$ cp -rf /tmp/kubectx/kubectx $PROJDIR # to copy file" | pv -qL 100
            cp -rf /tmp/kubectx/kubectx $PROJDIR
            echo
            echo "$ cp -rf /tmp/kubectx/kubens $PROJDIR # to copy file" | pv -qL 100
            cp -rf /tmp/kubectx/kubens $PROJDIR
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},2x"
            echo
            echo "$ rm -rf $PROJDIR # to delete folder" | pv -qL 100
            rm -rf $PROJDIR
        fi
    ;;
    AZURE)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},2i"
            echo
            echo "$ curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash # to install CLI" | pv -qL 100
            echo
            echo "$ sudo git clone https://github.com/ahmetb/kubectx /tmp/kubectx # to clone repo" | pv -qL 100
        elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},2"
            echo
            echo "$ curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash # to install CLI" | pv -qL 100
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
            echo
            sudo sudo rm -rf /tmp/kubectx
            echo "$ sudo git clone https://github.com/ahmetb/kubectx /tmp/kubectx # to clone repo" | pv -qL 100
            sudo git clone https://github.com/ahmetb/kubectx /tmp/kubectx
            echo
            echo "$ cp -rf /tmp/kubectx/kubectx $PROJDIR # to copy file" | pv -qL 100
            cp -rf /tmp/kubectx/kubectx $PROJDIR
            echo
            echo "$ cp -rf /tmp/kubectx/kubens $PROJDIR # to copy file" | pv -qL 100
            cp -rf /tmp/kubectx/kubens $PROJDIR
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},2x"
            echo
            echo "$ rm -rf $PROJDIR # to delete folder" | pv -qL 100
            rm -rf $PROJDIR
        fi
    ;;
    GCP)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},2i"
            echo
            echo "$ sudo git clone https://github.com/ahmetb/kubectx /tmp/kubectx # to clone repo" | pv -qL 100
        elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},2"
            echo
            sudo sudo rm -rf /tmp/kubectx
            echo "$ sudo git clone https://github.com/ahmetb/kubectx /tmp/kubectx # to clone repo" | pv -qL 100
            sudo git clone https://github.com/ahmetb/kubectx /tmp/kubectx
            echo
            echo "$ cp -rf /tmp/kubectx/kubectx $PROJDIR # to copy file" | pv -qL 100
            cp -rf /tmp/kubectx/kubectx $PROJDIR
            echo
            echo "$ cp -rf /tmp/kubectx/kubens $PROJDIR # to copy file" | pv -qL 100
            cp -rf /tmp/kubectx/kubens $PROJDIR
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},2x"
            echo
            echo "$ rm -rf $PROJDIR # to delete folder" | pv -qL 100
            rm -rf $PROJDIR
       fi    
    ;;
esac
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"3")
start=`date +%s`
source $ENVDIR/.env
case ${PLATFORM^^} in
    AWS)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},3i"
            echo 
            echo "$ \$PROJDIR/aws/aws configure # to configure credentials" | pv -qL 100
        elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},3"
            gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
            gcloud config set aws/location $AWS_LOCATION > /dev/null 2>&1 
            export AWS_REGION=$AWS_REGION
            $PROJDIR/aws/aws configure set default.region $AWS_REGION > /dev/null 2>&1 
            $PROJDIR/aws/aws configure set default.output json > /dev/null 2>&1 
            echo 
            echo "$ $PROJDIR/aws/aws configure # to configure credentials" | pv -qL 100
            $PROJDIR/aws/aws configure
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},3x"
            echo
            echo "*** Nothing to delete ***" | pv -qL 100
        fi
    ;;
    AZURE)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},3i"
            echo
            echo "$ az login --use-device-code # to log on to Azure account" | pv -qL 100
            echo
            echo "$ az account show # to confirm access" | pv -qL 100
        elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},3"
            echo
            echo "$ az login --use-device-code # to log on to Azure account" | pv -qL 100
            az login --use-device-code
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},3x"
            echo
            echo "*** Nothing to delete ***" | pv -qL 100
        fi
    ;;
    GCP)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},3i"
            echo 
            echo "$ gcloud auth login --brief --quiet # to authenticate as project owner or editor" | pv -qL 100
        elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},3"
            gcloud config set project $GCP_PROJECT > /dev/null 2>&1
            if [[ -f $ENVDIR/.${GCP_PROJECT}.json ]]; then
                echo 
                echo "*** Authenticating using service account key $ENVDIR/.${GCP_PROJECT}.json ***" | pv -qL 100
                echo "*** To use a different GCP project, delete the service account key ***" | pv -qL 100
            else
                while [[ -z "$PROJECT_ID" ]] || [[ "$GCP_PROJECT" != "$PROJECT_ID" ]]; do
                    echo 
                    echo "$ gcloud auth login --brief --quiet # to authenticate as project owner or editor" | pv -qL 100
                    gcloud auth login  --brief --quiet
                    echo
                    echo "Copy and paste a valid Google Cloud project ID below to confirm your choice:" | pv -qL 100
                    read GCP_PROJECT
                    gcloud config set project $GCP_PROJECT --quiet
                    sleep 5
                    export PROJECT_ID=$(gcloud projects list --filter $GCP_PROJECT --format 'value(PROJECT_ID)') 
                done
            echo
            echo "*** Authenticated ***"
            fi
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},3x"
            echo
            echo "*** Nothing to delete ***" | pv -qL 100
        fi
    ;;
esac
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"4")
start=`date +%s`
source $ENVDIR/.env
case ${PLATFORM^^} in
    AWS)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},4i"
            echo
            echo "$ gcloud --project \$GCP_PROJECT services enable gkemulticloud.googleapis.com connectgateway.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com serviceusage.googleapis.com anthos.googleapis.com logging.googleapis.com monitoring.googleapis.com stackdriver.googleapis.com storage-api.googleapis.com storage-component.googleapis.com securetoken.googleapis.com sts.googleapis.com clouddeploy.googleapis.com # to enable APIs" | pv -qL 100
            echo
            echo "$ git clone https://github.com/GoogleCloudPlatform/anthos-samples.git /tmp/anthos-samples # to clone repo" | pv -qL 100
            echo
            echo "$ cp -rf /tmp/anthos-samples/anthos-multi-cloud/AWS $PROJDIR # to copy configuration files" | pv -qL 100
         elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},4"
            gcloud config set project $GCP_PROJECT > /dev/null 2>&1
            echo
            echo "$ gcloud --project $GCP_PROJECT services enable gkemulticloud.googleapis.com connectgateway.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com serviceusage.googleapis.com anthos.googleapis.com logging.googleapis.com monitoring.googleapis.com stackdriver.googleapis.com storage-api.googleapis.com storage-component.googleapis.com securetoken.googleapis.com sts.googleapis.com clouddeploy.googleapis.com # to enable APIs" | pv -qL 100
            gcloud --project $GCP_PROJECT services enable gkemulticloud.googleapis.com connectgateway.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com serviceusage.googleapis.com anthos.googleapis.com logging.googleapis.com monitoring.googleapis.com stackdriver.googleapis.com storage-api.googleapis.com storage-component.googleapis.com securetoken.googleapis.com sts.googleapis.com clouddeploy.googleapis.com
            echo
            rm -rf /tmp/anthos-samples
            echo "$ git clone https://github.com/GoogleCloudPlatform/anthos-samples.git /tmp/anthos-samples # to clone repo" | pv -qL 100
            git clone https://github.com/GoogleCloudPlatform/anthos-samples.git /tmp/anthos-samples
            echo
            echo "$ cp -rf /tmp/anthos-samples/anthos-multi-cloud/AWS $PROJDIR # to copy configuration files" | pv -qL 100
            cp -rf /tmp/anthos-samples/anthos-multi-cloud/AWS $PROJDIR
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},4x"
            echo
            echo "$ rm -rf $PROJDIR/AWS # to delete repo clone" | pv -qL 100
            rm -rf $PROJDIR/AWS
        else
            export STEP="${STEP},4i"
            echo
            echo "1. Enable APIs" | pv -qL 100
        fi
    ;;
    AZURE)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},4i"
            echo
            echo "$ gcloud --project \$GCP_PROJECT services enable gkemulticloud.googleapis.com connectgateway.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com serviceusage.googleapis.com anthos.googleapis.com logging.googleapis.com monitoring.googleapis.com stackdriver.googleapis.com storage-api.googleapis.com storage-component.googleapis.com securetoken.googleapis.com sts.googleapis.com clouddeploy.googleapis.com # to enable APIs" | pv -qL 100
            echo
            echo "$ git clone https://github.com/GoogleCloudPlatform/anthos-samples.git /tmp/anthos-samples # to clone repo" | pv -qL 100
            echo
            echo "$ cp -rf /tmp/anthos-samples/anthos-multi-cloud/Azure \$PROJDIR # to copy configuration files" | pv -qL 100
        elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},4"
            echo
            echo "$ gcloud --project $GCP_PROJECT services enable gkemulticloud.googleapis.com connectgateway.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com serviceusage.googleapis.com anthos.googleapis.com logging.googleapis.com monitoring.googleapis.com stackdriver.googleapis.com storage-api.googleapis.com storage-component.googleapis.com securetoken.googleapis.com sts.googleapis.com clouddeploy.googleapis.com # to enable APIs" | pv -qL 100
            gcloud --project $GCP_PROJECT services enable gkemulticloud.googleapis.com connectgateway.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com serviceusage.googleapis.com anthos.googleapis.com logging.googleapis.com monitoring.googleapis.com stackdriver.googleapis.com storage-api.googleapis.com storage-component.googleapis.com securetoken.googleapis.com sts.googleapis.com clouddeploy.googleapis.com
            echo
            rm -rf /tmp/anthos-samples
            echo "$ git clone https://github.com/GoogleCloudPlatform/anthos-samples.git /tmp/anthos-samples # to clone repo" | pv -qL 100
            git clone https://github.com/GoogleCloudPlatform/anthos-samples.git /tmp/anthos-samples
            echo
            echo "$ cp -rf /tmp/anthos-samples/anthos-multi-cloud/Azure $PROJDIR # to copy configuration files" | pv -qL 100
            cp -rf /tmp/anthos-samples/anthos-multi-cloud/Azure $PROJDIR
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},4x"
            echo
            echo "$ az group delete --name ${AZ_RESOURCEGROUP} --yes # delete resource group" | pv -qL 100
            az group delete --name ${AZ_RESOURCEGROUP} --yes >/dev/null 2>&1
            echo
            echo "$ rm -rf $PROJDIR/Azure # to delete repo clone" | pv -qL 100
            rm -rf $PROJDIR/Azure
        else
            export STEP="${STEP},4i"
            echo
            echo "1. Create resource group" | pv -qL 100
        fi
    ;;
    GCP)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},4i"
            echo
            echo "$ gcloud --project \$GCP_PROJECT services enable gkemulticloud.googleapis.com connectgateway.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com serviceusage.googleapis.com anthos.googleapis.com logging.googleapis.com monitoring.googleapis.com stackdriver.googleapis.com storage-api.googleapis.com storage-component.googleapis.com securetoken.googleapis.com sts.googleapis.com clouddeploy.googleapis.com # to enable APIs" | pv -qL 100
         elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},4"
            gcloud config set project $GCP_PROJECT > /dev/null 2>&1
            echo
            echo "$ gcloud --project $GCP_PROJECT services enable gkemulticloud.googleapis.com connectgateway.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com serviceusage.googleapis.com anthos.googleapis.com logging.googleapis.com monitoring.googleapis.com stackdriver.googleapis.com storage-api.googleapis.com storage-component.googleapis.com securetoken.googleapis.com sts.googleapis.com clouddeploy.googleapis.com # to enable APIs" | pv -qL 100
            gcloud --project $GCP_PROJECT services enable gkemulticloud.googleapis.com connectgateway.googleapis.com cloudresourcemanager.googleapis.com container.googleapis.com gkeconnect.googleapis.com gkehub.googleapis.com serviceusage.googleapis.com anthos.googleapis.com logging.googleapis.com monitoring.googleapis.com stackdriver.googleapis.com storage-api.googleapis.com storage-component.googleapis.com securetoken.googleapis.com sts.googleapis.com clouddeploy.googleapis.com
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},4x"
            echo
            echo "*** Nothing to delete ***" | pv -qL 100
        else
            export STEP="${STEP},4i"
            echo
            echo "1. Enable APIs" | pv -qL 100
        fi
    ;;
esac
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"5")
start=`date +%s`
source $ENVDIR/.env
case ${PLATFORM^^} in
    AWS)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},5i"
            echo 
            echo "$ cat > \$PROJDIR/terraform.ftvars <<EOF
gcp_project_id = \"\$GCP_PROJECT\"
admin_users = [\"\$EMAIL\"]
name_prefix = \"aws-gke-cluster\"
node_pool_instance_type = \"\$AWS_NODE_TYPE\"
control_plane_instance_type = \"\$AWS_NODE_TYPE\"
cluster_version = \"\$CLUSTER_VERSION\"
gcp_location = \"\$AWS_LOCATION\"
aws_region = \"\$AWS_REGION\"
subnet_availability_zones = [\"$\{AWS_REGION}a\", \"\${AWS_REGION}b\", \"\${AWS_REGION}c\"]
EOF" | pv -qL 100
            echo
            echo "$ terraform init -upgrade # to initialize terraform" | pv -qL 100
            echo
            echo "$ terraform apply -auto-approve # to apply configuration" | pv -qL 100
            echo
            echo "$ gcloud container aws clusters get-credentials gcp-gke-cluster # to retrieve credentials" | pv -qL 100
            echo
            echo "$ kubectx aws=. # to set context"
            echo
            echo "$ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"\$PROJECT_NUMBER-compute@developer.gserviceaccount.com\" # to enable current user to set RBAC rules" | pv -qL 100
         elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},5"
            gcloud config set project $GCP_PROJECT > /dev/null 2>&1
            gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1
            export PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT --format="value(projectNumber)")
            echo
            echo "$ cd $PROJDIR/AWS # to change directory" | pv -qL 100
            cd $PROJDIR/AWS
            echo 
            echo "$ export EMAIL=\$(gcloud config get-value core/account) # to set email" | pv -qL 100
            export EMAIL=$(gcloud config get-value core/account)
            echo
            echo "$ cat > terraform.tfvars <<EOF
gcp_project_id = \"$GCP_PROJECT\"
admin_users = [\"$EMAIL\"]
name_prefix = \"aws-gke-cluster\"
node_pool_instance_type = \"$AWS_NODE_TYPE\"
control_plane_instance_type = \"$AWS_NODE_TYPE\"
cluster_version = \"$CLUSTER_VERSION\"
gcp_location = \"$AWS_LOCATION\"
aws_region = \"$AWS_REGION\"
subnet_availability_zones = [\"${AWS_REGION}a\", \"${AWS_REGION}b\", \"${AWS_REGION}c\"]
EOF" | pv -qL 100
cat > terraform.tfvars <<EOF
gcp_project_id = "$GCP_PROJECT"
admin_users = ["$EMAIL"]
name_prefix = "aws-gke-cluster"
node_pool_instance_type = "$AWS_NODE_TYPE"
control_plane_instance_type = "$AWS_NODE_TYPE"
cluster_version = "$CLUSTER_VERSION"
gcp_location = "$AWS_LOCATION"
aws_region = "$AWS_REGION"
subnet_availability_zones = ["${AWS_REGION}a", "${AWS_REGION}b", "${AWS_REGION}c"]
EOF
            echo
            echo "$ terraform init -upgrade # to initialize terraform" | pv -qL 100
            terraform init -upgrade
            echo
            echo "$ terraform apply -auto-approve # to apply configuration" | pv -qL 100
            terraform apply -auto-approve 
            echo
            source $PROJDIR/AWS/vars.sh > /dev/null 2>&1
            echo "$ gcloud container aws clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION # to retrieve credentials" | pv -qL 100
            gcloud container aws clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION
            echo
            echo "$ kubectx aws=. # to set context"
            kubectx aws=.
            echo
            echo "$ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"$PROJECT_NUMBER-compute@developer.gserviceaccount.com\" # to enable current user to set RBAC rules" | pv -qL 100
            kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"
         elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},5x"
            echo
            echo "$ cd $PROJDIR/AWS # to change directory" | pv -qL 100
            cd $PROJDIR/AWS
            echo
            echo "$ terraform destroy # to destroy terraform" | pv -qL 100
            terraform destroy
        else
            export STEP="${STEP},5i"
            echo
            echo "1. Configure terraform.tfvars" | pv -qL 100
            echo "2. Initialize terraform" | pv -qL 100
            echo "3. Apply terraform" | pv -qL 100
        fi
    ;;
    AZURE)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},5i"
            echo
            echo "$ cat > \$PROJDIR/terraform.ftvars <<EOF
gcp_project_id = \"\$GCP_PROJECT\"
admin_users = [\"\$EMAIL\"]
name_prefix = \"azure-gke-cluster\"
node_pool_instance_type = \"\$AZURE_NODE_TYPE\"
control_plane_instance_type = \"\$AZURE_NODE_TYPE\"
cluster_version = \"\$CLUSTER_VERSION\"
gcp_location = \"\$AWS_LOCATION\"
azure_region = \"\$AZURE_LOCATION\"
EOF" | pv -qL 100
            echo
            echo "$ terraform init -upgrade # to initialize terraform" | pv -qL 100
            echo
            echo "$ terraform apply -auto-approve # to apply configuration" | pv -qL 100
            echo
            echo "$ gcloud container azure clusters get-credentials \$CLUSTER_NAME --location $AWS_LOCATION # to retrieve credentials" | pv -qL 100
            echo
            echo "$ kubectx azure=. # to set context"
            echo
            echo "$ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"\$PROJECT_NUMBER-compute@developer.gserviceaccount.com\" # to enable current user to set RBAC rules" | pv -qL 100
         elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},5"
            gcloud config set project $GCP_PROJECT > /dev/null 2>&1
            gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1
            export PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT --format="value(projectNumber)")
            echo
            echo "$ cd $PROJDIR/Azure # to change directory" | pv -qL 100
            cd $PROJDIR/Azure
            echo 
            echo "$ export EMAIL=\$(gcloud config get-value core/account) # to set email" | pv -qL 100
            export EMAIL=$(gcloud config get-value core/account)
            echo
            echo "$ cat > terraform.tfvars <<EOF
gcp_project_id = \"$GCP_PROJECT\"
admin_users = [\"$EMAIL\"]
name_prefix = \"azure-gke-cluster\"
node_pool_instance_type = \"$AZURE_NODE_TYPE\"
control_plane_instance_type = \"$AZURE_NODE_TYPE\"
cluster_version = \"$CLUSTER_VERSION\"
gcp_location = \"$AWS_LOCATION\"
azure_region = \"$AZURE_LOCATION\"
EOF" | pv -qL 100
cat > terraform.tfvars <<EOF
gcp_project_id = "$GCP_PROJECT"
admin_users = ["$EMAIL"]
name_prefix = "azure-gke-cluster"
node_pool_instance_type = "$AZURE_NODE_TYPE"
control_plane_instance_type = "$AZURE_NODE_TYPE"
cluster_version = "$CLUSTER_VERSION"
gcp_location = "$AWS_LOCATION"
azure_region = "$AZURE_LOCATION"
EOF
            echo
            echo "$ export ARM_SUBSCRIPTION_ID=\$(/usr/bin/az account show --query \"id\" --output tsv) # to set subscription ID" | pv -qL 100
            export ARM_SUBSCRIPTION_ID=$(/usr/bin/az account show --query "id" --output tsv)
            echo
            echo "$ export ARM_TENANT_ID=\$(/usr/bin/az account list --query \"[?id=='\${ARM_SUBSCRIPTION_ID}'].{tenantId:tenantId}\" --output tsv) # to set tenant ID" | pv -qL 100
            export ARM_TENANT_ID=$(/usr/bin/az account list --query "[?id=='${ARM_SUBSCRIPTION_ID}'].{tenantId:tenantId}" --output tsv)
            echo
            echo "$ terraform init -upgrade # to initialize terraform" | pv -qL 100
            terraform init -upgrade
            echo
            echo "$ terraform apply -auto-approve # to apply configuration" | pv -qL 100
            terraform apply -auto-approve 
            echo
            source $PROJDIR/Azure/vars.sh > /dev/null 2>&1
            echo "$ gcloud container azure clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION # to retrieve credentials" | pv -qL 100
            gcloud container azure clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION
            echo
            echo "$ kubectx azure=. # to set context"
            kubectx azure=.
            echo
            echo "$ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"$PROJECT_NUMBER-compute@developer.gserviceaccount.com\" # to enable current user to set RBAC rules" | pv -qL 100
            kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},5x"
            echo
            echo "$ cd $PROJDIR/Azure # to change directory" | pv -qL 100
            cd $PROJDIR/Azure
            echo
            echo "$ terraform destroy # to destroy terraform" | pv -qL 100
            terraform destroy
        else
            export STEP="${STEP},5i"
            echo
            echo "1. Set subscription ID" | pv -qL 100
            echo "2. Set tenant ID" | pv -qL 100
            echo "3. Initialise and apply terraform configuration" | pv -qL 100
        fi
    ;;
    GCP)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},5i"
            echo
            echo "$ gcloud beta container clusters create gcp-gke-cluster --zone \$GCP_ZONE --machine-type e2-standard-2 --num-nodes 4 --spot --workload-pool=\${WORKLOAD_POOL} --labels=mesh_id=\${MESH_ID},location=\$GCP_REGION # to create container cluster" | pv -qL 100
            echo
            echo "$ gcloud container clusters get-credentials gcp-gke-cluster --zone \$GCP_ZONE # to retrieve the credentials for cluster" | pv -qL 100
            echo
            echo "$ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"\$(gcloud config get-value core/account)\" # to enable current user to set RBAC rules" | pv -qL 100
            echo
            echo "$ gcloud container fleet memberships register gcp-gke-cluster --gke-cluster=\$GCP_ZONE/gcp-gke-cluster --enable-workload-identity # to register cluster" | pv -qL 100
            echo
            echo "$ kubectx gcp=. # to set context"
            echo
            echo "$ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"\$PROJECT_NUMBER-compute@developer.gserviceaccount.com\" # to enable current user to set RBAC rules" | pv -qL 100
        elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},5"
            gcloud config set project $GCP_PROJECT > /dev/null 2>&1
            gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1
            export PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT --format="value(projectNumber)")
            export MESH_ID="proj-${PROJECT_NUMBER}" # sets the mesh_id label on the cluster
            export WORKLOAD_POOL=${GCP_PROJECT}.svc.id.goog
            echo
            echo "$ gcloud beta container clusters create gcp-gke-cluster --zone $GCP_ZONE --machine-type e2-standard-2 --num-nodes 4 --spot --workload-pool=${WORKLOAD_POOL} --labels=mesh_id=${MESH_ID},location=$GCP_REGION # to create container cluster" | pv -qL 100
            gcloud beta container clusters create gcp-gke-cluster --zone $GCP_ZONE --machine-type e2-standard-2 --num-nodes 4 --spot --workload-pool=${WORKLOAD_POOL} --labels=mesh_id=${MESH_ID},location=$GCP_REGION 
            echo
            echo "$ gcloud container clusters get-credentials gcp-gke-cluster --zone $GCP_ZONE # to retrieve credentials for cluster" | pv -qL 100
            gcloud container clusters get-credentials gcp-gke-cluster --zone $GCP_ZONE
            echo
            echo "$ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"\$(gcloud config get-value core/account)\" # to enable current user to set RBAC rules" | pv -qL 100
            kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
            echo
            echo "$ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"$PROJECT_NUMBER-compute@developer.gserviceaccount.com\" # to enable current user to set RBAC rules" | pv -qL 100
            kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"
            echo
            echo "$ gcloud container fleet memberships register gcp-gke-cluster --gke-cluster=$GCP_ZONE/gcp-gke-cluster --enable-workload-identity # to register cluster" | pv -qL 100
            gcloud container fleet memberships register gcp-gke-cluster --gke-cluster=$GCP_ZONE/gcp-gke-cluster --enable-workload-identity
            echo
            echo "$ kubectx gcp=. # to set context"
            kubectx gcp=.
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},5x"
            gcloud config set project $GCP_PROJECT > /dev/null 2>&1
            gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1
            echo
            echo "$ kubectx gcp # to switch context" | pv -qL 100
            kubectx gcp
            echo
            echo "$ gcloud container fleet memberships unregister gcp-gke-cluster --context=gcp # to unregister cluster" | pv -qL 100
            gcloud container fleet memberships unregister gcp-gke-cluster --context=gcp
            echo
            echo "$ gcloud beta container clusters delete gcp-gke-cluster --zone $GCP_ZONE # to delete cluster" | pv -qL 100
            gcloud beta container clusters delete gcp-gke-cluster --zone $GCP_ZONE 
        else
            export STEP="${STEP},5i"
            echo
            echo "1. Create container cluster" | pv -qL 100
            echo "2. Retrieve the credentials for cluster" | pv -qL 100
            echo "3. Enable current user to set RBAC rules" | pv -qL 100
            echo "4. Enable system container logging and container metrics" | pv -qL 100
            echo "5. Configure connect gateway" | pv -qL 100
        fi
    ;;
esac
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"6")
start=`date +%s`
source $ENVDIR/.env
case ${PLATFORM^^} in
    AWS)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},6i"
            echo
            echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\$CLOUDBUILD_SA --role=roles/clouddeploy.jobRunner # to run jobs" | pv -qL 100
            echo
            echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\$DEVELOPER_SA --role=roles/artifactregistry.reader # to pull containers" | pv -qL 100
            echo
            echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\$DEVELOPER_SA --role=roles/container.developer # to deploy to GKE" | pv -qL 100
            echo
            echo "$ gcloud --project \$GCP_PROJECT -q iam service-accounts add-iam-policy-binding \$DEVELOPER_SA --member=serviceAccount:\$CLOUDBUILD_SA --role=roles/iam.serviceAccountUser # to invoke Google Cloud Deploy operations" | pv -qL 100
            echo
            echo "$ gcloud -q projects add-iam-policy-binding \$GCP_PROJECT --condition=None --member=serviceAccount:\$CLOUDBUILD_SA --role=\"roles/clouddeploy.operator\" # to update the delivery pipeline and the target definitions" | pv -qL 100
            echo
            echo "$ gcloud iam service-accounts keys create \$ENVDIR/image-pull.json --iam-account \$DEVELOPER_SA # to download service account key" | pv -qL 100
            echo
            echo "$ kubectx aws # to set context" | pv -qL 100
            echo
            echo "$ kubectl create secret docker-registry artifact-registry --docker-server=https://\${GCP_REGION}-docker.pkg.dev --docker-email=\$EMAIL --docker-username=_json_key --docker-password=\"\$(cat $ENVDIR/image-pull.json)\" # to create docker registry secret" | pv -qL 100
            echo
            echo "$ kubectl patch serviceaccount default -p '{\"imagePullSecrets\": [{\"name\": \"artifact-registry\"}]}' # to patch the default k8s service account with docker-registry image pull secret" | pv -qL 100
         elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},6"
            PROJECT_NUMBER=$(gcloud --project $GCP_PROJECT projects describe $GCP_PROJECT --format="value(projectNumber)")
            DEVELOPER_SA=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
            CLOUDBUILD_SA=${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com
            echo
            echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$CLOUDBUILD_SA --role=roles/clouddeploy.jobRunner # to run jobs" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$CLOUDBUILD_SA --role=roles/clouddeploy.jobRunner
            echo
            echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/artifactregistry.reader # to pull containers" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/artifactregistry.reader
            echo
            echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/container.developer # to deploy to GKE" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/container.developer
            echo
            echo "$ gcloud --project=$GCP_PROJECT -q iam service-accounts add-iam-policy-binding $DEVELOPER_SA --member=serviceAccount:$CLOUDBUILD_SA --role=roles/iam.serviceAccountUser # to invoke Google Cloud Deploy operations" | pv -qL 100
            gcloud --project=$GCP_PROJECT -q iam service-accounts add-iam-policy-binding $DEVELOPER_SA --member=serviceAccount:$CLOUDBUILD_SA --role=roles/iam.serviceAccountUser
            echo
            echo "$ gcloud -q projects add-iam-policy-binding $GCP_PROJECT --condition=None --member=serviceAccount:$CLOUDBUILD_SA --role=\"roles/clouddeploy.operator\" # to update the delivery pipeline and the target definitions" | pv -qL 100
            gcloud -q projects add-iam-policy-binding $GCP_PROJECT --condition=None --member=serviceAccount:$CLOUDBUILD_SA --role="roles/clouddeploy.operator"
            echo
            echo "$ gcloud gcloud projects add-iam-policy-binding $GCP_PROJECT --member=\"serviceAccount:${GCP_PROJECT}.svc.id.goog[gke-system/gke-telemetry-agent]\" --role=roles/gkemulticloud.telemetryWriter # to write telemetry to Cloud Operations" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member="serviceAccount:${GCP_PROJECT}.svc.id.goog[gke-system/gke-telemetry-agent]" --role=roles/gkemulticloud.telemetryWriter
            if [[ ! -f $ENVDIR/image-pull.json ]]; then
                echo
                echo "$ gcloud iam service-accounts keys create $ENVDIR/image-pull.json --iam-account $DEVELOPER_SA # to download service account key" | pv -qL 100
                gcloud iam service-accounts keys create $ENVDIR/image-pull.json --iam-account $DEVELOPER_SA
            fi
            echo
            echo "$ kubectx aws # to set context" | pv -qL 100
            kubectx aws
            echo
            export EMAIL=$(gcloud config get-value core/account) > /dev/null 2>&1
            echo "$ kubectl create secret docker-registry artifact-registry --docker-server=https://${GCP_REGION}-docker.pkg.dev --docker-email=$EMAIL --docker-username=_json_key --docker-password=\"\$(cat $ENVDIR/image-pull.json)\" # to create docker registry secret" | pv -qL 100
            kubectl create secret docker-registry artifact-registry --docker-server=https://${GCP_REGION}-docker.pkg.dev --docker-email=$EMAIL --docker-username=_json_key --docker-password="$(cat $ENVDIR/image-pull.json)"
            echo
            echo "$ kubectl patch serviceaccount default -p '{\"imagePullSecrets\": [{\"name\": \"artifact-registry\"}]}' # to patch the default k8s service account with docker-registry image pull secret" | pv -qL 100
            kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "artifact-registry"}]}'
         elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},6x"
            echo
            echo "*** Nothing to delete ***" | pv -qL 100
        else
            export STEP="${STEP},6i"
            echo
            echo "1. Configure IAM policies" | pv -qL 100
            echo "2. Configure image pull secret" | pv -qL 100
        fi
    ;;
    AZURE)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},6i"
            echo
            echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\$CLOUDBUILD_SA --role=roles/clouddeploy.jobRunner # to run jobs" | pv -qL 100
            echo
            echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\$DEVELOPER_SA --role=roles/artifactregistry.reader # to pull containers" | pv -qL 100
            echo
            echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\$DEVELOPER_SA --role=roles/container.developer # to deploy to GKE" | pv -qL 100
            echo
            echo "$ gcloud --project \$GCP_PROJECT -q iam service-accounts add-iam-policy-binding \$DEVELOPER_SA --member=serviceAccount:\$CLOUDBUILD_SA --role=roles/iam.serviceAccountUser # to invoke Google Cloud Deploy operations" | pv -qL 100
            echo
            echo "$ gcloud -q projects add-iam-policy-binding \$GCP_PROJECT --condition=None --member=serviceAccount:\$CLOUDBUILD_SA --role=\"roles/clouddeploy.operator\" # to update the delivery pipeline and the target definitions" | pv -qL 100
            echo
            echo "$ gcloud iam service-accounts keys create \$ENVDIR/image-pull.json --iam-account \$DEVELOPER_SA # to download service account key" | pv -qL 100
            echo
            echo "$ kubectx azure # to set context" | pv -qL 100
            echo
            echo "$ kubectl create secret docker-registry artifact-registry --docker-server=https://\${GCP_REGION}-docker.pkg.dev --docker-email=\$EMAIL --docker-username=_json_key --docker-password=\"\$(cat $ENVDIR/image-pull.json)\" # to create docker registry secret" | pv -qL 100
            echo
            echo "$ kubectl patch serviceaccount default -p '{\"imagePullSecrets\": [{\"name\": \"artifact-registry\"}]}' # to patch the default k8s service account with docker-registry image pull secret" | pv -qL 100
         elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},6"
            PROJECT_NUMBER=$(gcloud --project $GCP_PROJECT projects describe $GCP_PROJECT --format="value(projectNumber)")
            DEVELOPER_SA=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
            CLOUDBUILD_SA=${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com
            echo
            echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$CLOUDBUILD_SA --role=roles/clouddeploy.jobRunner # to run jobs" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$CLOUDBUILD_SA --role=roles/clouddeploy.jobRunner
            echo
            echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/artifactregistry.reader # to pull containers" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/artifactregistry.reader
            echo
            echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/container.developer # to deploy to GKE" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/container.developer
            echo
            echo "$ gcloud --project=$GCP_PROJECT -q iam service-accounts add-iam-policy-binding $DEVELOPER_SA --member=serviceAccount:$CLOUDBUILD_SA --role=roles/iam.serviceAccountUser # to invoke Google Cloud Deploy operations" | pv -qL 100
            gcloud --project=$GCP_PROJECT -q iam service-accounts add-iam-policy-binding $DEVELOPER_SA --member=serviceAccount:$CLOUDBUILD_SA --role=roles/iam.serviceAccountUser
            echo
            echo "$ gcloud -q projects add-iam-policy-binding $GCP_PROJECT --condition=None --member=serviceAccount:$CLOUDBUILD_SA --role=\"roles/clouddeploy.operator\" # to update the delivery pipeline and the target definitions" | pv -qL 100
            gcloud -q projects add-iam-policy-binding $GCP_PROJECT --condition=None --member=serviceAccount:$CLOUDBUILD_SA --role="roles/clouddeploy.operator"
            echo
            echo "$ gcloud gcloud projects add-iam-policy-binding $GCP_PROJECT --member=\"serviceAccount:${GCP_PROJECT}.svc.id.goog[gke-system/gke-telemetry-agent]\" --role=roles/gkemulticloud.telemetryWriter # to write telemetry to Cloud Operations" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member="serviceAccount:${GCP_PROJECT}.svc.id.goog[gke-system/gke-telemetry-agent]" --role=roles/gkemulticloud.telemetryWriter
            if [[ ! -f $ENVDIR/image-pull.json ]]; then
                echo
                echo "$ gcloud iam service-accounts keys create $ENVDIR/image-pull.json --iam-account $DEVELOPER_SA # to download service account key" | pv -qL 100
                gcloud iam service-accounts keys create $ENVDIR/image-pull.json --iam-account $DEVELOPER_SA
            fi
            echo
            echo "$ kubectx azure # to set context" | pv -qL 100
            kubectx azure
            echo
            export EMAIL=$(gcloud config get-value core/account) > /dev/null 2>&1
            echo "$ kubectl create secret docker-registry artifact-registry --docker-server=https://${GCP_REGION}-docker.pkg.dev --docker-email=$EMAIL --docker-username=_json_key --docker-password=\"\$(cat $ENVDIR/image-pull.json)\" # to create docker registry secret" | pv -qL 100
            kubectl create secret docker-registry artifact-registry --docker-server=https://${GCP_REGION}-docker.pkg.dev --docker-email=$EMAIL --docker-username=_json_key --docker-password="$(cat $ENVDIR/image-pull.json)"
            echo
            echo "$ kubectl patch serviceaccount default -p '{\"imagePullSecrets\": [{\"name\": \"artifact-registry\"}]}' # to patch the default k8s service account with docker-registry image pull secret" | pv -qL 100
            kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "artifact-registry"}]}'
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},6x"
            echo
            echo "*** Nothing to delete ***" | pv -qL 100
        else
            export STEP="${STEP},6i"
            echo
            echo "1. Configure IAM policies" | pv -qL 100
            echo "2. Configure image pull secret" | pv -qL 100
        fi
    ;;
    GCP)
        if [ $MODE -eq 1 ]; then
            export STEP="${STEP},6i"
            echo
            echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\$CLOUDBUILD_SA --role=roles/clouddeploy.jobRunner # to run jobs" | pv -qL 100
            echo
            echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\$DEVELOPER_SA --role=roles/artifactregistry.reader # to pull containers" | pv -qL 100
            echo
            echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\$DEVELOPER_SA --role=roles/container.developer # to deploy to GKE" | pv -qL 100
            echo
            echo "$ gcloud --project=\$GCP_PROJECT -q iam service-accounts add-iam-policy-binding \$DEVELOPER_SA --member=serviceAccount:\$CLOUDBUILD_SA --role=roles/iam.serviceAccountUser # to invoke Google Cloud Deploy operations" | pv -qL 100
            echo
            echo "$ gcloud -q projects add-iam-policy-binding \$GCP_PROJECT --condition=None --member=serviceAccount:\$CLOUDBUILD_SA --role=\"roles/clouddeploy.operator\" # to update the delivery pipeline and the target definitions" | pv -qL 100
            echo
            echo "$ gcloud gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=\"serviceAccount:\${GCP_PROJECT}.svc.id.goog[gke-system/gke-telemetry-agent]\" --role=roles/gkemulticloud.telemetryWriter # to write telemetry to Cloud Operations" | pv -qL 100
         elif [ $MODE -eq 2 ]; then
            export STEP="${STEP},6"
            PROJECT_NUMBER=$(gcloud --project $GCP_PROJECT projects describe $GCP_PROJECT --format="value(projectNumber)")
            DEVELOPER_SA=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
            CLOUDBUILD_SA=${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com
            echo
            echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$CLOUDBUILD_SA --role=roles/clouddeploy.jobRunner # to run jobs" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$CLOUDBUILD_SA --role=roles/clouddeploy.jobRunner
            echo
            echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/artifactregistry.reader # to pull containers" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/artifactregistry.reader
            echo
            echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/container.developer # to deploy to GKE" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:$DEVELOPER_SA --role=roles/container.developer
            echo
            echo "$ gcloud --project=$GCP_PROJECT -q iam service-accounts add-iam-policy-binding $DEVELOPER_SA --member=serviceAccount:$CLOUDBUILD_SA --role=roles/iam.serviceAccountUser # to invoke Google Cloud Deploy operations" | pv -qL 100
            gcloud --project=$GCP_PROJECT -q iam service-accounts add-iam-policy-binding $DEVELOPER_SA --member=serviceAccount:$CLOUDBUILD_SA --role=roles/iam.serviceAccountUser
            echo
            echo "$ gcloud -q projects add-iam-policy-binding $GCP_PROJECT --condition=None --member=serviceAccount:$CLOUDBUILD_SA --role=\"roles/clouddeploy.operator\" # to update the delivery pipeline and the target definitions" | pv -qL 100
            gcloud -q projects add-iam-policy-binding $GCP_PROJECT --condition=None --member=serviceAccount:$CLOUDBUILD_SA --role="roles/clouddeploy.operator"
            echo
            echo "$ gcloud gcloud projects add-iam-policy-binding $GCP_PROJECT --member=\"serviceAccount:${GCP_PROJECT}.svc.id.goog[gke-system/gke-telemetry-agent]\" --role=roles/gkemulticloud.telemetryWriter # to write telemetry to Cloud Operations" | pv -qL 100
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member="serviceAccount:${GCP_PROJECT}.svc.id.goog[gke-system/gke-telemetry-agent]" --role=roles/gkemulticloud.telemetryWriter
        elif [ $MODE -eq 3 ]; then
            export STEP="${STEP},6x"
            echo
            echo "*** Nothing to delete ***" | pv -qL 100
        else
            export STEP="${STEP},6i"
            echo
            echo "1. Configure IAM policies" | pv -qL 100
        fi
    ;;
esac
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"7")
start=`date +%s`
source $ENVDIR/.env
case ${PLATFORM^^} in
    AWS)
        if [ $MODE -eq 1 ]; then
            echo
            echo "$ gcloud container aws clusters get-credentials \$CLUSTER_NAME --location \$AWS_LOCATION # to retrieve credentials" | pv -qL 100
            echo
            echo "$ \$PROJDIR/kubectx aws=. # to update context"
        else
            echo
            source $ENVDIR/AWS/AWS/vars.sh > /dev/null 2>&1
            echo "$ gcloud container aws clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION # to retrieve credentials" | pv -qL 100
            gcloud container aws clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION
            echo
            echo "$ $PROJDIR/kubectx aws=. # to update context"
            $PROJDIR/kubectx aws=.
        fi
    ;;
    AZURE)
        if [ $MODE -eq 1 ]; then
            echo
            echo "$ gcloud container azure clusters get-credentials \$CLUSTER_NAME --location \$AWS_LOCATION # to retrieve credentials" | pv -qL 100
            echo
            echo "$ \$PROJDIR/kubectx azure=. # to update context"
        else
            echo
            source $ENVDIR/AZURE/Azure/vars.sh > /dev/null 2>&1
            echo "$ gcloud container azure clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION # to retrieve credentials" | pv -qL 100
            gcloud container azure clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION
            echo
            echo "$ $PROJDIR/kubectx azure=. # to update context"
            $PROJDIR/kubectx azure=.
        fi
    ;;
    GCP)
        if [ $MODE -eq 1 ]; then
            echo
            echo "$ gcloud container clusters get-credentials gcp-gke-cluster --zone \$GCP_ZONE # to retrieve credentials for cluster" | pv -qL 100
            echo
            echo "$ \$PROJDIR/kubectx gcp=. # to update context"
       else
            echo
            echo "$ gcloud container clusters get-credentials gcp-gke-cluster --zone $GCP_ZONE # to retrieve credentials for cluster" | pv -qL 100
            gcloud container clusters get-credentials gcp-gke-cluster --zone $GCP_ZONE
            echo
            echo "$ $PROJDIR/kubectx gcp=. # to update context"
            $PROJDIR/kubectx gcp=.
        fi
    ;;
esac
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},7i"
    echo
    echo "$ curl -L \"https://storage.googleapis.com/gke-release/asm/istio-\${SERVICEMESH_VERSION}-linux-amd64.tar.gz\" | tar xz -C \$ENVDIR # to download the Anthos Service Mesh" | pv -qL 100
    echo
    echo "$ kubectl create namespace istio-system # to create a namespace called istio-system" | pv -qL 100
    echo
    echo "$ make -f \$ENVDIR/istio-\${SERVICEMESH_VERSION}/tools/certs/Makefile.selfsigned.mk root-ca # to generate a root certificate and key" | pv -qL 100
    echo
    echo "$ make -f \$ENVDIR/istio-\${SERVICEMESH_VERSION}/tools/certs/Makefile.selfsigned.mk \$ENVDIR/istio-\${SERVICEMESH_VERSION}/cluster1-cacerts # to generate an intermediate certificate and key" | pv -qL 100
    echo
    echo "$ kubectl create secret generic cacerts -n istio-system --from-file=\$ENVDIR/istio-\${SERVICEMESH_VERSION}/cluster1/ca-cert.pem --from-file=\$ENVDIR/istio-\${SERVICEMESH_VERSION}/cluster1/ca-key.pem --from-file=\$ENVDIR/istio-\${SERVICEMESH_VERSION}/cluster1/root-cert.pem --from-file=\$ENVDIR/istio-\${SERVICEMESH_VERSION}/cluster1/cert-chain.pem # to create a secret cacerts" | pv -qL 100
    echo
    echo "$ \$ENVDIR/istio-\${SERVICEMESH_VERSION}/bin/istioctl install --set profile=asm-multicloud -y # to install Anthos Service Mesh" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},7"
    echo
    echo "$ curl -L \"https://storage.googleapis.com/gke-release/asm/istio-${SERVICEMESH_VERSION}-linux-amd64.tar.gz\" | tar xz -C $ENVDIR # to download the Anthos Service Mesh" | pv -qL 100
    curl -L "https://storage.googleapis.com/gke-release/asm/istio-${SERVICEMESH_VERSION}-linux-amd64.tar.gz" | tar xz -C $ENVDIR
    echo
    echo "$ kubectl create namespace istio-system # to create a namespace called istio-system" | pv -qL 100
    kubectl create namespace istio-system
    echo
    echo "$ make -f $ENVDIR/istio-${SERVICEMESH_VERSION}/tools/certs/Makefile.selfsigned.mk root-ca # to generate a root certificate and key" | pv -qL 100
    make -f $ENVDIR/istio-${SERVICEMESH_VERSION}/tools/certs/Makefile.selfsigned.mk root-ca
    echo
    echo "$ make -f $ENVDIR/istio-${SERVICEMESH_VERSION}/tools/certs/Makefile.selfsigned.mk $ENVDIR/istio-${SERVICEMESH_VERSION}/cluster1-cacerts # to generate an intermediate certificate and key" | pv -qL 100
    make -f $ENVDIR/istio-${SERVICEMESH_VERSION}/tools/certs/Makefile.selfsigned.mk $ENVDIR/istio-${SERVICEMESH_VERSION}/cluster1-cacerts
    echo
    echo "$ kubectl create secret generic cacerts -n istio-system --from-file=$ENVDIR/istio-${SERVICEMESH_VERSION}/cluster1/ca-cert.pem --from-file=$ENVDIR/istio-${SERVICEMESH_VERSION}/cluster1/ca-key.pem --from-file=$ENVDIR/istio-${SERVICEMESH_VERSION}/cluster1/root-cert.pem --from-file=$ENVDIR/istio-${SERVICEMESH_VERSION}/cluster1/cert-chain.pem # to create a secret cacerts" | pv -qL 100
    kubectl create secret generic cacerts -n istio-system --from-file=$ENVDIR/istio-${SERVICEMESH_VERSION}/cluster1/ca-cert.pem --from-file=$ENVDIR/istio-${SERVICEMESH_VERSION}/cluster1/ca-key.pem --from-file=$ENVDIR/istio-${SERVICEMESH_VERSION}/cluster1/root-cert.pem --from-file=$ENVDIR/istio-${SERVICEMESH_VERSION}/cluster1/cert-chain.pem
    echo
    echo "$ $ENVDIR/istio-${SERVICEMESH_VERSION}/bin/istioctl install --set profile=asm-multicloud -y # to install Anthos Service Mesh" | pv -qL 100
    $ENVDIR/istio-${SERVICEMESH_VERSION}/bin/istioctl install --set profile=asm-multicloud -y
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},7x"
    echo
    echo "$ kubectl delete controlplanerevision -n istio-system # to delete revision" | pv -qL 100
    kubectl delete controlplanerevision -n istio-system 2> /dev/null
    echo
    echo "$ kubectl delete validatingwebhookconfiguration,mutatingwebhookconfiguration -l operator.istio.io/component=Pilot # to delete configuration" | pv -qL 100
    kubectl delete validatingwebhookconfiguration,mutatingwebhookconfiguration -l operator.istio.io/component=Pilot 2> /dev/null
    echo
    echo "$ kubectl delete namespace istio-system asm-system --ignore-not-found=true # to delete namespace" | pv -qL 100
    kubectl delete namespace istio-system asm-system --ignore-not-found=true
    echo
    echo "$ kubectl delete namespace istio-system # to delete a namespace called istio-system" | pv -qL 100
    kubectl delete namespace istio-system --ignore-not-found=true 
    echo
    echo "$ kubectl delete secret cacerts -n istio-system # to delete secret cacerts" | pv -qL 100
    kubectl delete secret cacerts -n istio-system
    echo
    echo "$ $ENVDIR/istio-${SERVICEMESH_VERSION}/bin/istioctl x uninstall --purge -y # to uninstall istio" | pv -qL 100
    $ENVDIR/istio-${SERVICEMESH_VERSION}/bin/istioctl x uninstall --purge -y
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"8")
start=`date +%s`
source $ENVDIR/.env
case ${PLATFORM^^} in
    AWS)
        if [ $MODE -eq 1 ]; then
            echo
            echo "$ gcloud container aws clusters get-credentials \$CLUSTER_NAME --location \$AWS_LOCATION # to retrieve credentials" | pv -qL 100
            echo
            echo "$ \$PROJDIR/kubectx aws=. # to update context"
        else
            echo
            source $ENVDIR/AWS/AWS/vars.sh > /dev/null 2>&1
            echo "$ gcloud container aws clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION # to retrieve credentials" | pv -qL 100
            gcloud container aws clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION
            echo
            echo "$ $PROJDIR/kubectx aws=. # to update context"
            $PROJDIR/kubectx aws=.
        fi
    ;;
    AZURE)
        if [ $MODE -eq 1 ]; then
            echo
            echo "$ gcloud container azure clusters get-credentials \$CLUSTER_NAME --location \$AWS_LOCATION # to retrieve credentials" | pv -qL 100
            echo
            echo "$ \$PROJDIR/kubectx azure=. # to update context"
        else
            echo
            source $ENVDIR/AZURE/Azure/vars.sh > /dev/null 2>&1
            echo "$ gcloud container azure clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION # to retrieve credentials" | pv -qL 100
            gcloud container azure clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION
            echo
            echo "$ $PROJDIR/kubectx azure=. # to update context"
            $PROJDIR/kubectx azure=.
        fi
    ;;
    GCP)
        if [ $MODE -eq 1 ]; then
            echo
            echo "$ gcloud container clusters get-credentials gcp-gke-cluster --zone \$GCP_ZONE # to retrieve credentials for cluster" | pv -qL 100
            echo
            echo "$ \$PROJDIR/kubectx gcp=. # to update context"
       else
            echo
            echo "$ gcloud container clusters get-credentials gcp-gke-cluster --zone $GCP_ZONE # to retrieve credentials for cluster" | pv -qL 100
            gcloud container clusters get-credentials gcp-gke-cluster --zone $GCP_ZONE
            echo
            echo "$ $PROJDIR/kubectx gcp=. # to update context"
            $PROJDIR/kubectx gcp=.
        fi
    ;;
esac
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},8i"
    echo
    echo "$ kubectl create namespace hipster # to create namespace" | pv -qL 100
    echo
    echo "$ kubectl label namespace hipster istio-injection=enabled # to label namespaces for automatic sidecar injection" | pv -qL 100
    echo
    echo "$ kubectl -n hipster apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml # to deploy application" | pv -qL 100
    echo
    echo "$ kubectl -n hipster apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/istio-manifests.yaml # to configure gateway" | pv -qL 100
    echo
    echo "$ kubectl wait --for=condition=available --timeout=600s deployment --all -n hipster # to wait for the deployment to finish" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},8"
    echo
    echo "$ kubectl create namespace hipster # to create namespace" | pv -qL 100
    kubectl create namespace hipster
    echo
    echo "$ kubectl label namespace hipster istio-injection=enabled # to label namespaces for automatic sidecar injection" | pv -qL 100
    kubectl label namespace hipster istio-injection=enabled
    echo
    echo "$ kubectl -n hipster apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml # to deploy application" | pv -qL 100
    kubectl -n hipster apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
    echo
    echo "$ kubectl -n hipster apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/istio-manifests.yaml # to configure gateway" | pv -qL 100
    kubectl -n hipster apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/istio-manifests.yaml
    echo
    echo "$ kubectl wait --for=condition=available --timeout=600s deployment --all -n hipster # to wait for the deployment to finish" | pv -qL 100
    kubectl wait --for=condition=available --timeout=600s deployment --all -n hipster
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},8x"
    echo
    echo "$ kubectl delete namespace hipster # to delete namespace" | pv -qL 100
    kubectl delete namespace hipster 2> /dev/null
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"9")
start=`date +%s`
source $ENVDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},9i"   
    echo
    echo "$ git config --global credential.https://source.developers.google.com.helper gcloud. # to configure git" | pv -qL 100
    echo
    echo "$ git config --global user.email \"\$(gcloud config get-value account)\" # to configure git" | pv -qL 100
    echo
    echo "$ git config --global user.name \"USER\" # to configure git" | pv -qL 100
    echo
    echo "$ git config --global init.defaultBranch main # to set branch" | pv -qL 100
    echo
    echo "$ gcloud source repos create \${APPLICATION_NAME}-gke-repo --project \$GCP_PROJECT # to create repo" | pv -qL 100
    echo
    echo "$ gcloud source repos clone \${APPLICATION_NAME}-gke-repo --project \$GCP_PROJECT # to clone repo" | pv -qL 100
    echo
    echo "$ gcloud beta builds triggers create cloud-source-repositories --project \$GCP_PROJECT --name=\"\${APPLICATION_NAME}-gke-repo-trigger\" --repo=\${APPLICATION_NAME}-gke-repo --branch-pattern=main --build-config=cloudbuild.yaml # to configure trigger" | pv -qL 100
    echo
    echo "$ cd \${APPLICATION_NAME}-gke-repo # to change to repo directory" | pv -qL 100
    echo
    echo "$ cat <<EOF > Dockerfile
FROM golang:1.19.2 as builder
WORKDIR /app
RUN go mod init hello-app
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /hello-app
FROM gcr.io/distroless/base-debian11
WORKDIR /
COPY --from=builder /hello-app /hello-app
ENV PORT 8080
USER nonroot:nonroot
CMD [\"/hello-app\"]
EOF" | pv -qL 100
    echo
    echo "$ cat <<EOF > main.go
package main

import (
    \"fmt\"
    \"log\"
    \"net/http\"
    \"os\"
)

func main() {
    mux := http.NewServeMux()
    mux.HandleFunc(\"\/\", hello)

    port := os.Getenv(\"PORT\")
    if port == \"\" {
        port = \"8080\"
    }

    log.Printf(\"Server listening on port \%s\", port)
    log.Fatal(http.ListenAndServe(\":\"+port, mux))
}

func hello(w http.ResponseWriter, r *http.Request) {
    log.Printf(\"Serving request: \%s\", r.URL.Path)
    host, _ := os.Hostname()
    fmt.Fprintf(w, \"Hello, world!\\n\")
    fmt.Fprintf(w, \"Version: 1.0.0\\n\")
    fmt.Fprintf(w, \"Hostname: \%s\\n\", host)
}
EOF" | pv -qL 100
    echo
    echo "$ cat <<EOF > hello_app_deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloweb
  labels:
    app: hello
spec:
  selector:
    matchLabels:
      app: hello
      tier: web
  template:
    metadata:
      labels:
        app: hello
        tier: web
    spec:
      containers:
      - name: hello-app
        image: us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 200m
EOF" | pv -qL 100
    echo
    echo "$ cat <<EOF > hello_app_service.yaml
apiVersion: v1
kind: Service
metadata:
  name: helloweb
  labels:
    app: hello
    tier: web
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: hello
    tier: web
EOF" | pv -qL 100
    echo
    echo "$ git add . # to add directory" | pv -qL 100
    echo
    echo "$ git commit -m \"Added files\" # to commit change" | pv -qL 100
    echo
    echo "$ git push origin main # to push change to main" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},9"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1
    cd $ENVDIR
    echo
    echo "$ git config --global credential.https://source.developers.google.com.helper gcloud. # to configure git" | pv -qL 100
    git config --global credential.https://source.developers.google.com.helper gcloud.
    echo
    echo "$ git config --global user.email \"\$(gcloud config get-value account)\" # to configure git" | pv -qL 100
    git config --global user.email "$(gcloud config get-value account)" > /dev/null 2>&1
    echo
    echo "$ git config --global user.name \"USER\" # to configure git" | pv -qL 100
    git config --global user.name "USER" > /dev/null 2>&1 
    echo
    echo "$ git config --global init.defaultBranch main # to set branch" | pv -qL 100
    git config --global init.defaultBranch main
    echo
    gcloud source repos delete ${APPLICATION_NAME}-gke-repo --project $GCP_PROJECT --quiet > /dev/null 2>&1 
    echo "$ gcloud source repos create ${APPLICATION_NAME}-gke-repo --project $GCP_PROJECT # to create repo" | pv -qL 100
    gcloud source repos create ${APPLICATION_NAME}-gke-repo --project $GCP_PROJECT 2> /dev/null
    echo
    rm -rf ${APPLICATION_NAME}-gke-repo
    echo "$ gcloud source repos clone ${APPLICATION_NAME}-gke-repo --project $GCP_PROJECT # to clone repo" | pv -qL 100
    gcloud source repos clone ${APPLICATION_NAME}-gke-repo --project $GCP_PROJECT
    echo
    gcloud beta builds triggers delete cloud-source-repositories --project $GCP_PROJECT --quiet > /dev/null 2>&1 
    echo "$ gcloud beta builds triggers create cloud-source-repositories --project $GCP_PROJECT --name=\"${APPLICATION_NAME}-gke-repo-trigger\" --repo=${APPLICATION_NAME}-gke-repo --branch-pattern=main --build-config=cloudbuild.yaml # to configure trigger" | pv -qL 100
    gcloud beta builds triggers create cloud-source-repositories --project $GCP_PROJECT --name="${APPLICATION_NAME}-gke-repo-trigger" --repo=${APPLICATION_NAME}-gke-repo --branch-pattern=main --build-config=cloudbuild.yaml 2> /dev/null
    echo
    echo "$ cd ${APPLICATION_NAME}-gke-repo # to change to repo directory" | pv -qL 100
    cd ${APPLICATION_NAME}-gke-repo
    echo
    echo "$ cat <<EOF > Dockerfile
FROM golang:1.19.2 as builder
WORKDIR /app
RUN go mod init hello-app
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /hello-app
FROM gcr.io/distroless/base-debian11
WORKDIR /
COPY --from=builder /hello-app /hello-app
ENV PORT 8080
USER nonroot:nonroot
CMD [\"/hello-app\"]
EOF" | pv -qL 100
cat <<EOF > Dockerfile
FROM golang:1.19.2 as builder
WORKDIR /app
RUN go mod init hello-app
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /hello-app
FROM gcr.io/distroless/base-debian11
WORKDIR /
COPY --from=builder /hello-app /hello-app
ENV PORT 8080
USER nonroot:nonroot
CMD ["/hello-app"]
EOF
    echo
    echo "$ cat <<EOF > main.go
package main

import (
    \"fmt\"
    \"log\"
    \"net/http\"
    \"os\"
)

func main() {
    mux := http.NewServeMux()
    mux.HandleFunc(\"\/\", hello)

    port := os.Getenv(\"PORT\")
    if port == \"\" {
        port = \"8080\"
    }

    log.Printf(\"Server listening on port \%s\", port)
    log.Fatal(http.ListenAndServe(\":\"+port, mux))
}

func hello(w http.ResponseWriter, r *http.Request) {
    log.Printf(\"Serving request: \%s\", r.URL.Path)
    host, _ := os.Hostname()
    fmt.Fprintf(w, \"Hello, world!\\n\")
    fmt.Fprintf(w, \"Version: 1.0.0\\n\")
    fmt.Fprintf(w, \"Hostname: \%s\\n\", host)
}
EOF" | pv -qL 100
cat <<EOF > main.go
package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
)

func main() {
    mux := http.NewServeMux()
    mux.HandleFunc("/", hello)

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Server listening on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, mux))
}

func hello(w http.ResponseWriter, r *http.Request) {
    log.Printf("Serving request: %s", r.URL.Path)
    host, _ := os.Hostname()
    fmt.Fprintf(w, "Hello, world!\n")
    fmt.Fprintf(w, "Version: 1.0.0\n")
    fmt.Fprintf(w, "Hostname: %s\n", host)
}
EOF
    echo
    echo "$ cat <<EOF > hello_app_deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloweb
  labels:
    app: hello
spec:
  selector:
    matchLabels:
      app: hello
      tier: web
  template:
    metadata:
      labels:
        app: hello
        tier: web
    spec:
      containers:
      - name: hello-app
        image: us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 200m
EOF" | pv -qL 100
cat <<EOF > hello_app_deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloweb
  labels:
    app: hello
spec:
  selector:
    matchLabels:
      app: hello
      tier: web
  template:
    metadata:
      labels:
        app: hello
        tier: web
    spec:
      containers:
      - name: hello-app
        image: us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 200m
EOF
    echo
    echo "$ cat <<EOF > hello_app_service.yaml
apiVersion: v1
kind: Service
metadata:
  name: helloweb
  labels:
    app: hello
    tier: web
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: hello
    tier: web
EOF" | pv -qL 100
cat <<EOF > hello_app_service.yaml
apiVersion: v1
kind: Service
metadata:
  name: helloweb
  labels:
    app: hello
    tier: web
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: hello
    tier: web
EOF
    echo
    echo "$ git add . # to add directory" | pv -qL 100
    git add .
    echo
    echo "$ git commit -m \"Added files\" # to commit change" | pv -qL 100
    git commit -m "Added files"
    echo
    echo "$ git push origin main # to push change to main" | pv -qL 100
    git push origin main
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},7x"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1
    echo
    echo "$ gcloud beta builds triggers delete ${APPLICATION_NAME}-gke-repo-trigger --project $GCP_PROJECT # to delete trigger" | pv -qL 100
    gcloud beta builds triggers delete ${APPLICATION_NAME}-gke-repo-trigger --project $GCP_PROJECT 
    echo
    echo "*** DO NOT DELETE REPO IF YOU INTEND TO RE-RUN THIS LAB. DELETED REPOS CANNOT BE REUSED WITHIN 7 DAYS ***"
    echo
    echo "*** To delete repo, run command \"gcloud source repos delete ${APPLICATION_NAME}-gke-repo --project $GCP_PROJECT\" ***" | pv -qL 100
else
    export STEP="${STEP},9i"   
    echo
    echo " 1. Configure git" | pv -qL 100
    echo " 2. Set branch" | pv -qL 100
    echo " 3. Create repo" | pv -qL 100
    echo " 4. Configure trigger" | pv -qL 100
    echo " 5. Commit change" | pv -qL 100
    echo " 6. Push change to main" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"10")
start=`date +%s`
source $ENVDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},10i"   
    echo
    echo "$ git config --global credential.https://source.developers.google.com.helper gcloud. # to cinfigure git" | pv -qL 100
    echo
    echo "$ git config --global user.email \"\$(gcloud config get-value account)\" # to configure git" | pv -qL 100
    echo
    echo "$ git config --global user.name \"USER\" # to configure git" | pv -qL 100
    echo
    echo "$ git config --global init.defaultBranch main # to set branch" | pv -qL 100
    echo
    echo "$ cd \${APPLICATION_NAME}-gke-repo # to change to repo directory" | pv -qL 100
    echo
    echo "$ cat <<SKAFFOLD > skaffold.yaml
apiVersion: skaffold/v2beta25
kind: Config
build:
    artifacts:
        - image: gcr.io/\${GCP_PROJECT}/\${APPLICATION_NAME}
          context: ./
          docker:
            dockerfile: Dockerfile
deploy:
    kubectl:
        manifests:
            - hello_*
profiles:
    - name: cloudbuild
      build:
        googleCloudBuild:
            timeout: 3600s
            logStreamingOption: STREAM_OFF
SKAFFOLD" | pv -qL 100
        echo
        echo "$ cat <<EOF > clouddeploy.yaml
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
 name: \${APPLICATION_NAME}-gke-delivery
description: application gke delivery pipeline
serialPipeline:
 stages:
 - targetId: gcp
   profiles: []
 - targetId: azure
   profiles: []
 - targetId: aws
   profiles: []
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: gcp
description: GCP cluster
anthosCluster:
 membership: projects/\${GCP_PROJECT}/locations/global/memberships/\$GCP_CLUSTER
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: azure
description: Azure cluster
anthosCluster:
 membership: projects/\${GCP_PROJECT}/locations/global/memberships/\$AZURE_CLUSTER
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: aws
description: AWS cluster
requireApproval: true
anthosCluster:
 membership: projects/\${GCP_PROJECT}/locations/global/memberships/\$AWS_CLUSTER
EOF" | pv -qL 100
    echo
    echo "$ cat <<EOF > cloudbuild.yaml
steps:
  - name: gcr.io/k8s-skaffold/skaffold
    args:
      - skaffold
      - build
      - '--interactive=false'
      - '--file-output=/workspace/artifacts.json'
  - name: gcr.io/google.com/cloudsdktool/cloud-sdk
    entrypoint: gcloud
    args:
      [
        \"beta\", \"deploy\", \"releases\", \"create\", \"rel-\${SHORT_SHA}\",
        \"--delivery-pipeline\", \"\${APPLICATION_NAME}-gke-delivery\",
        \"--region\", \"\${GCP_REGION}\",
        \"--annotations\", \"commitId=\${REVISION_ID}\",
        \"--build-artifacts\", \"/workspace/artifacts.json\"
      ]
EOF" | pv -qL 100
    echo
    echo "$ gcloud beta deploy apply --file clouddeploy.yaml --region=\${GCP_REGION} --project=\${GCP_PROJECT} # to configure clouddeploy" | pv -qL 100
    echo
    echo "$ git add . # to add directory" | pv -qL 100
    echo
    echo "$ git commit -m \"Added files\" # to commit change" | pv -qL 100
    echo
    echo "$ git push origin main # to push change to main" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},10"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    gcloud config set compute/zone $GCP_ZONE > /dev/null 2>&1
    echo
    cd $ENVDIR
    echo "$ git config --global credential.https://source.developers.google.com.helper gcloud. # to cinfigure git" | pv -qL 100
    git config --global credential.https://source.developers.google.com.helper gcloud.
    echo
    echo "$ git config --global user.email \"\$(gcloud config get-value account)\" # to configure git" | pv -qL 100
    git config --global user.email "$(gcloud config get-value account)" > /dev/null 2>&1
    echo
    echo "$ git config --global user.name \"USER\" # to configure git" | pv -qL 100
    git config --global user.name "USER" > /dev/null 2>&1 
    echo
    echo "$ git config --global init.defaultBranch main # to set branch" | pv -qL 100
    git config --global init.defaultBranch main
    echo
    echo "$ cd ${APPLICATION_NAME}-gke-repo # to change to repo directory" | pv -qL 100
    cd ${APPLICATION_NAME}-gke-repo
    echo
    echo "$ cat <<SKAFFOLD > skaffold.yaml
apiVersion: skaffold/v2beta25
kind: Config
build:
    artifacts:
        - image: gcr.io/${GCP_PROJECT}/${APPLICATION_NAME}
          context: ./
          docker:
            dockerfile: Dockerfile
deploy:
    kubectl:
        manifests:
            - hello_*
profiles:
    - name: cloudbuild
      build:
        googleCloudBuild:
            timeout: 3600s
            logStreamingOption: STREAM_OFF
SKAFFOLD" | pv -qL 100
cat <<SKAFFOLD > skaffold.yaml
apiVersion: skaffold/v2beta25
kind: Config
build:
    artifacts:
        - image: gcr.io/${GCP_PROJECT}/${APPLICATION_NAME}
          context: ./
          docker:
            dockerfile: Dockerfile
deploy:
    kubectl:
        manifests:
            - hello_*
profiles:
    - name: cloudbuild
      build:
        googleCloudBuild:
            timeout: 3600s
            logStreamingOption: STREAM_OFF
SKAFFOLD
    echo
    source $ENVDIR/AZURE/Azure/vars.sh > /dev/null 2>&1
    echo "$ gcloud container azure clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION # to retrieve credentials" | pv -qL 100
    gcloud container azure clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION
    echo
    echo "$ kubectx azure=. # to update context"
    kubectx azure=.
    echo
    source $ENVDIR/AWS/AWS/vars.sh > /dev/null 2>&1
    echo "$ gcloud container aws clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION # to retrieve credentials" | pv -qL 100
    gcloud container aws clusters get-credentials $CLUSTER_NAME --location $AWS_LOCATION
    echo
    echo "$ kubectx aws=. # to update context"
    kubectx aws=.
    echo
    echo "$ gcloud container clusters get-credentials gcp-gke-cluster --zone $GCP_ZONE # to retrieve credentials for cluster" | pv -qL 100
    gcloud container clusters get-credentials gcp-gke-cluster --zone $GCP_ZONE
    echo
    echo "$ kubectx gcp=. # to update context"
    kubectx gcp=.
    export CLUSTER=$(kubectl config get-contexts | grep gke_aws_${GCP_PROJECT}_$AWS_LOCATION_ | awk '{print $3}' | head -n 1)
    export AWS_CLUSTER=$(echo "$CLUSTER" | rev | cut -d_ -f1 | rev)
    export CLUSTER=$(kubectl config get-contexts | grep gke_azure_${GCP_PROJECT}_$AWS_LOCATION_ | awk '{print $3}' | head -n 1)
    export AZURE_CLUSTER=$(echo "$CLUSTER" | rev | cut -d_ -f1 | rev)
    export GCP_CLUSTER=gcp-gke-cluster
    echo
    echo "$ cat <<EOF > clouddeploy.yaml
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
 name: ${APPLICATION_NAME}-gke-delivery
description: application gke delivery pipeline
serialPipeline:
 stages:
 - targetId: gcp
   profiles: []
 - targetId: azure
   profiles: []
 - targetId: aws
   profiles: []
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: gcp
description: GCP cluster
anthosCluster:
 membership: projects/${GCP_PROJECT}/locations/global/memberships/$GCP_CLUSTER
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: azure
description: Azure cluster
anthosCluster:
 membership: projects/${GCP_PROJECT}/locations/global/memberships/$AZURE_CLUSTER
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: aws
description: AWS cluster
requireApproval: true
anthosCluster:
 membership: projects/${GCP_PROJECT}/locations/global/memberships/$AWS_CLUSTER
EOF" | pv -qL 100
        cat <<EOF > clouddeploy.yaml
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
 name: ${APPLICATION_NAME}-gke-delivery
description: main application gke pipeline
serialPipeline:
 stages:
 - targetId: gcp
   profiles: []
 - targetId: azure
   profiles: []
 - targetId: aws
   profiles: []
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: gcp
description: GCP cluster
anthosCluster:
 membership: projects/${GCP_PROJECT}/locations/global/memberships/$GCP_CLUSTER
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: azure
description: Azure cluster
anthosCluster:
 membership: projects/${GCP_PROJECT}/locations/global/memberships/$AZURE_CLUSTER
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: aws
description: AWS cluster
requireApproval: true
anthosCluster:
 membership: projects/${GCP_PROJECT}/locations/global/memberships/$AWS_CLUSTER
EOF
    echo
    echo "$ cat <<EOF > cloudbuild.yaml
steps:
  - name: gcr.io/k8s-skaffold/skaffold
    args:
      - skaffold
      - build
      - '--interactive=false'
      - '--file-output=/workspace/artifacts.json'
  - name: gcr.io/google.com/cloudsdktool/cloud-sdk
    entrypoint: gcloud
    args:
      [
        \"beta\", \"deploy\", \"releases\", \"create\", \"rel-\${SHORT_SHA}\",
        \"--delivery-pipeline\", \"${APPLICATION_NAME}-gke-delivery\",
        \"--region\", \"${GCP_REGION}\",
        \"--annotations\", \"commitId=\${REVISION_ID}\",
        \"--build-artifacts\", \"/workspace/artifacts.json\"
      ]
EOF" | pv -qL 100
    cat <<EOF > cloudbuild.yaml
steps:
  - name: gcr.io/k8s-skaffold/skaffold
    args:
      - skaffold
      - build
      - '--interactive=false'
      - '--file-output=/workspace/artifacts.json'
  - name: gcr.io/google.com/cloudsdktool/cloud-sdk
    entrypoint: gcloud
    args:
      [
        "beta", "deploy", "releases", "create", "rel-\${SHORT_SHA}",
        "--delivery-pipeline", "${APPLICATION_NAME}-gke-delivery",
        "--region", "${GCP_REGION}",
        "--annotations", "commitId=\${REVISION_ID}",
        "--build-artifacts", "/workspace/artifacts.json"
      ]
EOF
    echo
    echo "$ gcloud beta deploy apply --file clouddeploy.yaml --region=${GCP_REGION} --project=${GCP_PROJECT} # to configure clouddeploy" | pv -qL 100
    gcloud beta deploy apply --file clouddeploy.yaml --region=${GCP_REGION} --project=${GCP_PROJECT}
    echo
    echo "$ git add . # to add directory" | pv -qL 100
    git add .
    echo
    echo "$ git commit -m \"Added files\" # to commit change" | pv -qL 100
    git commit -m "Added files"
    echo
    echo "$ git push origin main # to push change to main" | pv -qL 100
    git push origin main
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},10x"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ gcloud beta deploy delete --file $ENVDIR/${APPLICATION_NAME}-gke-repo/clouddeploy.yaml --region=${GCP_REGION} --project=${GCP_PROJECT} --force # to delete configuration" | pv -qL 100
    gcloud beta deploy delete --file $ENVDIR/${APPLICATION_NAME}-gke-repo/clouddeploy.yaml --region=${GCP_REGION} --project=${GCP_PROJECT} --force 
else
    export STEP="${STEP},10i"   
    echo
    echo " 1. Set service account" | pv -qL 100
    echo " 2. Grant role" | pv -qL 100
    echo " 3. Assign role" | pv -qL 100
    echo " 4. Configure clouddeploy" | pv -qL 100
    echo " 5. Commit change" | pv -qL 100
    echo " 6. Push change to main" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"R")
echo
echo "
  __                      __                              __                               
 /|            /         /              / /              /                 | /             
( |  ___  ___ (___      (___  ___        (___           (___  ___  ___  ___|(___  ___      
  | |___)|    |   )     |    |   )|   )| |    \   )         )|   )|   )|   )|   )|   )(_/_ 
  | |__  |__  |  /      |__  |__/||__/ | |__   \_/       __/ |__/||  / |__/ |__/ |__/  / / 
                                 |              /                                          
"
echo "
We are a group of information technology professionals committed to driving cloud 
adoption. We create cloud skills development assets during our client consulting 
engagements, and use these assets to build cloud skills independently or in partnership 
with training organizations.
 
You can access more resources from our iOS and Android mobile applications.

iOS App: https://apps.apple.com/us/app/tech-equity/id1627029775
Android App: https://play.google.com/store/apps/details?id=com.techequity.app

Email:support@techequity.cloud 
Web: https://techequity.cloud

Ⓒ Tech Equity 2022" | pv -qL 100
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;
 
"G")
cloudshell launch-tutorial $SCRIPTPATH/.tutorial.md  > /dev/null 2>&1
;;

"Q")
echo
exit
;;
"q")
echo
exit
;;
* )
echo
echo "Option not available"
;;
esac
sleep 1
done
