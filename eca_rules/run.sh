#!/bin/sh

#Linux
export PLC=/usr/local/plc
export LD_LIBRARY_PATH=$PLC
cd /home/learn/rails_app/adel_v2/teaching_materials/eca_rules/

#Vine Linux 4.1
classpath=".:$PLC/jipl.jar:/usr/share/pgsql/postgresql-8.1-407.jdbc3.jar"

#Fedora Core 4
#classpath=".:$PLC/jipl.jar:/usr/share/java/postgresql-jdbc3.jar"

#Mac
#export PLC=/Applications/plc
#cd /Users/postgres/Documents/plc3
#classpath=".:$PLC/jipl.jar:/Library/Java/Extensions"

mode=$1
new=$2
user_id=$3
ent_seq_id=$4

java -cp $classpath -DPLC=$PLC -Djava.library.path=$PLC SeqTaste seq.cfg $mode $new $user_id $ent_seq_id

