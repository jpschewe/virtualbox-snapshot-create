# virtualbox-snapshot-create
Shell script to create a virtualbox snapshot and delete old snapshots.

# Scheduling with Linux and systemctl

Put the following in `~/.config/systemd/user/maintain-virtualbox-snapshots.service`

    [Unit]
    Description=Snapshot Virtualbox and cleanup old snapshots
    
    [Service]
    Type=oneshot
    ExecStart=/home/..../bin/virtualbox-snapshot-create/maintain-virtualbox-backups.sh 1 7

Put the following in `~/.config/systemd/user/maintain-virtualbox-snapshots.timer`

    [Unit]
    Description=Run maintain virtualbox snapshots daily
    
    [Timer]
    OnCalendar=daily
    Persistent=true
    
    [Install]
    WantedBy=timers.target
