tick="✓"
cross="✗"

step_log() {
  message=$1
  printf "\n\033[90;1m==> \033[0m\033[37;1m%s\033[0m\n" "$message"
}

add_log() {
  mark=$1
  subject=$2
  message=$3
  if [ "$mark" = "$tick" ]; then
    printf "\033[32;1m%s \033[0m\033[34;1m%s \033[0m\033[90;1m%s\033[0m\n" "$mark" "$subject" "$message"
  else
    printf "\033[31;1m%s \033[0m\033[34;1m%s \033[0m\033[90;1m%s\033[0m\n" "$mark" "$subject" "$message"
  fi
}

step_log "Setup PHP and Composer"
version=$1
export HOMEBREW_NO_INSTALL_CLEANUP=TRUE
brew tap shivammathur/homebrew-php 
brew install shivammathur/php/php@"$1" composer 
brew link --force --overwrite php@"$1" 
ini_file=$(php -d "date.timezone=UTC" --ini | grep "Loaded Configuration" | sed -e "s|.*:s*||" | sed "s/ //g")
echo "date.timezone=UTC" >> "$ini_file"
ext_dir=$(php -i | grep "extension_dir => /usr" | sed -e "s|.*=> s*||")
sudo chmod 777 "$ini_file"
mkdir -p "$(pecl config-get ext_dir)"
composer global require hirak/prestissimo 
semver=$(php -v | head -n 1 | cut -f 2 -d ' ')
add_log "$tick" "PHP" "Installed PHP $semver"
add_log "$tick" "Composer" "Installed"

add_extension() {
  extension=$1
  install_command=$2
  prefix=$3
  if ! php -m | grep -i -q "$extension" && [ -e "$ext_dir/$extension.so" ]; then
    echo "$prefix=$extension" >>"$ini_file" && add_log $tick "$extension" "Enabled"
  elif php -m | grep -i -q "$extension"; then
    add_log "$tick" "$extension" "Enabled"
  elif ! php -m | grep -i -q "$extension"; then
    exists=$(curl -sL https://pecl.php.net/json.php?package="$extension" -w "%{http_code}" -o /dev/null)
    if [ "$exists" = "200" ]; then
      (
        eval "$install_command" && \
        add_log "$tick" "$extension" "Installed and enabled"
      ) || add_log "$cross" "$extension" "Could not install $extension on PHP $semver"
    else
      if ! php -m | grep -i -q "$extension"; then
        add_log "$cross" "$extension" "Could not find $extension for PHP $semver on PECL"
      fi
    fi
  fi
}