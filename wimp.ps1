Set-ExecutionPolicy Bypass -Scope Process

# To list all Windows Features: dism /online /Get-Features
# Get-WindowsOptionalFeature -Online 
# LIST All IIS FEATURES: 
# Get-WindowsOptionalFeature -Online | where FeatureName -like 'IIS-*'

Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment

Enable-WindowsOptionalFeature -online -FeatureName NetFx4Extended-ASPNET45
Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45

Enable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
Enable-WindowsOptionalFeature -Online -FeatureName IIS-LoggingLibraries
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestMonitor
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpTracing
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Performance
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools
Enable-WindowsOptionalFeature -Online -FeatureName IIS-IIS6ManagementCompatibility
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Metabase
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-BasicAuthentication
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic

Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45


Enable-WindowsOptionalFeature -Online -FeatureName IIS-CGI


$VC_redist = 'https://aka.ms/vs/16/release/VC_redist.x64.exe'
$MYSQL_URL = 'https://dev.mysql.com/get/Downloads/MySQL-8.0'
$MYSQL_PKG ='mysql-8.0.25-winx64'
$MYSQL_visual_studio = 'https://dev.mysql.com/get/Downloads/MySQL-for-VisualStudio/mysql-for-visualstudio-1.2.9.msi'
$Visual_studio = 'https://download.visualstudio.microsoft.com/download/pr/9dc321fd-8a9b-47ef-98a9-af0515e08d6f/533c91be0b61f481cb93758a3c6af09cef719cedbaa6e9916232918649fd4a35/vs_Community.exe'
$PHP = 'https://windows.php.net/downloads/releases/php-7.4.21-Win32-vc15-x64.zip'


## MYSQL Community installation
wget -Uri $Visual_studio -OutFile "C:\visual_studio.exe"
wget -Uri $MYSQL_visual_studio -OutFile "C:\mysql-for-visualstudio.msi"

Start-Process -wait -FilePath "C:\visual_studio.exe" -ArgumentList "-q"
Start-Process -wait -FilePath "C:\mysql-for-visualstudio.msi" -ArgumentList "/q"

wget $MYSQL_URL/$MYSQL_PKG.zip -OutFile c:\mysql.zip
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
Add-Content C:\php\php.ini 'extension = php_mysqli.dll'
Add-Content C:\php\php.ini 'extension = php_mbstring.dll'


import-module WebAdministration

###############################################################
# Adds a FastCGI process pool in IIS
###############################################################
$php = 'C:\php\php-cgi.exe'
$configPath = get-webconfiguration 'system.webServer/fastcgi/application' | where-object { $_.fullPath -eq $php }
if (!$configPath) {
    add-webconfiguration 'system.webserver/fastcgi' -value @{'fullPath' = $php }
}

###############################################################
# Create IIS handler mapping for handling PHP requests
###############################################################
$handlerName = "PHP"
$handler = get-webconfiguration 'system.webserver/handlers/add' | where-object { $_.Name -eq $handlerName }
if (!$handler) {
    add-webconfiguration 'system.webServer/handlers' -Value @{
        Name = $handlerName;
        Path = "*.php";
        Verb = "*";
        Modules = "FastCgiModule";
        scriptProcessor=$php;
        resourceType='Either' 
    }
}

###############################################################
# Configure the FastCGI Setting
###############################################################
# Set the max request environment variable for PHP
$configPath = "system.webServer/fastCgi/application[@fullPath='$php']/environmentVariables/environmentVariable"
$config = Get-WebConfiguration $configPath
if (!$config) {
    $configPath = "system.webServer/fastCgi/application[@fullPath='$php']/environmentVariables"
    Add-WebConfiguration $configPath -Value @{ 'Name' = 'PHP_FCGI_MAX_REQUESTS'; Value = 10050 }
}

# Configure the settings
# Available settings: 
#     instanceMaxRequests, monitorChangesTo, stderrMode, signalBeforeTerminateSeconds
#     activityTimeout, requestTimeout, queueLength, rapidFailsPerMinute, 
#     flushNamedPipe, protocol   
$configPath = "system.webServer/fastCgi/application[@fullPath='$php']"
Set-WebConfigurationProperty $configPath -Name instanceMaxRequests -Value 10000
Set-WebConfigurationProperty $configPath -Name monitorChangesTo -Value 'C:\php\php.ini'

# Restart IIS to load new configs.
invoke-command -scriptblock {iisreset /restart }
