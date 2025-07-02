# beepy_scripts
helpful scripts for beepy

#1 alias for menu2.sh
`nano ~/.zshrc`

`alias menu='cd/home/user/beepy_scripts && zsh menu2.sh'`

`source ~/.zshrc`

#1 install sideButton.py as a service
create /etc/systemd/system/sideButton.service
```

```
`systemctl daemon-reload`

`systemctl enable sideButton.service`

`systemctl start sideButton.service`

`systemctl status sideButton.service`
