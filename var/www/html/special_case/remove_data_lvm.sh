cd /dev

(pv=`echo /dev/[sv]d[bc]`
vg=`pvs | grep '[sv]d[bc]' | awk '{print $2}'`
for i in $vg
do
    yes | lvremove /dev/$vg/*
done

for i in $vg
do
    yes | vgremove $i
done

for i in $pv
do
    yes | pvremove $pv
    wipefs -a $pv
done
rm -rf /var/lib/glusterd /etc/glusterfs /run/lvm /var/lib/misc/glusterfsd) || true
