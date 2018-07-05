#!/bin/bash

TESTING_SERVER_MODS="--enable-info --enable-ssl --enable-cgi --enable-dav"

if [ "$1" != "" ]
then
    TOMCAT_VERSION="$1"
    INSTALL_DIRECTORY="/usr/local"
    PRODUCT="apache-tomcat-v$TOMCAT_VERSION-src"
    RELEASE_VERSION=$(echo "$TOMCAT_VERSION" | perl -pe '($_) = $_ =~ /([1-9][0-9]*)\.[0-9]+\.[0-9]+/i; print "tomcat-" . $_;')
    DOWNLOAD_URL="https://archive.apache.org/dist/tomcat/$RELEASE_VERSION/$PRODUCT.tar.gz"
    LOGFILE="/tmp/$PRODUCT-install.log"
    JDK_VERSION="jdk-10.0.1_linux-x64_bin"
    JDK_DOWNLOAD_URL="http://download.oracle.com/otn-pub/java/jdk/10.0.1+10/fb4372174a714e6b8c52526dc134031e/$JDK_VERSION.rpm"
    
    
    
    if [ "$2" != "" ]
    then
        INSTALL_DIRECTORY="$2"
    else
        INSTALL_DIRECTORY="$INSTALL_DIRECTORY/$PRODUCT"
    fi
    
    if [ -e "$INSTALL_DIRECTORY" ]
    then
        echo "[!] WARNING : $INSTALL_DIRECTORY Will Be Overwritten By New Installation"
        echo "[*] Are you sure that you want to install Tomcat $TOMCAT_VERSION in : $INSTALL_DIRECTORY ? (y,n) : "
        read CONFIRM
        if ![ "$CONFIRM" == "Y" ] && ![ "$CONFRIM" == "y" ] && ![ "$CONFIRM" == "yes" ] 
        then
            echo "[*] Aborting ..."
            exit
        fi
    fi
    
    echo "###################################### Summary ######################################"
    echo ""
    echo "          Product Name: $PRODUCT"
    echo "               Version: $TOMCAT_VERSION"
    echo "         Download From: $DOWNLOAD_URL"
    echo "     Install Directory: $INSTALL_DIRECTORY"
    echo ""
    echo "#####################################################################################"
    
    echo "[*] Downloading $PRODUCT Sources ..."
    wget $DOWNLOAD_URL -O /tmp/$PRODUCT.tar.gz >> $LOGFILE 2>&1
    
    echo "[*] Extracting Files In : /tmp/$PRODUCT ..."
    tar -x -z -f /tmp/$PRODUCT.tar.gz -C /tmp
    sudo rm -rf /tmp/$PRODUCT.tar.gz
    cd /tmp/$PRODUCT
    
    echo "[*] Searching JDK Installation"
    
    echo "[*] Installing Package ..."
    rpm -ivh "$JDK_VERSION.rpm"
    
    echo "[*] Upgrading Package ..."
    rpm -Uvh "$JDK_VERSION.rpm"
    
    echo "[*] Building $PRODUCT ..."
    sudo ./buildconf >> $LOGFILE 2>&1
    sudo ./configure --with-included-apr --enable-ssl --enable-exception-hook --enable-log-debug --enable-logio --enable-log-forensic --prefix="$INSTALL_DIRECTORY/" >> $LOGFILE 2>&1
    sudo make clean
    sudo make >> $LOGFILE 2>&1
    
    echo "[*] Installing $PRODUCT Files ..."
    sudo make install >> $LOGFILE 2>&1
    
    BUILD_INFO=$(sudo $INSTALL_DIRECTORY/bin/apachectl -v)
    
    if [ "$BUILD_INFO" != "" ]
    then
        echo "[+] Installation Done ."
        echo ""
        echo "$BUILD_INFO"
    else
        echo "[-] ERROR : Installation Failed"
        echo ""
        echo " -> Please Check The Installation Log File : $LOGFILE"
    fi
else
    echo "===================================[ Usage ]==================================="
    echo "  Arguments :"
    echo "        $0 <TOMCAT_VERSION>"
    echo "        $0 <TOMCAT_VERSION> [APCHE_INSTALL_DIRECTORY]"
    echo ""
    echo "  Exemple :"
    echo "        $0 2.4.29 /usr/local/httpd-2.4.29"
    echo ""
    echo "==============================================================================="
fi