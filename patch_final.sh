#!/bin/bash

function install_magerun () {
wget -q https://files.magerun.net/n98-magerun.phar -P /root/bin
chmod ug+x /root/bin/n98-magerun.phar
MAGERUN=/root/bin/n98-magerun.phar
}

function install_magescan () {
wget -q https://github.com/steverobbins/magescan/releases/download/v1.12.3/magescan.phar -P /root/bin
chmod ug+x /root/bin/magescan.phar
MAGESCAN=/root/bin/magescan.phar
}

function check_php () {
rpm -q php >/dev/null 2>&1
s1=echo $?
php -v >/dev/null 2>&1
s2=echo $?

if [ $s1 -ne 0 -a $s2 -ne 0 ]; then
echo -en "\e[33m Php not found.\e[39m Do you still want to continue [Y/N] : "
read s3
verify_php
else
PHP=php
fi
} 

function verify_php () {
case $s3 in
	Y|y|yes|YES|Yes)
	echo -en "Enter the path to php utility (i.e php command) : "
	read pHp
	if [ -f $pHp ]; then
	echo "you are using : `$pHp -v | awk 'NR==1{print $1 $2}'`"
	MAGERUN="$pHp $MAGERUN"
	MAGESCAN="$pHp $MAGESCAN"
	PHP="pHp"
	else 
	echo "Utility path you entered does not exists."
	if [ "$count" -gt "2" ]; then 
	count=$(( count + 1 ))
	check_php
	else
	exit 1
	fi 
	fi
	;;
	N|n|no|No|NO)
	exit
	;;
	*)
	echo "Your choice does not match the available choices."
	exit
	;;
esac
}

# prerequisite
function prerequisite () {
if [ -d /root/bin ]; then 
mkdir /root/bin
install_magerun
install_magescan
else
if [ -f /root/bin/n98-magerun.phar ]; then install_magerun; else MAGERUN=/root/bin/n98-magerun.phar; fi
if [ -f /root/bin/magecan.phar ]; then install_magescan; else MAGESCAN=/root/bin/magescan.phar; fi
fi

rpm -q curl >/dev/null 2>&1
if [ "$?" -ne "0" ]; then yum install curl -y >/dev/null 2>&1; fi
rpm -q wget >/dev/null 2>&1
if [ "$?" -ne "0" ]; then yum install wget -y >/dev/null 2>&1; fi
rpm -q patch >/dev/null 2>&1
if [ "$?" -ne "0" ]; then yum install patch -y >/dev/null 2>&1; fi
rpm -q git >/dev/null 2>&1
if [ "$?" -ne "0" ]; then yum install git -y >/dev/null 2>&1; fi

count=0
check_php
}

# magento version 
function fetch_version () {
major=`$MAGERUN --skip-root-check --root-dir="$MAGEDIR" sys:info --format name -- Version | cut -d'.' -f1`
minor=`$MAGERUN --skip-root-check --root-dir="$MAGEDIR" sys:info --format name -- Version | cut -d'.' -f2`
revision=`$MAGERUN --skip-root-check --root-dir="$MAGEDIR" sys:info --format name -- Version | cut -d'.' -f3`
patch=`$MAGERUN --skip-root-check --root-dir="$MAGE_DIR" sys:info --format name -- Version | cut -d'.' -f4`
}

