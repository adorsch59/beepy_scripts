# beepy_scripts
helpful scripts for beepy

#1 alias for menu2.sh
`nano ~/.zshrc`

`alias menu='cd/home/user/beepy_scripts && zsh menu2.sh'`

`source ~/.zshrc`

#1 install sideButton.py as a service
create /etc/systemd/system/sideButton.service
`sudo cp sideButton.service /etc/systemd/system/sideButton.service`

`sudo systemctl daemon-reload`

`sudo systemctl enable sideButton.service`

`sudo systemctl start sideButton.service`

`sudo systemctl status sideButton.service`
