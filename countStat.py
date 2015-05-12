#!/usr/local/bin/python
import os;
import sys;
import datetime;
import time;

statlog = '/usr/local/sbin/stat.txt'
file_name = "/usr/local/sbin/stat.txt"
pad = "*"
pad2 = "-"
probe = "callme-crt-probe"
smsc_list = []; # keep grep'ped lines in the list
mnp_list = [];   # keep claro_mnp.log  errors in the list
zb2_list = [];
unidos_list = [];

today = datetime.date.today()
yesterday = today - datetime.timedelta(days=1) 
old = today - datetime.timedelta(days=4); # all smg and probes files older than 4 days will be deleted

yesterday = str(yesterday) # we need strings for today and yesterday in code
today = str(today)
old = str(old)

probes_log = "/usr/local/sbin/" + yesterday + "_probes-statistics.log "
smg_log = "/usr/local/sbin/" + yesterday + "_smg-statistics.log"
check_min = yesterday + " 09:00: "
probes = ('callme-crt-probe', 'callme-dor-probe', 'callme-tmx-probe') # tuple for probes
dict = {} # dictionary to keep stat results

##############################################################################################################################################################
# this function grep stat for all probes in **probes*** tuple
def probes_stat():
    for probe in probes:
        per_min = os.popen("/bin/grep " + " '" + check_min + "' " + probes_log + " | /bin/grep " + probe + " | /bin/cut -d ' ' -f 12").read();
        probe_per_min = probe + "_per_min";
        dict[probe_per_min] = per_min;

        per_day = os.popen(" awk '/" +  probe + "/ {sum+=$12} END {print sum}' " + probes_log).read();
        probe_per_day = probe + "_per_day";
        dict[probe_per_day] = per_day;

        max_per_min = os.popen("/bin/grep " + probe + " " + probes_log + " | /bin/cut -d ' ' -f 2,12 | /bin/sort -g -n -k 2 | /usr/bin/tail -n 1").read();
        probe_max_per_min = probe + "_max_per_min";
        dict[probe_max_per_min] = max_per_min;

    return;
################################################################################################################################################################

################################################################################################################################################################
# this function grep stat for SMG and adds to dictionary

def smg_stat():
    smg_per_min = os.popen("/bin/grep " + " '" + check_min + "' " + smg_log + " | /bin/cut -d ' ' -f 11").read();
    dict['smg_per_min'] = smg_per_min;
    smg_per_day = os.popen(" awk '{sum+=$11} END {print sum}' " + smg_log).read();
    dict['smg_per_day'] = smg_per_day;
    smg_max_per_min = os.popen("/bin/grep 'smg OUT' " + smg_log + " | /bin/cut -d ' ' -f 2,11 | /bin/sort -g -n -k 2 | /usr/bin/tail -n 1").read();
    dict['smg_max_per_min'] = smg_max_per_min;
    return;

##################################################################################################################################################################
def check_smsc():
#**** today log

    logFileName ='/opt/smg/log/logFile.log';
    fileobj = open(logFileName, "r")

    search = "disconnected from smsc";

    for line in fileobj:
        if search in line:
            #line = line.rstrip("\n"); # remove new line, otherwise it will print extra new line in output
            smsc_list.append(line);
    fileobj.seek(0,0)        
    search = "connected to SMSC";

    for line in fileobj:
        if search in line:
            #line = line.rstrip("\n"); # remove new line, otherwise it will print extra new line in output
            smsc_list.append(line);

    fileobj.close()

####################################################################################################################################################################

def check_mnp():

    logFileName ='/opt/mnp/claro_mnp.log';
    fileobj = open(logFileName,"r")

#*** success  for today
    search = today;
    match = 'MNP is done'
    for line in fileobj:
        if (search in line and match in line):
            #line = line.rstrip("\n"); # remove new line, otherwise it will print extra new line in output
            mnp_list.append(line);

    fileobj.seek(0,0); # return pointer of file to beginning again

#*** errors for today 
    match = 'Program'

    for line in fileobj:
        if (search in line and match in line):
            #line = line.rstrip("\n"); # remove new line, otherwise it will print extra new line in output
            mnp_list.append(line);
    fileobj.close()

####################################################################################################################################################################

def check_zb2():
#*** errors for today  
    logFileName ='/opt/Zb2/claro_zb2.log';
    fileobj = open(logFileName,"r")

    search = today;
    match = 'Program'

    for line in fileobj:
        if (search in line and match in line):
            #line = line.rstrip("\n"); # remove new line, otherwise it will print extra new line in output
            zb2_list.append(line);

    fileobj.seek(0,0); # return pointer of file to beginning again

#*** success for today
    match = 'Done ZB2'

    for line in fileobj:
        if (search in line and match in line):
            #line = line.rstrip("\n"); # remove new line, otherwise it will print extra new line in output
            zb2_list.append(line);

    fileobj.close()