# detect pathes remaining on website.
function fetch_patches () {
$MAGESCAN scan:patch $1 | grep Unpatched >/dev/null 2>&1
s4=echo $?
if [ $s4 -ne 0 ]; then
case $major in
	1)
	case $minor in
		9)
		case $revision in
			2)
			case $patch in 
				3)
				pf_7405v11_1923=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.9.2.3" | grep "7405" | grep "v1.1"`
				;;
				2)
				curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.9.2.2" | grep "7405" > $MAGEDIR/../patching/patchfiles
				pf_7405v11_1922=`grep "v1.1" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
				pf_7405v1_1922=`grep "v1" $MAGEDIR/../patching/patchfiles | head -1` > /dev/null 2>&1
				;;
				1)
				curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.9.2" > $MAGEDIR/../patching/patchfiles
				pf_7405v11_1921=`grep "1.9.2.1" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
				pf_7405v1_1921=`grep "1.9.2" $MAGEDIR/../patching/patchfiles | grep "7405" | grep 'v1' | head -1` > /dev/null 2>&1
				pf_6788_1921=`grep "1.9.2.1" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
				;;
				0)
				curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.9" > $MAGEDIR/../patching/patchfiles
				pf_7405v11_1920=`grep "1.9.2.0" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
				pf_7405v1_1920=`grep "1.9.2" $MAGEDIR/../patching/patchfiles | grep "7405" | grep 'v1' | head -1` > /dev/null 2>&1
				pf_6788_1920=`grep "1.9.2.0" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
				pf_6482_1920=`grep "1.9" $MAGEDIR/../patching/patchfiles | grep "6482"` > /dev/null 2>&1
				pf_6285_1920=`grep "1.9" $MAGEDIR/../patching/patchfiles | grep "6285"` > /dev/null 2>&1
				;;
				*)
				echo "Magento Version not found : $major.$minor.$revision.$patch";
				exit 1
				;;
			esac
			;;	
			1)	
			case $patch in 
				1)
				curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.9" > $MAGEDIR/../patching/patchfiles
				pf_7405v11_1911=`grep "1.9.1.1" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
				pf_7405v1_1911=`grep "1.9.1" $MAGEDIR/../patching/patchfiles | grep "7405" | grep 'v1' | head -1` > /dev/null 2>&1
				pf_6788_1911=`grep "1.9.1.1" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
				pf_6482_1911=`grep "6482" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
				pf_6285_1911=`grep "6285" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
				pf_5994_1911=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" | grep "5994"`
				;;
				0)
				curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.9" > $MAGEDIR/../patching/patchfiles
				pf_7405v11_1910=`grep "1.9.1.1" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
				pf_7405v1_1910=`grep "1.9.1" $MAGEDIR/../patching/patchfiles | grep "7405" | grep 'v1' | head -1` > /dev/null 2>&1
				pf_6788_1910=`grep "1.9.1.0" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
				pf_6482_1910=`grep "6482" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
				pf_6285_1910=`grep "6285" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
				pf_5994_1910=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" | grep "5994"`
				pf_5344_1910=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.8" | grep "53"`
				;;
				*)
				echo "Magento Version not found : $major.$minor.$revision.$patch";
				exit 1
				;;
			esac
			;;
			0)
			case $patch in
                                1)
				curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.9" > $MAGEDIR/../patching/patchfiles
				pf_7504v11_1901=`grep "1.9.0.1" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
                                pf_7405v1_1901=`grep "1.9.0" $MAGEDIR/../patching/patchfiles | grep "7405" | grep 'v1' | head -1` > /dev/null 2>&1
				pf_6788_1901=`grep "1.9.0.1" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
				pf_6482_1901=`grep "6482" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
				pf_6285_1901=`grep "1.9" | grep "6285" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
				pf_5994_1901=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" | grep "5994"`
				pf_5344_1901=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.8" | grep "53"`
				;;
                                0)
				curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.9" > $MAGEDIR/../patching/patchfiles
				pf_7504v11_1900=`grep "1.9.0.1" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
                                pf_7405v1_1901=`grep "1.9.0" $MAGEDIR/../patching/patchfiles | grep "7405" | grep 'v1' | head -1` > /dev/null 2>&1
                                pf_6788_1900=`grep "1.9.0" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
                                pf_6482_1900=`grep "6482" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
                                pf_6285_1900=`grep "6285" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
				pf_5994_1900=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" | grep "5994"`
                                pf_5344_1900=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.8" | grep "53"`
                                ;;
				*)
				echo "Magento Version not found : $major.$minor.$revision.$patch";
				exit 1
				;;
                        esac
                        ;;
			*)
			echo "Magento Version not found : $major.$minor.$revision.$patch";
			exit 1
			;;
		esac	
		;;
		8)
		case $revision in
			1)
			curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.8" > $MAGEDIR/../patching/patchfiles 
			pf_7405v11_1810=`grep "1.8.1.0" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
			pf_7405v1_1810=`grep "1.8.1" $MAGEDIR/../patching/patchfiles | grep "7405" | grep 'v1' | head -1` > /dev/null 2>&1
                        pf_6788_1810=`grep "1.8.1" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
                        pf_6482_1810=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.9" | grep "6482"`
			pf_6285_1810=`grep "1.8.1.0" $MAGEDIR/../patching/patchfiles | grep "6285"` > /dev/null 2>&1
                        pf_5994_1810=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" | grep "5994"`
                        pf_5344_1810=`grep "53" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
			;;
			0)
			curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.8" > $MAGEDIR/../patching/patchfiles 
			pf_7405v11_1800=`grep "1.8.0.0" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
			pf_7405v1_1800=`grep "1.8.0" $MAGEDIR/../patching/patchfiles | grep "7405" | grep 'v1' | head -1` > /dev/null 2>&1
                        pf_6788_1800=`grep "1.8.0" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
                        pf_6482_1800=`grep "6482" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
			pf_6285_1800=`grep "1.8.0.0" $MAGEDIR/../patching/patchfiles | grep "6285"` > /dev/null 2>&1
                        pf_5994_1800=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" | grep "5994"`
                        pf_5344_1800=`grep "53" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
			;;
			*)
			echo "Magento Version not found : $major.$minor.$revision.$patch";
			exit 1
			;;
		esac
		;;
		7)
		case $revision in
			0)
			case $patch in
				2)
				curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.7" > $MAGEDIR/../patching/patchfiles
				pf_7405v11_1702=`grep "1.7.0.2" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
				pf_7405v1_1702=`grep "7405" $MAGEDIR/../patching/patchfiles | grep 'v1' | head -1` > /dev/null 2>&1
                        	pf_6788_1702=`grep "1.7.0.2" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
                        	pf_6482_1702=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.8" | grep "6482"`
				pf_6285_1702=`grep "6285" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
                        	pf_5994_1701=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" | grep "5994"`
                        	pf_5344_1701=`grep "53" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
				;;
				1)
				curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.7" > $MAGEDIR/../patching/patchfiles
				pf_7405v11_1701=`grep "1.7.0.1" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
				pf_7405v1_1701=`grep "7405" $MAGEDIR/../patching/patchfiles | grep 'v1' | head -1` > /dev/null 2>&1
                        	pf_6788_1701=`grep "1.7.0.1" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
                        	pf_6482_1701=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.8" | grep "6482"`
				pf_6285_1701=`grep "6285" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
                        	pf_5994_1701=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" | grep "5994"`
                        	pf_5344_1701=`grep "53" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
				;;
				0)
				curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.7" > $MAGEDIR/../patching/patchfiles
				pf_7405v11_1700=`grep "1.7.0.0" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
				pf_7405v1_1700=`grep "7405" $MAGEDIR/../patching/patchfiles | grep 'v1' | head -1` > /dev/null 2>&1
                       	 	pf_6788_1700=`grep "1.7.0.1" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
                        	pf_6482_1700=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.8" | grep "6482"`
				pf_6285_1700=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.9" | grep "6285"`
                        	pf_5994_1700=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" | grep "5994"`
                        	pf_5344_1700=`grep "53" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
				;;
				*)
				echo "Magento Version not found : $major.$minor.$revision.$patch";
				exit 1
				;;
			esac		
			;;
			*)
			echo "Magento Version not found : $major.$minor.$revision.$patch";
			exit 1
			;;
		esac
		;;
		6)
		case $revision in
			2)
			curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" > $MAGEDIR/../patching/patchfiles
			pf_7405v11_1620=`grep "1.6.2.0" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
			pf_7405v1_1620=`grep "1.6.2" $MAGEDIR/../patching/patchfiles | grep "7405" | grep 'v1' | head -1` > /dev/null 2>&1
                        pf_6788_1620=`grep "1.6.2.0" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
                        pf_6482_1620=`grep "1.6.2" $MAGEDIR/../patching/patchfiles | grep "6482"` > /dev/null 2>&1
			pf_6285_1620=`grep "6285" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
                        pf_5994_1620=`grep "5994" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
                        pf_5344_1620=`grep "1.6.1" $MAGEDIR/../patching/patchfiles | grep "53"` > /dev/null 2>&1
			;;
			1)
			curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" > $MAGEDIR/../patching/patchfiles
			pf_7405v11_1610=`grep "1.6.1.0" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
			pf_7405v1_1610=`grep "1.6.1" $MAGEDIR/../patching/patchfiles | grep "7405" | grep 'v1' | head -1` > /dev/null 2>&1
                        pf_6788_1610=`grep "1.6.1.0" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
                        pf_6482_1610=`grep "1.6.2" $MAGEDIR/../patching/patchfiles | grep "6482"` > /dev/null 2>&1
			pf_6285_1610=`grep "6285" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
                        pf_5994_1610=`grep "5994" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
                        pf_5344_1610=`grep "1.6.1" $MAGEDIR/../patching/patchfiles | grep "53"` > /dev/null 2>&1
			;;
			0)
			curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/type/ce-patch | rev | awk '{print $1}' | rev | grep "1.6" > $MAGEDIR/../patching/patchfiles
			pf_7405v11_1600=`grep "1.6.0.0" $MAGEDIR/../patching/patchfiles | grep "7405" | grep "v1.1"` > /dev/null 2>&1
			pf_7405v1_1600=`grep "1.6.0" $MAGEDIR/../patching/patchfiles | grep "7405" | grep 'v1' | head -1` > /dev/null 2>&1
                        pf_6788_1600=`grep "1.6.0.0" $MAGEDIR/../patching/patchfiles | grep "6788"` > /dev/null 2>&1
                        pf_6482_1600=`grep "1.6.0" $MAGEDIR/../patching/patchfiles | grep "6482"` > /dev/null 2>&1
			pf_6285_1600=`grep "6285" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
                        pf_5994_1600=`grep "5994" $MAGEDIR/../patching/patchfiles` > /dev/null 2>&1
                        pf_5344_1600=`grep "1.6.0" $MAGEDIR/../patching/patchfiles | grep "53"` > /dev/null 2>&1
			;;
			*)
			echo "Magento Version not found : $major.$minor.$revision.$patch";
			exit 1
			;;
		esac
		;;
		*)
		echo "Magento Version is not supported yet : $major.$minor.$revision.$patch";
		exit 0
		;;
