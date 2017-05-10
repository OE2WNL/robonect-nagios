(c) DerWebWolf 2017
v1.0

```
* ----------------------------------------------------------------------------
* "THE BEER-WARE LICENSE" (Revision 42):
* <robonect@derwebwolf.net> wrote this file. As long as you retain this notice you
* can do whatever you want with this stuff. If we meet some day, and you think
* this stuff is worth it, you can buy me a beer in return.
* ----------------------------------------------------------------------------
```
Credits for Robonect and the used API fully go to robonect.de

### Please ensure that this script has execution rights with the following command:
```
chmod o+x check_robonect.sh
```

### Config Nagios Check Command in a .cfg file as follows:

```
define command{
       command_name    check_robonect_battery
       command_line    /etc/nagios3/conf.d/monitoringpackage/plugins/check_robonect.sh -H '$HOSTADDRESS$' -t battery -u 'admin' -p 'secret' -w '$ARG1$' -c '$ARG2$'
}

define command{
       command_name    check_robonect_status
       command_line    /etc/nagios3/conf.d/monitoringpackage/plugins/check_robonect.sh -H '$HOSTADDRESS$' -t status -u 'admin' -p 'secret'
}
```


And the final check command for the mower host:
```
define host{
       use             generic-host
       host_name       Automower
       address         192.168.2.1
}

define service{
       use             generic-service
       host_name       Automower
       service_description battery
       check_command   check_robonect_battery!40!35
}

define service{
       use             generic-service
       host_name       Automower
       service_description status
       check_command   check_robonect_status
}
```
