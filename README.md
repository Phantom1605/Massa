# Massa
This is a script for installing Massa Protocol
The script is relevant for the testnet network 10.1

Run the script by command:
```
. <(wget -qO- https://raw.githubusercontent.com/Phantom1605/Massa/main/Massa_installer.sh
```
1. Join to Discord. 
2. Go to the testnet-rewards - registration chat and write any message.
3. Send your server Ip to the massa bot.
4. On the server, run the command and enter the Discord ID issued by the massa bot:
```
massa_cli_client -a node_testnet_rewards_program_ownership_proof
```
5. The value output by the command is send to the massa bot
6. Send the wallet address to the testnet-faucet channel, which can be viewed using the command
```
massa_wallet_info
```
7. Buy rolls to participate in the tetnet by command:
```
massa_buy_rolls -mb
```
8. Enable the option of stacking for the wallet by the command:
```
massa_cli_client -a node_add_staking_private_keys
```
9. To view information about your node, you can use the command:
```
massa_node_info
```

Links:

GitHub - https://github.com/massalabs/massa

URL - https://massa.net

