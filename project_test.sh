#!/bin/bash

docker_compose_file_name="assignment_compose.yml"

director_folder_name="director"
chunk_creator_folder_name="chunk_creator"
cloner_worker_folder_name="cloner_worker"
# cloner_rate_limiter_folder_name="cloner_rate_limiter"

function check_if_project_folder_exists() {
    local folder_name=$1
    if test -d "${folder_name}"; then
        echo "OK: Directory ${folder_name} exists. Good job."
    else
        echo "ERROR: Make a project with the \"${folder_name}\" project name!"
    fi
}

function check_if_mix_project() {
    local folder_name=$1
    cd $folder_name
    if test -f "mix.exs"; then
        echo "OK: ${folder_name} is a mix project. Good job."
    else
        echo "ERROR: \"${folder_name}\" is not a mix project!"
    fi
    cd ..
}

function check_if_docker_compose_file_is_present() {
    if test -f "${docker_compose_file_name}"; then
        echo "OK: you have a docker compose file. Good job."
    else
        echo "ERROR: Make a docker compose file called ${docker_compose_file_name}!"
    fi
}

# Project folder checks
check_if_project_folder_exists $director_folder_name
check_if_project_folder_exists $chunk_creator_folder_name
check_if_project_folder_exists $cloner_worker_folder_name
# check_if_project_folder_exists $cloner_rate_limiter_folder_name

# Mix project checks
check_if_mix_project $director_folder_name
check_if_mix_project $chunk_creator_folder_name
check_if_mix_project $cloner_worker_folder_name
# check_if_mix_project $cloner_rate_limiter_folder_name

# Check if project docker compose file is present
check_if_docker_compose_file_is_present
