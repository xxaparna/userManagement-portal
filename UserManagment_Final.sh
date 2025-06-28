#!/bin/bash

# Check root privileges
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root."
  exit 1
fi

# === BANNER ===
show_banner() {
  clear
  echo "===================================================="
  echo "            🔐 USER MANAGEMENT SYSTEM 🔐            "
  echo "              Created by Team                      "
  echo "===================================================="
  sleep 2
}

# === MAIN MENU ===
main_menu() {
  while true; do
    CHOICE=$(dialog --clear --backtitle "User Management System" --title "User Management System" \
      --menu "Choose an option:" 20 60 12 \
      1 "Add User" \
      2 "Delete User" \
      3 "View All Users" \
      4 "Lock User" \
      5 "Unlock User" \
      6 "Edit User" \
      7 "Check if User Exists" \
      8 "Show Account Status" \
      9 "Set Password Expiration" \
      10 "Exit" \
      2>&1 >/dev/tty)

    clear || break
    [ $? -ne 0 ] && break

    case $CHOICE in
      1) add_user ;;
      2) delete_user ;;
      3) view_users ;;
      4) lock_user ;;
      5) unlock_user ;;
      6) edit_user_menu ;;
      7) check_user ;;
      8) show_status ;;
      9) set_password_expiration ;;
      10) exit 0 ;;
      *) dialog --msgbox "Invalid option" 10 50 ;;
    esac
  done
}

# === FUNCTIONS ===

add_user() {
  user=$(dialog --inputbox "Enter new username:" 12 50 2>&1 >/dev/tty) || return
  pass=$(dialog --insecure --passwordbox "Enter password:" 12 50 2>&1 >/dev/tty) || return
  useradd -m "$user"
  echo "$user:$pass" | chpasswd
  dialog --msgbox "User '$user' added." 10 50
}

delete_user() {
  user=$(dialog --inputbox "Enter username to delete:" 12 50 2>&1 >/dev/tty) || return
  userdel -r "$user"
  dialog --msgbox "User '$user' deleted." 10 50
}

view_users() {
  users=$(cut -d: -f1 /etc/passwd)
  dialog --msgbox "=== System Users ===\n$users" 22 60
}

lock_user() {
  user=$(dialog --inputbox "Enter username to lock:" 12 50 2>&1 >/dev/tty) || return
  usermod -L "$user"
  dialog --msgbox "User '$user' locked." 10 50
}

unlock_user() {
  user=$(dialog --inputbox "Enter username to unlock:" 12 50 2>&1 >/dev/tty) || return
  usermod -U "$user"
  dialog --msgbox "User '$user' unlocked." 10 50
}

check_user() {
  user=$(dialog --inputbox "Enter username to check:" 12 50 2>&1 >/dev/tty) || return
  if id "$user" &>/dev/null; then
    dialog --msgbox "User '$user' exists." 10 50
  else
    dialog --msgbox "User '$user' does NOT exist." 10 50
  fi
}

show_status() {
  user=$(dialog --inputbox "Enter username to check status:" 12 50 2>&1 >/dev/tty) || return
  status=$(passwd -S "$user")
  dialog --msgbox "$status" 10 60
}

set_password_expiration() {
  user=$(dialog --inputbox "Enter username to set password expiration for:" 12 60 2>&1 >/dev/tty) || return
  if ! id "$user" &>/dev/null; then
    dialog --msgbox "User '$user' does not exist." 10 50
    return
  fi

  days=$(dialog --inputbox "Enter number of days until password expires:" 12 60 2>&1 >/dev/tty) || return
  chage -M "$days" "$user"
  dialog --msgbox "Password expiration set to $days days for user '$user'." 10 60
}

edit_user_menu() {
  user=$(dialog --inputbox "Enter username to edit:" 12 50 2>&1 >/dev/tty) || return
  if ! id "$user" &>/dev/null; then
    dialog --msgbox "User '$user' does not exist." 10 50
    return
  fi

  while true; do
    opt=$(dialog --clear --backtitle "Edit User: $user" --title "Edit User Menu" \
      --menu "Choose an option:" 18 60 8 \
      a "Change Username" \
      b "Change Password" \
      c "Change Home Directory" \
      d "Disable Shell Access" \
      e "View Last Login Time" \
      f "Back to Main Menu" \
      2>&1 >/dev/tty)

    clear || break
    [ $? -ne 0 ] && break

    case $opt in
      a) change_username "$user"; return ;;
      b) change_password "$user" ;;
      c) change_home "$user" ;;
      d) disable_shell "$user" ;;
      e) view_last_login "$user" ;;
      f) return ;;
      *) dialog --msgbox "Invalid option" 10 50 ;;
    esac
  done
}

change_username() {
  old_user=$1
  new_user=$(dialog --inputbox "Enter new username:" 12 50 2>&1 >/dev/tty) || return
  usermod -l "$new_user" "$old_user"
  usermod -d "/home/$new_user" -m "$new_user"
  dialog --msgbox "Username changed from '$old_user' to '$new_user'." 10 60
}

change_password() {
  user=$1
  pass=$(dialog --insecure --passwordbox "Enter new password:" 12 50 2>&1 >/dev/tty) || return
  echo "$user:$pass" | chpasswd
  dialog --msgbox "Password updated for '$user'." 10 50
}

change_home() {
  user=$1
  new_home=$(dialog --inputbox "Enter new home directory path:" 12 50 2>&1 >/dev/tty) || return
  usermod -d "$new_home" -m "$user"
  dialog --msgbox "Home directory for '$user' changed to '$new_home'." 10 60
}

disable_shell() {
  user=$1
  usermod -s /usr/sbin/nologin "$user"
  dialog --msgbox "Shell access disabled for '$user'." 10 60
}

view_last_login() {
  user=$1
  login_time=$(last -n 1 "$user" | head -n 1)
  if [[ -z "$login_time" ]]; then
    login_time="No login record found for user '$user'."
  fi
  dialog --msgbox "$login_time" 12 70
}

# Start script
show_banner
main_menu