esac

else
echo "Either Store ($major.$minor.$revision.$patch) is already patched Or Its version is not supportable yet."
fi
}

# download the prepatched and origional source files
function download_files () {

file=`curl -s https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/info/filter/version/$major.$minor.$revision.$patch | grep tar.gz | rev | cut -d' ' -f1 | rev`

curl -s -o $MAGEDIR/../patching https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/file/$file 

git clone https://github.com/magecomp/Magento-Pre-Patched-Files.git $MAGEDIR/../patching/

}

function patch_download () {
patchName=$1
case $patchName in
	5344)
	P5344="pf_5344_$major$minor$revision$patch"
	if [ ! -z "${!P5344}" ]; then
	wget -q -P $MAGEDIR/../patching/ "https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/file/${!P5344}"
	if [ "$?" -eq "0" ]; then p5344=downloaded; fi
	fi
	;;
	5994)
	P5994="pf_5994_$major$minor$revision$patch"
	if [ ! -z "${!P5994}" ]; then
	wget -q -P $MAGEDIR/../patching/ "https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/file/${!P5994}"
	if [ "$?" -eq "0" ]; then p5994=downloaded; fi
	fi
	;;
	6285)
	P6285="pf_6285_$major$minor$revision$patch"
	if [ ! -z "${!P6285}" ]; then
	wget -q -P $MAGEDIR/../patching/ "https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/file/${!P6285}"
	if [ "$?" -eq "0" ]; then p6285=downloaded; fi
	fi
	;;
	6482)
	P6482="pf_6482_$major$minor$revision$patch"
	if [ ! -z "${!P6482}" ]; then
	wget -q -P $MAGEDIR/../patching/ "https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/file/${!P6482}"
	if [ "$?" -eq "0" ]; then p6482=downloaded; fi
	fi
	;;
	6788)
	P6788="pf_6788_$major$minor$revision$patch"
	if [ ! -z "${!P6788}" ]; then
	wget -q -P $MAGEDIR/../patching/ "https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/file/${!P6788}"
	if [ "$?" -eq "0" ]; then p6788=downloaded; fi
	fi
	;;
	7405)
	P7405v1="pf_7405v1_$major$minor$revision$patch"
	P7405v11="pf_7405v11_$major$minor$revision$patch"
	if [ -z "${!P7405v1}" ]; then
	wget -q -P $MAGEDIR/../patching/ "https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/file/${P7405v1}"
	if [ "$?" -eq "0" ]; then p7405v1=downloaded; fi
	fi
	if [ -z "${!P7405v11}" ]; then
	wget -q -P $MAGEDIR/../patching/ "https://$MAG_ID:$TOKEN@www.magentocommerce.com/products/downloads/file/${!P7405v11}"
	if [ "$?" -eq "0" ]; then p7405v11=downloaded; fi
	fi	
	if [ "$7405v1" -eq "0" -a "$7405v11" -eq "0" ]; then p7405=downloaded; fi
	*)
	;;
