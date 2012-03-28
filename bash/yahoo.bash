# Yahoo Functions

# YAHOO user id
export YAHOO_USER=bward
export YAHOO_GLT_HOST=localhost
export YAHOO_GLT_PORT=9998

# tunnel WOE proxy
export TUNNEL=true

export PATH=~/ybin:$PATH

## Handle misbehaving Cisco VPN
function restart_cisco {
    sudo /System/Library/StartupItems/CiscoVPN/CiscoVPN restart
}