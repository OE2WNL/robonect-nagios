#!/bin/bash
########################################################################################
# (c) DerWebWolf 2017
# v1.0
#
# * ----------------------------------------------------------------------------
# * "THE BEER-WARE LICENSE" (Revision 42):
# * <robonect@derwebwolf.net> wrote this file. As long as you retain this notice you
# * can do whatever you want with this stuff. If we meet some day, and you think
# * this stuff is worth it, you can buy me a beer in return.
# * ----------------------------------------------------------------------------
#
# Credits for Robonect and the used API fully go to robonect.de
#
#
# Please ensure that this script has execution rights with the following command:
# chmod o+x check_robonect.sh
#
# Config Nagios Check Command in a .cfg file as follows:
#
# define command{
#        command_name    check_robonect_battery
#        command_line    /etc/nagios3/conf.d/monitoringpackage/plugins/check_robonect.sh -H '$HOSTADDRESS$' -t battery -u 'admin' -p 'secret' -w '$ARG1$' -c '$ARG2$'
# }

# define command{
#        command_name    check_robonect_status
#        command_line    /etc/nagios3/conf.d/monitoringpackage/plugins/check_robonect.sh -H '$HOSTADDRESS$' -t status -u 'admin' -p 'secret'
# }
#
# And the final check command for the mower host:
# define host{
#        use             generic-host
#        host_name       Automower
#        address         192.168.2.1
# }
#
# define service{
#        use             generic-service
#        host_name       Automower
#        service_description battery
#        check_command   check_robonect_battery!40!35
# }
#
# define service{
#        use             generic-service
#        host_name       Automower
#        service_description status
#        check_command   check_robonect_status
# }
#
#
########################################################################################

default_roboname="Automower";
default_warning=50;
default_critical=35;

while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        # This is an arg value type option. Will catch -o value or --output-file value
        -H|--host)
        shift # past the key and to the value
        host="$1"
        ;;

        -t|--type)
        shift # past the key and to the value
        type="$1"
        ;;

        -u|--user)
        shift # past the key and to the value
        user="$1"
        ;;

        -p|--password)
        shift # past the key and to the value
        password="$1"
        ;;

        -w|--warning)
        shift # past the key and to the value
        warning="$1"
        ;;

        -c|--critical)
        shift # past the key and to the value
        critical="$1"
        ;;
        *)
        # Do whatever you want with extra options
        echo "Unknown option '$key'"
        ;;
    esac
    # Shift after checking all the cases to get the next option
    shift
done


if [ "$host" == "" ];then
        echo "Parameter -H or --host needed";
        exit 3;
fi

if [ "$type" != "battery" ] && [ "$type" != "status" ]; then
        echo "Parameter -type or --type with value battery or status needed";
        exit 3;
fi

if [ "$warning" == "" ];then
	warning=$default_warning;
fi

if [ "$critical" == "" ];then
	critical=$default_critical;
fi

if [ $warning -lt $critical ];then
	echo "Critical should be lower than warning";
	exit 3;
fi

xml=$(curl -s -S "http://$host/xml?cmd=status&user=$user&pass=$password");

if [ "$xml" == "" ];then
        echo "Probably wrong user and/or password?";
        exit 3;
fi

roboname=$(echo $xml | grep -oPm1 "(?<=<name>)[^<]+" | head -1)
if [ "$roboname" == "" ];then
	roboname=$default_roboname;
fi

if [ "$type" == "status" ]; then
	status=$(echo $xml | grep -oPm1 "(?<=<status>)[^<]+" | head -1)

	case "$status" in
		0)
		statustxt="Status wird ermittelt"
		;;
		1)
		statustxt="$roboname parkt"
		;;
		2)
		statustxt="$roboname maeht"
		;;
		3)
		statustxt="$roboname sucht die Ladestation"
		;;
		4)
		statustxt="$roboname laedt"
		;;
		5)
		statustxt="$roboname sucht (wartet auf das Umsetzen im manuelen Modus)"
		;;
		7)
		statustxt="Fehlerstatus"
		;;
		8)
		statustxt="Schleifensignal verloren"
		;;
		16)
		statustxt="$roboname abgeschaltet"
		;;
		17)
		statustxt="$roboname schlaeft"
		;;
	esac

	if [ $status -eq 7 ] || [ $status -eq 8 ];then
		echo "Status Critical - $statustxt|status=$status";
		exit 2;
	fi

	echo "Status OK - $statustxt|status=$status";
	exit 0;
fi

if [ "$type" == "battery" ]; then
	battery=$(echo $xml | grep -oPm1 "(?<=<battery>)[^<]+" | head -1)

	if [ $battery -lt $critical ];then
		echo "Battery level Critical - Current percentage $battery %|bat=$battery";
		exit 2;
	fi

	if [ $battery -lt $warning ];then
		echo "Battery level Warning - Current percentage $battery %|bat=$battery";
		exit 1;
	fi

	echo "Battery level OK - Current percentage $battery %|bat=$battery";
	exit 0;
fi