esac
}

function patch_scan () {
$MAGESCAN scan:patch $1 > /tmp/patches
}

# finding the state of patch Patched,Unpatched or Unknown.
function patch_state () {
case $1 in
	5344)
	grep 5344 /tmp/patches | grep Unpatched
	if [ "$?" -eq "0" ]; then patch_download 5344; fi
	if [ $p5344 != "downloaded" ]; then
	grep 5344 /tmp/patches | grep Patched
		if [ "$?" -eq "0" ]; then p5344=patched; fi
	grep 5344 /tmp/patches | grep Unknown
		if [ "$?" -eq "0" ]; then p5344=unknown; fi
	fi
	;;
	5994)
	grep 5994 /tmp/patches | grep Unpatched
        if [ "$?" -eq "0" ]; then patch_download 5994; fi
        if [ $p5994 != downloaded ]; then
        grep 5994 /tmp/patches | grep Patched
                if [ "$?" -eq "0" ]; then p5994=patched; fi
		if [ "$p5344" == "unknown" ]; then p5344=patched; fi
        grep 5344 /tmp/patches | grep Unknown
                if [ "$?" -eq "0" ]; then p5344=unknown; fi
        fi
        ;;
	6285)
	grep 6285 /tmp/patches | grep Unpatched
        if [ "$?" -eq "0" ]; then patch_download 6285; fi
        if [ "$p6285" != "downloaded" ]; then
        grep 6285 /tmp/patches | grep Patched
                if [ "$?" -eq "0" ]; then p6285=patched; fi
                if [ "$p5344" == "unknown" ]; then p5344=patched; fi
                if [ "$p5994" == "unknown" ]; then p5994=patched; fi
        grep 5285 /tmp/patches | grep Unknown
                if [ "$?" -eq "0" ]; then p6285=unknown; fi
        fi
        ;;
	6482)
	grep 6482 /tmp/patches | grep Unpatched
        if [ "$?" -eq "0" ]; then patch_download 6482; fi
        if [ "$p6482" != "downloaded" ]; then
        grep 6482 /tmp/patches | grep Patched
                if [ "$?" -eq "0" ]; then p6285=patched; fi
                if [ "$p5344" == "unknown" ]; then p5344=patched; fi
                if [ "$p5994" == "unknown" ]; then p5994=patched; fi
                if [ "$p6285" == "unknown" ]; then p5994=patched; fi
        grep 6482 /tmp/patches | grep Unknown
                if [ "$?" -eq "0" ]; then p6482=unknown; fi
        fi
        ;;
	6788)
	grep 6788 /tmp/patches | grep Unpatched
        if [ "$?" -eq "0" ]; then patch_download 6788; fi
        if [ "$p6788" != "downloaded" ]; then
        grep 6788 /tmp/patches | grep Patched
                if [ "$?" -eq "0" ]; then p6788=patched; fi
                if [ "$p5344" == "unknown" ]; then p5344=patched; fi
                if [ "$p5994" == "unknown" ]; then p5994=patched; fi
                if [ "$p6285" == "unknown" ]; then p6285=patched; fi
                if [ "$p6482" == "unknown" ]; then p6482=patched; fi
        grep 6788 /tmp/patches | grep Unknown
                if [ "$?" -eq "0" ]; then p6788=unknown; fi
        fi
        ;;
	7405)
	grep 7405 /tmp/patches | grep Unpatched
        if [ "$?" -eq "0" ]; then patch_download 7405; fi
        if [ "$p7405" != "downloaded" ]; then
        grep 7405 /tmp/patches | grep Patched
                if [ "$?" -eq "0" ]; then p7405=patched; fi
                if [ "$p5344" == "unknown" ]; then p5344=patched; fi
                if [ "$p5994" == "unknown" ]; then p5994=patched; fi
                if [ "$p6285" == "unknown" ]; then p6285=patched; fi
                if [ "$p6482" == "unknown" ]; then p6482=patched; fi
                if [ "$p6788" == "unknown" ]; then p6482=patched; fi
        grep 7405 /tmp/patches | grep Unknown
                if [ "$?" -eq "0" ]; then 7405p=unknown; fi
        fi
        ;;
	*)
	;;
