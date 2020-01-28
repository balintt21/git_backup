# git_backup
Bash script to create backup of bare git repositories from a remote host

# usage
Usage: ./git_backup.sh [OPTIONS] <[user@]hostname> <path_to_repositories>
Description: Clones every repository from a remote git server via ssh as bare repository.
             Compresses all of them into one archive file.
Options:
	-p <ssh_port> SSH port number
	-o <DIR> Output destination. By default it is the current directory.
	-h, --help Show this message

