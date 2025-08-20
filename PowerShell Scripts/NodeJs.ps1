node -v
npm -v
Set-ExecutionPolicy -ExecutionPolicy UnRestricted -Scope LocalMachine
Get-ExecutionPolicy -List

npm cache clean
npm install -g npm
rm package-lock.json
npm init -y

cd "C:\Program Files\nodejs"