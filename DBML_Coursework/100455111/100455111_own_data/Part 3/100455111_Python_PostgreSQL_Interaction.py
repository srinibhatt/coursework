
'''
Before you can run this code, please do the following:
    Fill up the information in line 23 below "connStr = "host='cmpstudb-01.cmp.uea.ac.uk' dbname= '' user='' password = " + pw"
    using the Russell Smith's provided credentials', add your password in the pw.txt file.
    
    Get connected to VPN (https://my.uea.ac.uk/divisions/it-and-computing-services/service-catalogue/network-and-telephony-services/vpn) if you are running this code from an off-campus location.
    
    Get the server running in https://pgadmin.cmp.uea.ac.uk/ by log into the server. 
    
'''
from datetime import datetime

import psycopg2
import pandas as pd

def is_four_digit_code(code):
    # Check if the code is numeric and has length 4
    return  len(code) == 4


def validate_date(input_date):
    result = True
    try:
        # Convert the input string to a datetime object
        date_object = datetime.strptime(input_date, '%Y-%m-%d')

        # Check if the date is in July 2024
        if date_object.month == 7 and date_object.year == 2024:
            print(f"{input_date} is a valid date in July 2024.")
            result = True
        else:
            print(f"{input_date} is not in July 2024.")
            result = False

    except ValueError:
        print(f"{input_date} is not a valid date in the format yyyy-mm-dd.")
        result = False

    return result

def getConn():
    #function to retrieve the password, construct
    #the connection string, make a connection and return it.
    #The pw.txt file will have the password to access the PGAdmin given to you by Russell Smith
    pwFile = open("pw.txt", "r")
    pw = pwFile.read();
    pwFile.close()
    # Fill up the following information from the Russell Smith's email.
    connStr = "host='cmpstudb-01.cmp.uea.ac.uk'  dbname= 'dvk23uvu' user='dvk23uvu' "\
               "password = "+pw
    #connStr=("dbname='studentdb' user='dbuser' password= 'dbPassword' " )
    conn=psycopg2.connect(connStr)      
    return  conn

def clearOutput():
    with open("output.txt", "w") as clearfile:
        clearfile.write('')
        
def writeOutput(output):
    with open("output.txt", "a") as myfile:
        myfile.write(output)
         
