#!/usr/bin/env bash

#args
url=""
port="22"
remote_path=""
output_path="./"
output_filename=""
date=""
repositories=""
#functions
usage_text()
{
    echo -e "Usage: $1 [OPTIONS] <[user@]hostname> <path_to_repositories>"
    echo -e "Description: Clones every repository from a remote git server via ssh as bare repository.\n             Compresses all of them into one archive file."
    echo -e "Options:\n\t-p <ssh_port> SSH port number\n\t-o <DIR> Output destination. By default it is the current directory.\n\t-h, --help Show this message\n"
}

print_usage()
{
    type -a usage_text > /dev/null
    if [ "$?" -eq 0 ]; then
        echo "$@" | grep -qP "(-h|--help)"
        if [ "$?" -eq 0 ] || [ "$#" -lt 2 ]; then
            usage_text $0
            exit 0
        fi
    fi
}

print_info()
{
    echo "date:     $date"
    echo "ssh:      -p $port $url"
    echo "remote:   $remote_path"
    echo "local:    $output_path/$output_filename"
    echo -e "\nrepositories:"
    for repo in $repositories; do
        echo -e "\t$repo"
    done
}

parse_args()
{
    if [ "$#" -gt 1 ]; then
        local param=""
        local prev=""
        local next=""
        local args="$@"
        while [ -n "$args" ]; do
            case $param in
            -p)
            port=$1
            ;;
            -o)
            output_path=$1
            ;;
            *)
            ;;
            esac
            if [ "$1" == "-p" ] || [ "$1" == "-o" ]; then
                param="$1"
            else
                param=""
            fi
            if [ "$(echo $@ | wc -w)" == 2 ]; then
                url="$1"
                remote_path="$2"
            fi
            shift
            args="$@"
        done
    fi
    date=$(date +%Y-%m-%d-%H-%M)
    output_filename=$(echo "$url" | cut -d'@' -f2)
    output_filename="$output_filename""_""$date"
}

check_source()
{
    if [ -n "$url" ]; then
        echo "check connection: ssh -p $port $url git version"
        ssh -p "$port" "$url" git version
        if [ "$?" -ne 0 ]; then
            exit $?
        fi
    fi
}

clone_repositories()
{
    echo -e "\nclone repositories:"
    if [ -z "$repositories" ]; then
        echo "error: remote directory is empty!"
        exit 2
    fi
    curr_dir=$(pwd)
    tmp_dir="$output_path/git_backup_$date"
    mkdir -p "$tmp_dir"
    if [ "$?" -eq 0 ]; then
        print_info > "$tmp_dir/backup.info"
        cd "$tmp_dir"
        for repo in $repositories; do
            ssh -p "$port" "$url" ls -l "$remote_path/$repo/HEAD" > /dev/null
            if [ "$?" -eq 0  ]; then
                local rep_cfg=$(ssh -p "$port" "$url" cat "$remote_path/$repo/config")
                if [ -n "$rep_cfg" ]; then
                    echo "$rep_cfg" | grep -o "bare" > /dev/null
                    if [ "$?" -eq 0  ]; then
                        echo "cloning ssh://$url:$port/$remote_path/$repo"
                        git clone --bare "ssh://$url:$port/$remote_path/$repo"
                        if [ "$?" -ne 0 ]; then
                            echo "error: failed to clone $repo"
                        fi
                        echo ""
                    else
                        echo "error: $repo is not bare repository!"
                    fi
                fi
            fi
        done
        cd "$curr_dir"
        tar -cJf "$output_path/$output_filename.tar.xz" -C "$tmp_dir" .
    fi
    rm -rf "$tmp_dir"
}

print_usage "$@"
parse_args "$@"
check_source
repositories=$(ssh -p "$port" "$url" ls $remote_path)
print_info
clone_repositories
