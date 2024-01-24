## DevOps \ Домашнее задание №15 - Zabbix

Настроить мониторинг для выбранного приложения.


## VM - Zabbix


docker run --name some-zabbix-appliance -p 80:80 -p 10051:10051 -d zabbix/zabbix-appliance:ubuntu-4.0-latest

или

docker run --name zabbix-appliance -t \
      -p 10051:10051 \
      -p 80:80 \
      -d zabbix/zabbix-appliance:latest


zabbix-java-gateway уже в докере
Templates \ JMX





## VM - Apache (TOMCAT)

https://tomcat.apache.org/tomcat-11.0-doc/monitoring.html



FROM tomcat:11.0-jdk21
#https://github.com/docker-library/tomcat/blob/97251f3bf88258f6edcb6f313970ae1971e4537b/11.0/jdk21/temurin-jammy/Dockerfile


CATALINA_OPTS=-Dcom.sun.management.jmxremote.port=9875 \
  -Dcom.sun.management.jmxremote.rmi.port=%my.rmi.port% \
  -Dcom.sun.management.jmxremote.ssl=false \
  -Dcom.sun.management.jmxremote.authenticate=false


ADD hello.war /usr/local/tomcat/webapps/



