#!/bin/bash
# Default variables
function="install"
source="false"

# Options
. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/Logo_Alex845.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script performs many actions related to a Massa node"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,  --help        show the help page"
		echo -e "  -op, --open-ports  open required ports"
		echo -e "  -s,  --source      install the node using a source code"
		echo -e "  -un, --uninstall   unistall the node"
		echo
		echo -e "You can use either \"=\" or \" \" as an option and value ${C_LGn}delimiter${RES}"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/Phantom1605/Massa/blob/main/Massa_installer.sh - script URL"
		echo
		return 0
		;;
	-op|--open-ports)
		function="open_ports"
		shift
		;;
	-s|--source)
		function="install_source"
		shift
		;;
	-un|--uninstall)
		function="uninstall"
		shift
		;;
	*|--)
		break
		;;
	esac
done

# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
open_ports() {
	sudo systemctl stop massad
	. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/secondary/opening_ports.sh) 31244 31245
	sudo tee <<EOF >/dev/null $HOME/massa/massa-node/config/config.toml
[network]
routable_ip = "`wget -qO- eth0.me`"
EOF
	sudo apt install net-tools -y
	netstat -ntlp | grep "massa-node"
	sudo systemctl restart massad
}
update() {
	printf_n "${C_LGn}Node updating...${RES}"
	if [ ! -n "$massa_password" ]; then
		printf_n "\n${C_R}There is no massa_password variable with the password, enter it to save it in the variable!${RES}"
		. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/Massa/main/insert-variables.sh) -n massa_password
	fi
	if [ ! -n "$massa_password" ]; then
		printf_n "${C_R}There is no massa_password variable with the password!${RES}\n"
		return 1 2>/dev/null; exit 1
	fi
	mkdir -p $HOME/massa_backup
	if [ ! -f $HOME/massa_backup/wallet.dat ]; then
		sudo cp $HOME/massa/massa-client/wallet.dat $HOME/massa_backup/wallet.dat
	fi
	if [ ! -f $HOME/massa_backup/node_privkey.key ]; then
		sudo cp $HOME/massa/massa-node/config/node_privkey.key $HOME/massa_backup/node_privkey.key
	fi
	if grep -q "wrong password" <<< `cd $HOME/massa/massa-client/; ./massa-client -p "$massa_password" 2>&1; cd`; then
		printf_n "\n${C_R}Wrong password!${RES}\n"
		return 1 2>/dev/null; exit 1
	fi
	local massa_version=`wget -qO- https://api.github.com/repos/massalabs/massa/releases/latest | jq -r ".tag_name"`
	wget -qO $HOME/massa.tar.gz "https://github.com/massalabs/massa/releases/download/TEST.13.0/massa_TEST.13.0_release_linux.tar.gz"
	if [ `wc -c < "$HOME/massa.tar.gz"` -ge 1000 ]; then
		rm -rf $HOME/massa/
		tar -xvf $HOME/massa.tar.gz
		chmod +x $HOME/massa/massa-node/massa-node $HOME/massa/massa-client/massa-client
		printf "[Unit]
Description=Massa Node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/massa/massa-node
ExecStart=$HOME/massa/massa-node/massa-node -p "$massa_password"
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/massad.service
		sudo systemctl enable massad
		sudo systemctl daemon-reload
		sudo cp $HOME/massa_backup/node_privkey.key $HOME/massa/massa-node/config/node_privkey.key
		open_ports
		cd $HOME/massa/massa-client/
		sudo cp $HOME/massa_backup/wallet.dat $HOME/massa/massa-client/wallet.dat
		. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/Massa/main/insert-variables.sh)
		cd
		. <(https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/Logo_Alex845.sh)
		printf_n "
The node was ${C_LGn}updated${RES}.
\tv ${C_LGn}Useful commands${RES} v
To run a client: ${C_LGn}massa_client${RES}
To view the node status: ${C_LGn}sudo systemctl status massad${RES}
To view the node log: ${C_LGn}massa_log${RES}
To restart the node: ${C_LGn}sudo systemctl restart massad${RES}
CLI client commands (use ${C_LGn}massa_cli_client -h${RES} to view the help page):
${C_LGn}`compgen -a | grep massa_ | sed "/massa_log/d"`${RES}
"
	else
		printf_n "${C_LR}Archive with binary downloaded unsuccessfully!${RES}\n"
	fi
	rm -rf $HOME/massa.tar.gz
}
install() {
	if [ -d $HOME/massa/ ]; then
		update
	else
                if [ ! -n "$massa_password" ]; then
			printf_n "\n${C_LGn}Come up with a password to encrypt the keys and enter it.${RES}"
			. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/Massa/main/insert-variables.sh) -n massa_password
		fi
		if [ ! -n "$massa_password" ]; then
			printf_n "${C_R}There is no massa_password variable with the password!${RES}\n"
			return 1 2>/dev/null; exit 1
		fi
		sudo apt update
		sudo apt upgrade -y
		sudo apt install jq curl pkg-config git build-essential libssl-dev -y
		printf_n "${C_LGn}Node installation...${RES}"
		local massa_version=`wget -qO- https://api.github.com/repos/massalabs/massa/releases/latest | jq -r ".tag_name"`
		wget -qO $HOME/massa.tar.gz "https://github.com/massalabs/massa/releases/download/TEST.13.0/massa_TEST.13.0_release_linux.tar.gz"
		if [ `wc -c < "$HOME/massa.tar.gz"` -ge 1000 ]; then
			tar -xvf $HOME/massa.tar.gz
			rm -rf $HOME/massa.tar.gz
			chmod +x $HOME/massa/massa-node/massa-node $HOME/massa/massa-client/massa-client
			printf "[Unit]