try:
    conn=None   
    conn=getConn()
    # All the sql statement once run will be autocommited
    conn.autocommit=True
    cur = conn.cursor()
    cur.execute("SET SEARCH_PATH TO coursework_2, public;");
    f = open("input.txt", "r")
    clearOutput()
    for x in f:
        print(x)
        if(x[0] == 'A'):
            # insert spectator
            raw = x.split("#",1)
            raw[1]=raw[1].strip()
            data = raw[1].split("#")   
            # Statement to insert data into the student table
            try:

                # The SQL statement can be a INSERT statement
                #sql="INSERT INTO student(sno,sname,semail) values ('{}','{}','{}');".format(data[0],data[1],data[2]);
                sql = "call insert_spectator({},'{}','{}');". format (data[0],data[1],data[2]);
                writeOutput("TASK "+x[0]+"\n")
                print(cur.mogrify(sql))

                cur.execute(sql)
                writeOutput(cur.statusmessage+"\n")
                sql  = "select * from spectator where sno={}".format(data[0])
                table_df=pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str=table_df.to_string()
                writeOutput(table_str+"\n")
            except Exception as e:
                writeOutput(str(e)+"\n")

        elif (x[0] == 'B'):
            # insert event
            raw = x.split("#", 1)
            raw[1] = raw[1].strip()
            data = raw[1].split("#")
            try:
                ecode =  data[0]
                edate = data[3]
                if (is_four_digit_code(ecode) == False) :
                    print('ecode {} is invalid , so skipping '.format(ecode))
                    continue

                if(validate_date(edate) == False) :
                    print('edate {} is invalid , so skipping '.format(edate))
                    continue

                sql = "call insert_event('{}','{}','{}','{}','{}',{});".format(data[0], data[1], data[2],data[3],data[4],data[5]);
                writeOutput("TASK " + x[0] + "\n")
                print(cur.mogrify(sql))

                cur.execute(sql)
                writeOutput(cur.statusmessage + "\n")
                sql = "select * from event where ecode='{}'".format(data[0])
                print(cur.mogrify(sql))
                table_df = pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str = table_df.to_string()
                writeOutput("---"+table_str + "\n"+"---")
            except Exception as e:
                writeOutput(str(e) + "\n")

        elif (x[0] == 'C'):
            # delete spectator
            raw = x.split("#", 1)
            raw[1] = raw[1].strip()
            data = raw[1].split("#")
            try:

                sql = "call delete_spectator({});".format(data[0]);
                writeOutput("TASK " + x[0] + "\n")
                print(cur.mogrify(sql))

                cur.execute(sql)
                writeOutput(cur.statusmessage + "\n")
                sql = "select * from spectator where sno={}".format(data[0])
                print(cur.mogrify(sql))
                table_df = pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str = table_df.to_string()
                writeOutput("---" + table_str + "---"+ "\n" )
            except Exception as e:
                writeOutput(str(e) + "\n")

        elif (x[0] == 'D'):
            # delete event
            raw = x.split("#", 1)
            raw[1] = raw[1].strip()
            data = raw[1].split("#")
            try:

                sql = "call delete_event('{}');".format(data[0]);
                writeOutput("TASK " + x[0] + "\n")
                print(cur.mogrify(sql))

                cur.execute(sql)
                writeOutput(cur.statusmessage + "\n")
                sql = "select * from event where ecode='{}'".format(data[0])
                print(cur.mogrify(sql))
                table_df = pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str = table_df.to_string()
                writeOutput("---" + table_str + "---"+ "\n" )
            except Exception as e:
                writeOutput(str(e) + "\n")

        elif (x[0] == 'E'):
            # issue ticket
            raw = x.split("#", 1)
            raw[1] = raw[1].strip()
            data = raw[1].split("#")
            try:

                sql = "call insert_ticket('{}',{});".format(data[0],data[1]);
                writeOutput("TASK " + x[0] + "\n")
                print(cur.mogrify(sql))

                cur.execute(sql)
                writeOutput(cur.statusmessage + "\n")
                sql = "select * from ticket where sno='{}' and ecode='{}'".format(data[1],data[0])
                print(cur.mogrify(sql))
                table_df = pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str = table_df.to_string()
                writeOutput("---" + table_str + "---"+ "\n" )
            except Exception as e:
                writeOutput("---" +str(e) + "\n")

        elif (x[0] == 'F'):
            # issue ticket
            writeOutput("TASK " + x[0] + "\n")
            try:

                sql = "select * from total_spectator_per_date_per_location"
                print(cur.mogrify(sql))
                table_df = pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str = table_df.to_string()
                writeOutput("---" + table_str + "---"+ "\n" )
            except Exception as e:
                writeOutput(str(e) + "\n")

        elif (x[0] == 'G'):
            # issue ticket
            writeOutput("TASK " + x[0] + "\n")
            try:

                sql = "select * from total_tickets_issued_per_event "
                print(cur.mogrify(sql))
                table_df = pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str = table_df.to_string()
                writeOutput("---" + table_str + "---"+ "\n" )
            except Exception as e:
                writeOutput("---" + str(e) + "\n" + "---")


        elif (x[0] == 'H'):
            # issue ticket
            raw = x.split("#", 1)
            raw[1] = raw[1].strip()
            data = raw[1].split("#")
            writeOutput("TASK " + x[0] + "\n")
            try:

                sql = "select * from total_tickets_issued_per_event where ecode ='{}'".format(data[0])
                print(cur.mogrify(sql))
                table_df = pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str = table_df.to_string()
                writeOutput("---" + table_str + "---"+ "\n" )
            except Exception as e:
                writeOutput("---" + str(e) + "\n" + "---")


        elif (x[0] == 'I'):
            # issue ticket
            raw = x.split("#", 1)
            raw[1] = raw[1].strip()
            data = raw[1].split("#")
            writeOutput("TASK " + x[0] + "\n")
            try:

                sql = "select * from report_spectator_schedule where sno={};".format(data[0])
                print(cur.mogrify(sql))
                table_df = pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str = table_df.to_string()
                writeOutput("---" + table_str + "---"+ "\n" )
            except Exception as e:
                writeOutput("---" + str(e) + "\n" + "---")

        elif (x[0] == 'J'):
            # issue ticket
            raw = x.split("#", 1)
            raw[1] = raw[1].strip()
            data = raw[1].split("#")
            writeOutput("TASK " + x[0] + "\n")
            try:

                sql = "select * from ticket_status_report where tno ={};".format(data[0])
                print(cur.mogrify(sql))
                table_df = pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str = table_df.to_string()
                writeOutput("---" + table_str + "---"+ "\n" )
            except Exception as e:
                writeOutput("---" + str(e) + "\n" + "---")

        elif (x[0] == 'K'):
            # issue ticket
            raw = x.split("#", 1)
            raw[1] = raw[1].strip()
            data = raw[1].split("#")
            writeOutput("TASK " + x[0] + "\n")
            try:

                sql = "select * from cancelled_tickets_report where ecode = '{}'".format(data[0])
                print(cur.mogrify(sql))
                table_df = pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str = table_df.to_string()
                writeOutput("---" + table_str + "---"+ "\n" )
            except Exception as e:
                writeOutput("---" + str(e) + "\n" + "---")

        elif (x[0] == 'L'):
            # issue ticket
            raw = x.split("#", 1)
            raw[1] = raw[1].strip()
            data = raw[1].split("#")
            writeOutput("TASK " + x[0] + "\n")
            try:

                sql = "call clean_tables();"
                print(cur.mogrify(sql))
                table_df = pd.read_sql_query(sql, conn)
                # Converting dataframe to string so that it can be written to text file.
                table_str = table_df.to_string()
                writeOutput("---" + table_str + "---"+ "\n" )
            except Exception as e:
                writeOutput("---" + str(e) + "\n" + "---")
        elif(x[0] == 'X'):
            print("Exit {}".format(x[0]))
            writeOutput("\n\nExit program!")
except Exception as e:
    print (e)               