#!/usr/bin/env zsh

script_absolute_path=$(cd $(dirname $0); pwd)
dotfiles_dir="${script_absolute_path}/dotfiles"

function backup_config_file(){
	if [ -e ~/.$1 ]; then
		mv ~/.$1 ~/.config_backup_`date +"%Y%m%d"`/.
	fi
}

function make_config_symlink(){
	real_path="${dotfiles_dir}/$1"
	if [ -e $real_path ]; then
		ln -s $real_path ~/.$1
	fi
}

function back_and_make(){
	backup_config_file $1
	make_config_symlink $1
}

mkdir ~/.config_backup_`date +"%Y%m%d"`

echo $dotfiles_dir
for dotfile in `\ls -A $dotfiles_dir`
do
	back_and_make $dotfile
done