########################################################################################################################################################################
def check_unidos():
#*** errors for today 
    logFileName ='/opt/Unidos/claro_unidos.log';
    fileobj = open(logFileName,"r")

    search = today;
    match = 'Program'

    for line in fileobj:
        if (search in line and match in line):
            #line = line.rstrip("\n"); # remove new line, otherwise it will print extra new line in output
            unidos_list.append(line);

    fileobj.seek(0,0); # return pointer of file to beginning again

#*** success for today
    match = 'Done Unidos'

    for line in fileobj:
        if (search in line and match in line):
            #line = line.rstrip("\n"); # remove new line, otherwise it will print extra new line in output
            unidos_list.append(line);

    fileobj.close()

#####################################################################################################################################################################
def delete_oldlogs():
    
    old_probe_log = '/usr/local/sbin/' + old + '_probes-statistics.log'
    old_smg_log = '/usr/local/sbin/' + old + '_smg-statistics.log'

    try: 
        os.remove(old_probe_log);
    except StandardError:
        print "Error: can't find file"
    except IOError:
        print "Error: can't find file"
    else: 
        print "removed successfully"
        
    try: 
        os.remove(old_smg_log);
    except StandardError:
        print "Error: can't find file"
    except IOError:
        print "Error: can't find file"
    else: 
        print "removed successfully"

#####################################################################################################################################################################
def print_stat():
    try:
        fo = open(file_name, "a")
        lines_of_text = [pad*110 + "\n", pad*10 + "  SMG and PROBES stat  " + yesterday + " " + pad*10 + "\n\n"] 
        fo.writelines(lines_of_text)

        fo.write(pad2*10 + " # of events per minute at 09:00 " + yesterday + " " + pad2*10 + "\n\n");
        fo.write(" calme-crt-probe per minute at 09:00: " + dict['callme-crt-probe_per_min'] + "\n");
        fo.write(" calme-dor-probe per minute at 09:00: " + dict['callme-dor-probe_per_min'] + "\n");
        fo.write(" calme-tmx-probe per minute at 09:00: " + dict['callme-tmx-probe_per_min'] + "\n");
        fo.write(" SMG per minute at 09:00:             " + dict['smg_per_min'] + "\n\n");

        
        fo.write(pad2*10 + " total # of events per day " + yesterday + " " + pad2*10 + "\n\n");
        fo.write(" calme-crt-probe total number: " + dict['callme-crt-probe_per_day'] + "\n");
        fo.write(" calme-dor-probe total number: " + dict['callme-dor-probe_per_day'] + "\n");
        fo.write(" calme-tmx-probe total number: " + dict['callme-tmx-probe_per_day'] + "\n");
        fo.write(" SMG total number:             " + dict['smg_per_day'] + "\n\n");
        
        fo.write(pad2*10 + " maximum number events per minute " + yesterday + " " + pad2*10 + "\n\n");
        fo.write(" calme-crt-probe max number per minute:     " + dict['callme-crt-probe_max_per_min'] + "\n");
        fo.write(" calme-dor-probe max number per minute:     " + dict['callme-dor-probe_max_per_min'] + "\n");
        fo.write(" calme-tmx-probe max number per minute:     " + dict['callme-tmx-probe_max_per_min'] + "\n");
        fo.write(" SMG max number per minute:                 " + dict['smg_max_per_min'] + "\n\n");


    # ----------- mnp messages -------------------------------------------------------------------------    
        a = len(mnp_list);
        if (a > 0):
            fo.write(pad2*10 + "  mnp file report in today's log " + pad2*10 +"\n");
            for line in mnp_list:
                fo.write(line);
        fo.write("\n")
        
    # ----------- zb2 messages -------------------------------------------------------------------------    
        a = len(zb2_list);
        if (a > 0):
            fo.write(pad2*10 + "  zb2 file report in today's log " + pad2*10 +"\n");
            for line in zb2_list:
                fo.write(line);
        fo.write("\n")

    # ----------- unidos messages -------------------------------------------------------------------------    
        a = len(unidos_list);
        if (a > 0):
            fo.write(pad2*10 + "  unidos file report in today's log " + pad2*10 +"\n");
            for line in unidos_list:
                fo.write(line);
        fo.write("\n")

    # ----------- SMSC messages -------------------------------------------------------------------------    
        a = len(smsc_list);
        if (a > 0):
            fo.write(pad2*10 + " we have SMSC connection messages in today's log " + pad2*10 +"\n");
            for line in smsc_list:
                fo.write(line);
        else:
            fo.write("no SMSC messages in log file for today");

        fo.write("\n\n")



        lines_of_text = [pad2*10 + "  END OF THE DAY " + yesterday + " " + pad2*10 + "\n", pad*110 + "\n\n\n"] 
        fo.writelines(lines_of_text)
            
        fo.close();
    except IOError:
        print "IOError"
    else:
        print "File created"
################################################################################################################################################


probes_stat();

smg_stat();

check_smsc();

check_mnp();

check_zb2();

check_unidos();

print_stat();

delete_oldlogs();

