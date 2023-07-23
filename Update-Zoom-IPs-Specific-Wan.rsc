# Simple script to fetch IP address lists from Zoom and add these
# to a firewall address list for later use but also to route
# Zoom traffic via a specific WAN, in this example ether2

{
    :local wanInterface "ether2"
    :local listname "zoom-hosts"
    
    # Gateway IP of WAN
    :local gatewayIP [/ip dhcp-client get [find interface=$wanInterface] gateway]

    # Remove items existing on the list
    /ip firewall address-list remove [/ip firewall address-list find list=$listname]

    # Remove existing routes for Zoom IPs
    /ip route remove [find comment~$listname]

    :local update do={
        :do {
            :local result [/tool fetch url=$url as-value output=user]; :if ($result->"downloaded" != "63") do={
                :local data ($result->"data")
                # :do { remove [find list=$listname comment!="Optional"] } on-error={}
                :while ([:len $data]!=0) do={
                        :if ([:pick $data 0 [:find $data "\n"]]~"^([0-2]{0,1}[0-9]{1,2}\\.){3}[0-2]{0,1}[0-9]{1,2}(\\/[0-3]{0,1}[0-9]{1,1}){0,1}") do={
                            :do {
                                /ip firewall address-list add list=$listname address=([:pick $data 0 [:find $data $delimiter]].$cidr)
                                /ip route add dst-address=([:pick $data 0 [:find $data $delimiter]].$cidr) gateway=$gatewayIP comment="$listname"
                            } on-error={}
                        }
                    :set data [:pick $data ([:find $data "\n"]+1) [:len $data]]
                } ; :log warning "Imported address list < $listname> from file: $url"
            } else={:log warning "Address list: <$listname>, downloaded file to big: $url" }
        } on-error={:log warning "Address list <$listname> update failed"}
    }
    $update url="https://assets.zoom.us/docs/ipranges/Zoom.txt" listname=$listname delimiter=("\n") gatewayIP=$gatewayIP
    $update url="https://assets.zoom.us/docs/ipranges/ZoomMeetings.txt" listname=$listname delimiter=("\n") gatewayIP=$gatewayIP
    $update url="https://assets.zoom.us/docs/ipranges/ZoomCRC.txt" listname=$listname delimiter=("\n") gatewayIP=$gatewayIP
    $update url="https://assets.zoom.us/docs/ipranges/ZoomPhone.txt" listname=$listname delimiter=("\n") gatewayIP=$gatewayIP
}