Description=Massa Node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/massa/massa-node
ExecStart=$HOME/massa/massa-node/massa-node -p "$massa_password"
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/massad.service
			sudo systemctl enable massad
			sudo systemctl daemon-reload
			open_ports
			cd $HOME/massa/massa-client/
			if [ ! -d $HOME/massa_backup ]; then
				./massa-client wallet_generate_private_key
			else
				sudo cp $HOME/massa_backup/node_privkey.key $HOME/massa/massa-node/config/node_privkey.key
				sudo systemctl restart massad
				sudo cp $HOME/massa_backup/wallet.dat $HOME/massa/massa-client/wallet.dat	
			fi
			. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/Massa/main/insert-variables.sh)
			if [ ! -d $HOME/massa_backup ]; then
				mkdir $HOME/massa_backup
				sudo cp $HOME/massa/massa-client/wallet.dat $HOME/massa_backup/wallet.dat
				sudo cp $HOME/massa/massa-node/config/node_privkey.key $HOME/massa_backup/node_privkey.key
			fi
			printf_n "${C_LGn}Done!${RES}"
			cd
			. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/Logo_Alex845.sh)
			printf_n "
The node was ${C_LGn}started${RES}.
Remember to save files in this directory:
${C_LR}$HOME/massa_backup/${RES}
And password for decryption: ${C_LR}${massa_password}${RES}
\tv ${C_LGn}Useful commands${RES} v
To run a client: ${C_LGn}massa_client${RES}
To view the node status: ${C_LGn}sudo systemctl status massad${RES}
To view the node log: ${C_LGn}massa_log${RES}
To restart the node: ${C_LGn}sudo systemctl restart massad${RES}
CLI client commands (use ${C_LGn}massa_cli_client -h${RES} to view the help page):
${C_LGn}`compgen -a | grep massa_ | sed "/massa_log/d"`${RES}
"
		else
			rm -rf $HOME/massa.tar.gz
			printf_n "${C_LR}Archive with binary downloaded unsuccessfully!${RES}\n"
		fi
	fi
}
install_source() {
	if [ -d $HOME/massa/ ]; then
		printf_n "${C_LR}Node already installed!${RES}"
	else
		sudo apt update
		sudo apt upgrade -y
		sudo apt install jq curl pkg-config git build-essential libssl-dev -y
		printf_n "${C_LGn}Node installation...${RES}"
		. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/installation_packages/rust.sh) -n
		if [ ! -d $HOME/massa/ ]; then
			git clone --branch testnet https://gitlab.com/massalabs/massa.git
		fi
		cd $HOME/massa/massa-node/
		RUST_BACKTRACE=full cargo build --release
		printf "[Unit]
Description=Massa Node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/massa/massa-node
ExecStart=$HOME/massa/target/release/massa-node
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/massad.service
		sudo systemctl enable massad
		sudo systemctl daemon-reload
		open_ports
		printf_n "
${C_LGn}Done!${RES}
${C_LGn}Client installation...${RES}
"
		cd $HOME/massa/massa-client/
		cargo run --release wallet_new_privkey
		. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/secondary/insert-variable.sh) -n massa_log -v "sudo journalctl -f -n 100 -u massad" -a
	fi
	printf_n "${C_LGn}Done!${RES}"
	cd
	. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/Logo_Alex845.sh)
	printf_n "
The node was ${C_LGn}started${RES}.
Remember to save files in this directory:
${C_LR}$HOME/massa_backup/${RES}
\tv ${C_LGn}Useful commands${RES} v
To run a client: ${C_LGn}massa_client${RES}
To view the node status: ${C_LGn}sudo systemctl status massad${RES}
To view the node log: ${C_LGn}massa_log${RES}
To restart the node: ${C_LGn}sudo systemctl restart massad${RES}
CLI client commands (use ${C_LGn}massa_cli_client -h${RES} to view the help page):
${C_LGn}`compgen -a | grep massa_ | sed "/massa_log/d"`${RES}
"
}
uninstall() {
	sudo systemctl stop massad
	if [ ! -d $HOME/massa_backup ]; then
		mkdir $HOME/massa_backup
		sudo cp $HOME/massa/massa-client/wallet.dat $HOME/massa_backup/wallet.dat
		sudo cp $HOME/massa/massa-node/config/node_privkey.key $HOME/massa_backup/node_privkey.key
	fi
	if [ -f $HOME/massa_backup/wallet.dat ] && [ -f $HOME/massa_backup/node_privkey.key ]; then
		rm -rf $HOME/massa/ /etc/systemd/system/massa.service /etc/systemd/system/massad.service
		sudo systemctl daemon-reload
		. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/secondary/insert-variable.sh) -n massa_log -da
		. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/secondary/insert-variable.sh) -n massa_client -da
		. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/secondary/insert-variable.sh) -n massa_cli_client -da
		. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/secondary/insert-variable.sh) -n massa_node_info -da
		. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/secondary/insert-variable.sh) -n massa_wallet_info -da
		. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/secondary/insert-variable.sh) -n massa_buy_rolls -da
		printf_n "${C_LGn}Done!${RES}"
	else
		printf_n "${C_LR}No backup of the necessary files was found, delete the node manually!${RES}"
	fi	
}

# Actions
sudo apt install wget -y &>/dev/null
. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/blocks-for-scripts/main/Logo_Alex845.sh)
cd
$function