esac
}

# checking the status of patched applied or unapplied
function patch_status () {
patch_name=$1
case $patch_name in
	5344)
	patch_state 5344
	;;
	5994)
	patch_state 5994
	;;
	6285)
	patch_state 6285
	;;
	6482)
	patch_state 6482
	;;
	6788)
	patch_state 6788
	;;
	7405)
	patch_state 7405
	;;
	*)
	;;
esac

# Patches which are left with unknown status
function patch_unknown () {

if [ "$p5344" == "unknown" ]; then
	patch_download 5344
	echo "Status of patch 5344 is Unknown. It is not applied via this script but kept downloaded in $MAGDIR . Check it manually."
fi	
if [ "$p5994" == "unknown" ]; then
	patch_download 5994
	echo "Status of patch 5994 is Unknown. It is not applied via this script but kept downloaded in $MAGDIR . Check it manually."
fi	
if [ "$p6285" == "unknown" ]; then
	patch_download 6285
	echo "Status of patch 6285 is Unknown. It is not applied via this script but kept downloaded in $MAGDIR . Check it manually."
fi	
if [ "$p6482" == "unknown" ]; then
	patch_download 6482
	echo "Status of patch 6482 is Unknown. It is not applied via this script but kept downloaded in $MAGDIR . Check it manually."
fi	
if [ "$p6788" == "unknown" ]; then
	patch_download 6788
	echo "Status of patch 6788 is Unknown. It is not applied via this script but kept downloaded in $MAGDIR . Check it manually."
fi	
if [ "$p7405" == "unknown" ]; then
	patch_download 7405
	echo "Status of patch 7405 is Unknown. It is not applied via this script but kept downloaded in $MAGDIR . Check it manually."
fi	

}

