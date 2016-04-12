#!/usr/bin/python2
##############################################################################
#  Copyright 2010 Thomas Boutry <xerus@x3rus.com>
#
#
#  html-email-send.py is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  html-email-sender.py is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Nobi; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# **************************************************************************
#
# Description :
#   Send an HTML email with an embedded image and a plain text message for
#   email clients that don't want to display the HTML.
#
#   Read Body of the email from the STDIN, you can add html markup and embeded IMAGE
#   to add img in the body set img like this  : "<img src="cid:img1">" and on the command line
#   in argument give the same identifier and the path where the file are like this: 
#    "{'img1':'/tmp/clementine-art-R27791.jpg'}"
#
#   Here a simple exemple :
#       echo " <b> Title in BOLD </b> with this IMG : <br> <img src="cid:img1"><br>Nifty! " | ./html-email-sender.py -t you@example.com -f me@example.com -s "test script" -i "{'img1':'/tmp/toto.jpg'}"
#
#   A more complex exemple :
#    file /tmp/body.txt :#
# ---------------------------------------------------------
#       <h1> Super Mail with Title </h1>
#
#        <b> With Bold </> <br>
#        and without :) <br>
#
#        First IMG : <br>
#        <img src="cid:i1"> <br>
#        Woww :P <br>
#        a second : <br>
#        <img src="cid:i2"> <br>
#        <br>
#        Well you understand :P !
# ---------------------------------------------------------
#     The command to send the mail :
#       cat /tmp/body.txt | ./html-email-sender.py -t you@example.com -f me@example.com -s "test script" -i "{'i1':'/tmp/bar.jpg','i2':'/tmp/foo.jpg'}"
#

import getopt,sys,ast,re
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEImage import MIMEImage

####################
#### Function #####
####################

def cmdUsage():
            print ("""
            Usage: STDIN | html-email-sender.py [OPTIONS]...
            
            Send E-MAIL in HTML format give the possibility to add images in the mail
            Options availables in version long and short
                -h, --help              Show the Help message
                -v, --verbose           Set the application in a verbose mode
                -t, --to                Email adresse who will receive the mail
                -f, --from              Email from the person who send the mail
                -s, --subject           Subject of the emails
                -i, --images            Lists of images to open and include in the mails
                                        \"{\'img1\':\'/tmp/toto.jpg\', \'img2\':\'/tmp/titi.jpg\'}\" "

            Exemple of use  :
                echo " <b> Title in BOLD </b> with this IMG : <br> <img src="cid:img1"><br>Nifty! " | ./html-email-sender.py -t you@example.com -f me@example.com -s "test script" -i "{'img1':'/tmp/toto.jpg'}"

            This will send an email with the img1 in the body of the mail , it's possible to add many images of course.
            """)
# END cmdUsage

# Function to remove all html tags use a regex to perform the operation
def remove_html_tags(data):
    p = re.compile(r'<.*?>')
    return p.sub('', data)

###############
#### VARs #####
###############
bIsVerbose = False

strFrom="root"
strTo="root"
strSubject="Unknown"
dicImages={}
strBody=""

################
#### MAIN  #####
################

# Parse command line arguments and validate options
# print error message if invalide argument exist
try:
    opts, args = getopt.getopt(sys.argv[1:], "vhs:t:f:i:", ["help", "to","from","subject", "images"])
except getopt.GetoptError as err:
    # Error Bad Arguments , print help information and exit:
    print (" \n" + str(err) ) # will print something like "option -a not recognized"
    cmdUsage()
    sys.exit(2)

# Process each arguments
for cmdOption , cmdArgument in opts:
    if cmdOption in ("-s", "--subject"):
        strSubject= cmdArgument
    if cmdOption in ("-t", "--to"):
        strTo= cmdArgument
    if cmdOption in ("-f", "--from"):
        strFrom= cmdArgument
    if cmdOption in ("-i", "--images"):
        try:
            dicImages= ast.literal_eval(cmdArgument)
        except:
            print ("ERROR: Img Argument not OK , it must be something like : ")
            print ("       -i \"{\'img1\':\'/tmp/toto.jpg\', \'img2\':\'/tmp/titi.jpg\'}\" ")
            cmdUsage()
            sys.exit(2)
    elif cmdOption in ("-v","--verbose"):
        bIsVerbose = True
    elif cmdOption in ("-h", "--help"):
        cmdUsage()
        sys.exit()

# Read From STDIN
# ref : http://www.pixelbeat.org/programming/readline/python
for line in sys.stdin.readlines():
    try:
        strBody = strBody + line
    except:
        pass


# Create the root message and fill in the from, to, and subject headers
msgRoot = MIMEMultipart('related')
msgRoot['Subject'] = strSubject
msgRoot['From'] = strFrom
msgRoot['To'] = strTo
msgRoot.preamble = 'This is a multi-part message in MIME format.'

# Encapsulate the plain and HTML versions of the message body in an
# 'alternative' part, so message agents can decide which they want to display.
msgAlternative = MIMEMultipart('alternative')
msgRoot.attach(msgAlternative)

#msgText = MIMEText('This is the alternative plain text message.')
msgText = MIMEText(remove_html_tags(strBody))
msgAlternative.attach(msgText)

# We reference the image in the IMG SRC attribute by the ID we give it below
#msgText = MIMEText('<b>Some <i>HTML</i> text</b> and an image.<br><img src="cid:image1"><br>Nifty!', 'html')
msgText = MIMEText(strBody ,'html')
msgAlternative.attach(msgText)

for strImgName , strImgPath in dicImages.items():
    try:
        # This example assumes the image is in the current directory
        fp = open(strImgPath, 'rb')
        msgImage = MIMEImage(fp.read())
        fp.close()

        # Define the image's ID as referenced above
        msgImage.add_header('Content-ID', '<'+strImgName+'>')
        msgRoot.attach(msgImage)
    except:
        print ("ERROR: Unable to open file : " + strImgPath)

# Send the email (this example assumes SMTP authentication is required)
import smtplib
smtp = smtplib.SMTP()
smtp.connect('relay',25)
smtp.ehlo()
smtp.sendmail(strFrom, strTo, msgRoot.as_string())
smtp.quit()
