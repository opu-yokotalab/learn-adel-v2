#!/bin/sh
#Linux
classpath=".:/$PLC/jipl.jar:/usr/share/java/postgresql-jdbc3.jar"

#Mac
#classpath=".:/$PLC/jipl.jar"

javac -cp $classpath *.java