function patch_apply () {

cp -f $MAGEDIR/../patching $MAGEDIR/
cd $MAGEDIR
mkdir $MAGEDIR/../log/

if [ "$p5344" == "downloaded" ]; then
F5344="pf_5344_$major$minor$revision$patch"
bash ${!F5344} > $MAGEDIR/../log/5344 2>&1 
if [ "$?" -eq "0" ]; then p5344='applied'; else p5344='unapplied'; fi
fi

if [ "$p5994" == "downloaded" ]; then 
F5994="pf_5994_$major$minor$revision$patch"
bash ${!F5994} > $MAGEDIR/../log/5994 2>&1 
if [ "$?" -eq "0" ]; then p5994='applied'; else p5994='unapplied'; fi
fi

if [ "$p6285" == "downloaded" ]; then 
F6285="pf_6285_$major$minor$revision$patch"
bash ${!F6285} > $MAGEDIR/../log/6285 2>&1 
if [ "$?" -eq "0" ]; then p6285='applied'; else p6285='unapplied'; fi
fi

if [ "$p6482" == "downloaded" ]; then 
F6482="pf_6482_$major$minor$revision$patch"
bash ${!F6482} > $MAGEDIR/../log/6482 2>&1 
if [ "$?" -eq "0" ]; then p6482='applied'; else p6482='unapplied'; fi
fi

if [ "$p6788" == "downloaded" ]; then 
F6788="pf_6788_$major$minor$revision$patch"
bash ${!F6788} > $MAGEDIR/../log/6788 2>&1 
if [ "$?" -eq "0" ]; then p6788='applied'; else p6788='unapplied'; fi
fi

if [ "$p7405" == "downloaded" ]; then
 
	if [ "$p7405v1" == "downloaded" ]; then 
	F7405v1="pf_7405v1_$major$minor$revision$patch"
	bash ${!F7405v1} > $MAGEDIR/../log/7405 2>&1 
	if [ "$?" -eq "0" ]; then p7405v1='applied'; else p7405v1='unapplied'; fi
	fi

	if [ "$p7405v11" == "downloaded" ]; then 
	F7405v11="pf_7405v11_$major$minor$revision$patch"
	bash ${!F7405v11} > $MAGEDIR/../log/7405 2>&1 
	if [ "$?" -eq "0" ]; then p7405v11='applied'; else p7405v11='unapplied'; fi
	fi

	if [ "$p7405v1" == "applied" -a "$p7405v11" == "applied" ]; then
	p7405='applied'
	elif [ "$p7405v1" == "unapplied" -a "$p7405v11" == "unapplied" ]; then
	p7405='unapplied'
	elif [ "$p7405v1" == "applied" -a "$p7405v11" == "unapplied" ]; then
	p7405='unapplied'
	elif [ "$p7405v1" == "unapplied" -a "$p7405v11" == "applied" ]; then
	p7405='unapplied'
	else
	true
	fi
fi
}

