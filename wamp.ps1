
$VC_redist = 'https://aka.ms/vs/16/release/VC_redist.x64.exe'
$apache = 'https://www.apachehaus.com/downloads/httpd-2.4.48-o111k-x64-vs16.zip'
#$MYSQL = 'https://dev.mysql.com/get/Downloads/MySQLInstaller/mysql-installer-community-8.0.25.0.msi'
$MYSQL_URL = 'https://dev.mysql.com/get/Downloads/MySQL-8.0'
$MYSQL_PKG ='mysql-8.0.25-winx64'
$MYSQL_visual_studio = 'https://dev.mysql.com/get/Downloads/MySQL-for-VisualStudio/mysql-for-visualstudio-1.2.9.msi'
$Visual_studio = 'https://download.visualstudio.microsoft.com/download/pr/9dc321fd-8a9b-47ef-98a9-af0515e08d6f/533c91be0b61f481cb93758a3c6af09cef719cedbaa6e9916232918649fd4a35/vs_Community.exe'
$PHP = 'https://windows.php.net/downloads/releases/php-7.4.21-Win32-vc15-x64.zip'

## Apache installation
wget -Uri $VC_redist -OutFile "C:\VC_redist.x64.exe"
Start-Process -Wait -FilePath "C:\VC_redist.x64.exe" -ArgumentList "/q"

wget $apache -OutFile "C:\httpd.zip"
Expand-Archive "C:\httpd.zip" -DestinationPath "c:\"

Start-Process -wait -FilePath "C:\Apache24\bin\httpd.exe" -ArgumentList "-k install"
Start-Process -wait -FilePath "C:\Apache24\bin\httpd.exe" -ArgumentList "-k start"


## MYSQL Community installation
#wget -Uri $MYSQL -OutFile "C:\mysql-installer-community.msi"
wget -Uri $Visual_studio -OutFile "C:\visual_studio.exe"
wget -Uri $MYSQL_visual_studio -OutFile "C:\mysql-for-visualstudio.msi"

Start-Process -wait -FilePath "C:\visual_studio.exe" -ArgumentList "-q"
Start-Process -wait -FilePath "C:\mysql-for-visualstudio.msi" -ArgumentList "/q"
#msiexec.exe /q /log install.txt /i c:\mysql-installer-community.msi

wget $MYSQL_URL/$MYSQL_PKG -OutFile c:\mysql.zip
Expand-Archive "c:\mysql.zip" -DestinationPath "c:\"
Rename-Item C:\$MYSQL_PKG c:\mysql

Start-Process -wait -FilePath "c:\mysql\bin\mysqld.exe" -ArgumentList "--initialize-insecure"
Start-Process -wait -FilePath "c:\mysql\bin\mysqld.exe" -ArgumentList "--install"
sc.exe start MySQL

# PHP
wget $PHP -OutFile c:\php.zip
Expand-Archive c:\php.zip -DestinationPath "c:\php"
Copy-Item "C:\php\php.ini-production" -Destination "c:\php\php.ini"
Add-Content C:\php\php.ini 'extension_dir = "C:\PHP\ext"'
Add-Content C:\Apache24\conf\httpd.conf 'LoadModule php7_module "C:/php/php7apache2_4.dll"'
Add-Content C:\Apache24\conf\httpd.conf 'AddType application/x-httpd-php .html .htm'
Add-Content C:\Apache24\conf\httpd.conf 'AddHandler application/x-httpd-php .php'
(gc -path C:\Apache24\conf\httpd.conf) -replace '(DirectoryIndex index.html)','$1 index.php' |sc C:\Apache24\conf\httpd.conf
Add-Content C:\Apache24\conf\httpd.conf 'PHPiniDir "C:/php"'
