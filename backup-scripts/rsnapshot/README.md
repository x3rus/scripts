==== Description ====

Ensemble de script utilisant Rsnapshot pour la réalisation de Backup par SSH.
Ces scripts envoie aussi un courriel de résultat du backup à l'administrateur.


==== Installation server ====

# Installation logiciel 
  sudo apt-get install rsnapshot
  sudo apt-get install rrdtool

# Création des répertoires (root:root)
  # Configuration
	sudo mkdir /etc/rsnapshot/hosts
	sudo mkdir /etc/rsnapshot/keys
  # logs
	sudo mkdir /var/log/rsnapshot

# Modification des permissions pour les clefs SSH 
	sudo chmod 700 /etc/rsnapshot/keys

# Création du répertoire pour le stockage des graphes
	sudo mkdir /var/lib/rrd/

# Création du répertoire pour stocker les fichiers
	sudo mkdir /usr/local/sysadmin/backup/

# Copier les fichiers 
	sudo cp backup_runner.sh FullBackup.sh html-email-sender.py rsnapreport.pl /usr/local/sysadmin/backup/    
	

# Modifier les variables dans le script FullBackup.sh


# Création du fichier de configuration [ATTENTION PAS D'ESPACE mais des TABULATIONS]
	/etc/rsnapshot/hosts/server_name.conf

# Création de clef SSH
	 sudo ssh-keygen 
		Generating public/private rsa key pair.
		Enter file in which to save the key (/root/.ssh/id_rsa): /etc/rsnapshot/keys/rsnapshot_rsa    
		Enter passphrase (empty for no passphrase): 
		Enter same passphrase again: 
		Your identification has been saved in /etc/rsnapshot/keys/rsnapshot_rsa.
		Your public key has been saved in /etc/rsnapshot/keys/rsnapshot_rsa.pub.
		The key fingerprint is:
		3f:39:ab:99:f4:04:c1:21:4c:88:cd:52:37:87:d7:38 root@barrabas
		The key's randomart image is:
		+--[ RSA 2048]----+
		|   =.+=.oo       |
	
==== Configuration client ====

# Ajout de la clef sur le client

# mise en place de la clef sur le serveur dans le fichier /root/.ssh/authorized_keys

	from="192.168.24.6",command="/root/backup/validate-rsync" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC74V43+VT3IbVO3cPLl265 ....... ....... ADAQABAAABA root@SERVER_RSNAPSHOT

# Changement permission fichier authorized_keys
	chmod o-r authorized_keys

# Création du fichier /root/backup/validate-rsync avec celui contenu dans le repo git.
	chmod u+x validate-rsync

# Création du fichier de graph avec rrdtool pour avoir un estimer du temps total du backup prend
 	sudo rrdtool create /var/lib/rrd/time_for_backup.rrd --start $(date +%s) --step 86400 DS:backupTime:GAUGE:172800:0:1440 RRA:LAST:0.5:1:14