function patch_fix () {

if [ "$p6788" == "applied" ]; then 
git clone https://github.com/rhoerr/supee-6788-toolbox.git $MAGEDIR/../patching/
cp $MAGEDIR/../patching/supee-6788-toolbox/fixSUPEE6788.php $MAGEDIR/shell/ 
cd $MAGEDIR/shell/ ; $PHP -f fixSUPEE6788.php -- fixWhitelists > 2>&1 $MAGEDIR/../patching/fixSUPEE6788.log
if [ "$?" -eq "0" ]; then echo "6788 Fix applied."; fi
else
git clone https://github.com/rhoerr/supee-6788-toolbox.git $MAGEDIR/../patching/
#download fix
#generate report
# Apply the patch
# Copy the file 
# run the command.
##
fi

if [ "$p7405" == "applied" ]; then
cd $MAGEDIR/app/design/frontend
find . -name "register.phtml" > $MAGEDIR/../patching/fixSUPEE7405.log
while read line; do 
if [ -f "$line" ]; then 
grep getPostActionUrl $line > /dev/null 2>&1
f1=$?
grep -A1 "getPostActionUrl" $line | grep "getBlockHtml" | grep "formkey" > /dev/null 2>&1
f2=$?
if [ "$f1" -eq "0" -a "$f2" -ne "0" ]; then
sed -i "/getPostActionUrl/a <?php echo \$this->getBlockHtml('formkey'); ?>" $line
fi
fi
done < $MAGEDIR/../patching/fixSUPEE7405.log
else
# generare report what have to check after applying it manually
fi

}

function generate_report () {
## generate report of unapplied patches only.
}

#<<<<<<<<<<< SCRIPT START >>>>>>>>>>>>#

# run as root
if [ `id -u` -ne 0 ]; then echo "U R ! su"; exit; fi

if [ -z "$1" ]; then
echo -e "\nUsage : /bin/bash script.sh <MAGE DIR. PATH>"
elif [ ! -d "$1" -a ! -f "$1/app/etc/local.xml" ]; then
echo -e "\nDIRECTORY : $1 or FILE : $1/app/etc/local.xml, Does not exists."
else
MAGEDIR=$1
fi

MAG_ID=
TOKEN=

prerequisite

WEBSITE=`$MAGERUN --skip-root-check --root-dir="$MAGEDIR" cache:dir:flush sys:store:config:base-url:list | grep http | cut -d'|' -f4 | xargs | cut -d'/' -f3`

fetch_version
fetch_patches
$MAGERUN --skip-root-check --root-dir="$MAGE_DIR" cache:dir:flush
$PHP $MAGEDIR/shell/compiler.php clear
$PHP $MAGEDIR/shell/compiler.php disable
mkdir $MAGEDIR/../patching

